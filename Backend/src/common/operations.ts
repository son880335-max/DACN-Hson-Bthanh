import { createHash } from 'node:crypto';
import { PoolClient } from 'pg';
import { z } from 'zod';
import { Actor } from '../auth/auth.service.js';
import { Database } from './database.js';
import { ApiError } from './errors.js';

function canonical(value: unknown): string {
  if (Array.isArray(value)) return '[' + value.map(canonical).join(',') + ']';
  if (value !== null && typeof value === 'object') {
    return '{' + Object.entries(value).sort(([a], [b]) => a.localeCompare(b))
      .map(([k, v]) => JSON.stringify(k) + ':' + canonical(v)).join(',') + '}';
  }
  return JSON.stringify(value);
}

export class Operations {
  constructor(private readonly db: Database) {}
  async run<T>(actor: Actor, operationId: string, kind: string, body: unknown,
    execute: (client: PoolClient) => Promise<T>): Promise<T> {
    z.string().uuid().parse(operationId);
    const bodyHash = createHash('sha256').update(canonical({ kind, body })).digest('hex');
    return this.db.transaction(async client => {
      const account = await client.query('SELECT role,permissions,phone_verified_at,team_approved FROM accounts WHERE id=$1 AND locked_at IS NULL FOR SHARE', [actor.id]);
      const fresh = account.rows[0];
      if (!fresh || !fresh.phone_verified_at || fresh.role !== actor.role ||
          (actor.role === 'rescue' && !fresh.team_approved) || actor.permissions.some(p => !fresh.permissions.includes(p))) {
        throw new ApiError(403, 'PERMISSIONS_CHANGED', 'Quyền tài khoản đã thay đổi. Hãy đăng nhập lại.');
      }
      await client.query('SELECT pg_advisory_xact_lock(hashtextextended($1,0))', [actor.id + ':' + operationId]);
      const prior = await client.query('SELECT kind,body_hash,response FROM operation_receipts WHERE actor_id=$1 AND operation_id=$2', [actor.id, operationId]);
      if (prior.rowCount) {
        if (prior.rows[0].kind !== kind || prior.rows[0].body_hash !== bodyHash) {
          throw new ApiError(409, 'OPERATION_REUSED', 'Mã thao tác đã dùng cho nội dung khác. Hãy kiểm tra kết quả trước khi gửi thay đổi.');
        }
        return prior.rows[0].response as T;
      }
      const response = await execute(client);
      await client.query('INSERT INTO operation_receipts(actor_id,operation_id,kind,body_hash,response) VALUES($1,$2,$3,$4,$5::jsonb)',
        [actor.id, operationId, kind, bodyHash, JSON.stringify(response)]);
      return response;
    });
  }
}
