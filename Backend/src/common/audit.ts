import { randomUUID } from 'node:crypto';
import { Actor } from '../auth/auth.service.js';
import { Database } from './database.js';

export async function recordAccessAudit(
  db: Database,
  actor: Actor,
  requestId: string,
  ownerId: string,
  kind = 'detail_view',
) {
  if (actor.id === ownerId || actor.role === 'citizen') return;
  try {
    await db.pool.query(
      `INSERT INTO access_audit (id, actor_id, request_id, kind, at)
       SELECT $1, $2, $3, $4, clock_timestamp()
       WHERE NOT EXISTS (
         SELECT 1 FROM access_audit
         WHERE actor_id = $2 AND request_id = $3
         AND at > clock_timestamp() - interval '1 hour'
       )`,
      [randomUUID(), actor.id, requestId, kind],
    );
  } catch (err: unknown) {
    console.error(JSON.stringify({
      event: 'audit_write_failed',
      requestId,
      error: err instanceof Error ? err.name : 'UnknownError',
    }));
  }
}

export async function recordBatchAccessAudit(
  db: Database,
  actor: Actor,
  requestIds: string[],
  kind = 'list_contact_view',
) {
  if (actor.role !== 'admin' || requestIds.length === 0) return;
  try {
    await db.pool.query(
      `INSERT INTO access_audit (id, actor_id, request_id, kind, at)
       SELECT gen_random_uuid(), $1, req_id, $2, clock_timestamp()
       FROM unnest($3::uuid[]) AS req_id
       WHERE NOT EXISTS (
         SELECT 1 FROM access_audit
         WHERE actor_id = $1 AND request_id = req_id
         AND at > clock_timestamp() - interval '1 hour'
       )`,
      [actor.id, kind, requestIds],
    );
  } catch (err: unknown) {
    console.error(JSON.stringify({
      event: 'audit_write_failed',
      requestIds,
      error: err instanceof Error ? err.name : 'UnknownError',
    }));
  }
}
