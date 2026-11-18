import { createHash, randomBytes } from 'node:crypto';
import { Algorithm, hash, verify } from '@node-rs/argon2';
import { parsePhoneNumberFromString } from 'libphonenumber-js';
import { z } from 'zod';
import { AppConfig } from '../common/config.js';
import { Database } from '../common/database.js';
import { ApiError } from '../common/errors.js';

export type Role = 'citizen' | 'rescue' | 'admin';
export interface Actor {
  id: string; phone: string; displayName: string; role: Role; permissions: string[];
  verified: boolean; teamApproved: boolean; testAccount: boolean;
}

export const passwordOptions = { algorithm: Algorithm.Argon2id, memoryCost: 19456, timeCost: 2, parallelism: 1 };
export const tokenHash = (token: string) => createHash('sha256').update(token).digest('hex');
export function normalizePhone(value: string) {
  const phone = parsePhoneNumberFromString(value.trim(), 'VN');
  if (!phone?.isValid()) throw new ApiError(422, 'INVALID_PHONE', 'Số điện thoại chưa hợp lệ.');
  return phone.number;
}

export class AuthService {
  private readonly dummyHash = hash(randomBytes(32).toString('hex'), passwordOptions);
  readonly pairFailures = new Map<string, { count: number; resetAt: number }>();
  readonly phoneFailures = new Map<string, { count: number; resetAt: number }>();
  constructor(private readonly db: Database, private readonly config: AppConfig) {}
  private actor(row: any): Actor {
    return { id: row.id, phone: row.phone, displayName: row.display_name, role: row.role,
      permissions: row.permissions, verified: !!row.phone_verified_at,
      teamApproved: row.team_approved, testAccount: row.is_test_account };
  }
  async login(input: unknown, ip = '127.0.0.1') {
    const data = z.object({ phone: z.string().min(1).max(40), password: z.string().min(1).max(1024) }).strict().parse(input);
    const phone = normalizePhone(data.phone);
    const clientIp = ip || '127.0.0.1';
    const pairKey = `${phone}:${clientIp}`;
    const now = Date.now();

    for (const [k, v] of this.pairFailures) {
      if (v.resetAt <= now) this.pairFailures.delete(k);
    }
    for (const [k, v] of this.phoneFailures) {
      if (v.resetAt <= now) this.phoneFailures.delete(k);
    }

    const pair = this.pairFailures.get(pairKey);
    if (pair && pair.count >= 5 && pair.resetAt > now) {
      const retryAfter = Math.max(1, Math.ceil((pair.resetAt - now) / 1000));
      throw new ApiError(429, 'RATE_LIMITED', 'Có quá nhiều lần thử đăng nhập không thành công. Hãy thử lại sau.', {
        'Retry-After': retryAfter,
      });
    }

    const phoneEntry = this.phoneFailures.get(phone);
    if (phoneEntry && phoneEntry.count >= 20 && phoneEntry.resetAt > now) {
      const retryAfter = Math.max(1, Math.ceil((phoneEntry.resetAt - now) / 1000));
      throw new ApiError(429, 'RATE_LIMITED', 'Có quá nhiều lần thử đăng nhập không thành công. Hãy thử lại sau.', {
        'Retry-After': retryAfter,
      });
    }

    const result = await this.db.pool.query('SELECT * FROM accounts WHERE phone=$1', [phone]);
    const row = result.rows[0];
    const valid = await verify(row?.password_hash ?? await this.dummyHash, data.password).catch(() => false);
    if (!row || !valid || row.locked_at || (this.config.NODE_ENV === 'production' && row.is_test_account)) {
      const pairEntry = this.pairFailures.get(pairKey) ?? { count: 0, resetAt: now + 15 * 60_000 };
      pairEntry.count++;
      this.pairFailures.set(pairKey, pairEntry);

      const pEntry = this.phoneFailures.get(phone) ?? { count: 0, resetAt: now + 15 * 60_000 };
      pEntry.count++;
      this.phoneFailures.set(phone, pEntry);

      throw new ApiError(401, 'INVALID_CREDENTIALS', 'Số điện thoại hoặc mật khẩu không đúng.');
    }

    this.pairFailures.delete(pairKey);
    if (!row.phone_verified_at) throw new ApiError(403, 'PHONE_NOT_VERIFIED', 'Tài khoản chưa được xác minh số điện thoại.');
    if (row.role === 'rescue' && !row.team_approved) throw new ApiError(403, 'TEAM_NOT_APPROVED', 'Đội chưa đủ quyền hoạt động.');
    const token = randomBytes(32).toString('base64url');
    const expiresAt = new Date(Date.now() + this.config.SESSION_HOURS * 3600_000);
    await this.db.pool.query('INSERT INTO sessions(token_hash,account_id,expires_at) VALUES($1,$2,$3)', [tokenHash(token), row.id, expiresAt]);
    return { token, expiresAt: expiresAt.toISOString(), account: this.actor(row) };
  }
  async authenticate(authorization?: string): Promise<Actor> {
    const match = /^Bearer ([A-Za-z0-9_-]{43})$/.exec(authorization ?? '');
    if (!match?.[1]) throw new ApiError(401, 'UNAUTHENTICATED', 'Hãy đăng nhập để tiếp tục.');
    const result = await this.db.pool.query(`SELECT a.* FROM accounts a JOIN sessions s ON s.account_id=a.id
      WHERE s.token_hash=$1 AND s.revoked_at IS NULL AND s.expires_at>clock_timestamp() AND a.locked_at IS NULL`, [tokenHash(match[1])]);
    const row = result.rows[0];
    if (!row || (this.config.NODE_ENV === 'production' && row.is_test_account)) {
      throw new ApiError(401, 'SESSION_EXPIRED', 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.');
    }
    const actor = this.actor(row);
    if (!actor.verified) throw new ApiError(403, 'PHONE_NOT_VERIFIED', 'Tài khoản chưa được xác minh.');
    if (actor.role === 'rescue' && !actor.teamApproved) throw new ApiError(403, 'TEAM_NOT_APPROVED', 'Đội chưa đủ quyền hoạt động.');
    return actor;
  }
  async logout(authorization: string) {
    const token = authorization.slice(7);
    await this.db.pool.query('UPDATE sessions SET revoked_at=clock_timestamp() WHERE token_hash=$1 AND revoked_at IS NULL', [tokenHash(token)]);
  }
  async recordConsent(actor: Actor, body: unknown) {
    const parsed = z.object({
      version: z.string().trim().min(1).max(50),
    }).parse(body);
    const result = await this.db.pool.query(
      `UPDATE accounts SET consent_version=$1, consented_at=clock_timestamp() WHERE id=$2 RETURNING consent_version, consented_at`,
      [parsed.version, actor.id]
    );
    return {
      consented: true,
      consentVersion: result.rows[0]?.consent_version ?? parsed.version,
      consentedAt: result.rows[0]?.consented_at ?? new Date(),
    };
  }
}

export function requireRole(actor: Actor, role: Role) {
  if (actor.role !== role) throw new ApiError(403, 'FORBIDDEN', 'Bạn không có quyền thực hiện thao tác này.');
}
export function requireAdmin(actor: Actor, permission: string) {
  requireRole(actor, 'admin');
  if (!actor.permissions.includes(permission)) throw new ApiError(403, 'FORBIDDEN', 'Tài khoản quản trị chưa được cấp quyền này.');
}
