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
  constructor(private readonly db: Database, private readonly config: AppConfig) {}
  private actor(row: any): Actor {
    return { id: row.id, phone: row.phone, displayName: row.display_name, role: row.role,
      permissions: row.permissions, verified: !!row.phone_verified_at,
      teamApproved: row.team_approved, testAccount: row.is_test_account };
  }
  async login(input: unknown) {
    const data = z.object({ phone: z.string().min(1).max(40), password: z.string().min(1).max(1024) }).strict().parse(input);
    const phone = normalizePhone(data.phone);
    const result = await this.db.pool.query('SELECT * FROM accounts WHERE phone=$1', [phone]);
    const row = result.rows[0];
    const valid = await verify(row?.password_hash ?? await this.dummyHash, data.password).catch(() => false);
    if (!row || !valid || row.locked_at || (this.config.NODE_ENV === 'production' && row.is_test_account)) {
      throw new ApiError(401, 'INVALID_CREDENTIALS', 'Số điện thoại hoặc mật khẩu không đúng.');
    }
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
}

export function requireRole(actor: Actor, role: Role) {
  if (actor.role !== role) throw new ApiError(403, 'FORBIDDEN', 'Bạn không có quyền thực hiện thao tác này.');
}
export function requireAdmin(actor: Actor, permission: string) {
  requireRole(actor, 'admin');
  if (!actor.permissions.includes(permission)) throw new ApiError(403, 'FORBIDDEN', 'Tài khoản quản trị chưa được cấp quyền này.');
}
