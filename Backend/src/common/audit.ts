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
}
