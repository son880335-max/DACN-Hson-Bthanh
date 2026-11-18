import test from 'node:test';
import assert from 'node:assert/strict';
import { runMaintenance } from '../src/common/maintenance.js';

test('runMaintenance dry-run counts items, and live run deletes aged sessions, receipts, and unlinked evidence files', async () => {
  const executedSql: string[] = [];
  const deletedFiles: string[] = [];

  const mockDb: any = {
    pool: {
      query: async (sql: string, params?: any[]) => {
        executedSql.push(sql);
        if (sql.includes('SELECT count(*)::int AS count FROM sessions')) {
          return { rows: [{ count: 3 }] };
        }
        if (sql.includes('SELECT count(*)::int AS count FROM operation_receipts')) {
          return { rows: [{ count: 5 }] };
        }
        if (sql.includes('SELECT count(*)::int AS count FROM evidence')) {
          return { rows: [{ count: 2 }] };
        }
        if (sql.includes('DELETE FROM sessions')) {
          return { rowCount: 3 };
        }
        if (sql.includes('DELETE FROM operation_receipts')) {
          return { rowCount: 5 };
        }
        if (sql.includes('SELECT id, storage_key FROM evidence')) {
          return {
            rows: [
              { id: '11111111-1111-1111-1111-111111111111', storage_key: '11111111-1111-1111-1111-111111111111.jpg' },
              { id: '22222222-2222-2222-2222-222222222222', storage_key: '22222222-2222-2222-2222-222222222222.jpg' },
            ],
          };
        }
        if (sql.includes('DELETE FROM evidence')) {
          return { rowCount: 2 };
        }
        return { rows: [] };
      },
    },
  };

  const mockStorage: any = {
    put: async () => {},
    get: async () => Buffer.from(''),
    delete: async (key: string) => {
      deletedFiles.push(key);
    },
  };

  // 1. Dry run
  const dryResult = await runMaintenance(mockDb, mockStorage, { dryRun: true, retentionDays: 30 });
  assert.equal(dryResult.dryRun, true);
  assert.equal(dryResult.sessions, 3);
  assert.equal(dryResult.operationReceipts, 5);
  assert.equal(dryResult.unlinkedEvidence, 2);
  assert.equal(deletedFiles.length, 0, 'Dry run must not delete any files');
  assert.ok(!executedSql.some(sql => sql.includes('DELETE FROM')), 'Dry run must not execute DELETE');

  // 2. Live run
  executedSql.length = 0;
  const liveResult = await runMaintenance(mockDb, mockStorage, { dryRun: false, retentionDays: 30 });
  assert.equal(liveResult.dryRun, false);
  assert.equal(liveResult.sessions, 3);
  assert.equal(liveResult.operationReceipts, 5);
  assert.equal(liveResult.unlinkedEvidence, 2);

  // Storage should have deleted both original and thumbnail files for the 2 unlinked evidence
  assert.equal(deletedFiles.length, 4);
  assert.ok(deletedFiles.includes('11111111-1111-1111-1111-111111111111.jpg'));
  assert.ok(deletedFiles.includes('11111111-1111-1111-1111-111111111111.thumb.jpg'));
  assert.ok(deletedFiles.includes('22222222-2222-2222-2222-222222222222.jpg'));
  assert.ok(deletedFiles.includes('22222222-2222-2222-2222-222222222222.thumb.jpg'));

  // Database DELETE statements should have been executed
  assert.ok(executedSql.some(sql => sql.includes('DELETE FROM sessions')));
  assert.ok(executedSql.some(sql => sql.includes('DELETE FROM operation_receipts')));
  assert.ok(executedSql.some(sql => sql.includes('DELETE FROM evidence')));
});
