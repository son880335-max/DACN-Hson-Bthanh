import { Database } from './database.js';
import { ObjectStorage } from '../evidence/storage.js';

export interface MaintenanceResult {
  sessions: number;
  operationReceipts: number;
  unlinkedEvidence: number;
  dryRun: boolean;
}

export async function runMaintenance(
  db: Database,
  storage: ObjectStorage,
  options: { dryRun?: boolean; retentionDays?: number } = {},
): Promise<MaintenanceResult> {
  const dryRun = options.dryRun ?? false;
  const retentionDays = options.retentionDays ?? 30;

  const sessionsCondition = `
    (revoked_at IS NOT NULL AND revoked_at < clock_timestamp() - interval '7 days')
    OR (expires_at < clock_timestamp() - interval '7 days')
  `;

  const receiptsCondition = `created_at < clock_timestamp() - ($1 || ' days')::interval`;
  const evidenceCondition = `request_id IS NULL AND received_at < clock_timestamp() - interval '24 hours'`;

  if (dryRun) {
    const [sessRes, recRes, evRes] = await Promise.all([
      db.pool.query(`SELECT count(*)::int AS count FROM sessions WHERE ${sessionsCondition}`),
      db.pool.query(`SELECT count(*)::int AS count FROM operation_receipts WHERE ${receiptsCondition}`, [retentionDays]),
      db.pool.query(`SELECT count(*)::int AS count FROM evidence WHERE ${evidenceCondition}`),
    ]);

    return {
      sessions: sessRes.rows[0]?.count ?? 0,
      operationReceipts: recRes.rows[0]?.count ?? 0,
      unlinkedEvidence: evRes.rows[0]?.count ?? 0,
      dryRun: true,
    };
  }

  const sessDel = await db.pool.query(`DELETE FROM sessions WHERE ${sessionsCondition}`);
  const sessionsCount = sessDel.rowCount ?? 0;

  const recDel = await db.pool.query(`DELETE FROM operation_receipts WHERE ${receiptsCondition}`, [retentionDays]);
  const receiptsCount = recDel.rowCount ?? 0;

  const evRows = await db.pool.query(`SELECT id, storage_key FROM evidence WHERE ${evidenceCondition}`);
  const evidenceList = evRows.rows as Array<{ id: string; storage_key: string }>;

  for (const item of evidenceList) {
    await storage.delete(item.storage_key).catch(() => undefined);
    await storage.delete(`${item.id}.thumb.jpg`).catch(() => undefined);
  }

  if (evidenceList.length > 0) {
    const ids = evidenceList.map(e => e.id);
    await db.pool.query(`DELETE FROM evidence WHERE id = ANY($1::uuid[])`, [ids]);
  }

  return {
    sessions: sessionsCount,
    operationReceipts: receiptsCount,
    unlinkedEvidence: evidenceList.length,
    dryRun: false,
  };
}
