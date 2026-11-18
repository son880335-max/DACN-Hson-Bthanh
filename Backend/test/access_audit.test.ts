import test from 'node:test';
import assert from 'node:assert/strict';
import { recordAccessAudit, recordBatchAccessAudit } from '../src/common/audit.js';

test('recordAccessAudit and recordBatchAccessAudit log views without personal info and throttle per hour', async () => {
  const auditRows: any[] = [];

  const mockDb: any = {
    pool: {
      query: async (sql: string, params: any[]) => {
        if (sql.includes('INSERT INTO access_audit')) {
          if (sql.includes('unnest')) {
            // Batch insert
            const [actorId, kind, requestIds] = params;
            const oneHourAgo = Date.now() - 3600_000;
            for (const reqId of requestIds) {
              const existing = auditRows.find(
                r => r.actor_id === actorId && r.request_id === reqId && r.at.getTime() > oneHourAgo
              );
              if (!existing) {
                auditRows.push({ id: 'gen-uuid', actor_id: actorId, request_id: reqId, kind, at: new Date() });
              }
            }
            return { rowCount: requestIds.length };
          } else {
            const [id, actorId, requestId, kind] = params;
            const oneHourAgo = Date.now() - 3600_000;
            const existingRecent = auditRows.find(
              r => r.actor_id === actorId && r.request_id === requestId && r.at.getTime() > oneHourAgo
            );
            if (!existingRecent) {
              const newRow = { id, actor_id: actorId, request_id: requestId, kind, at: new Date() };
              auditRows.push(newRow);
              return { rowCount: 1, rows: [newRow] };
            }
            return { rowCount: 0, rows: [] };
          }
        }
        return { rows: [] };
      },
    },
  };

  const ownerId = '11111111-1111-1111-1111-111111111111';
  const requestId = '99999999-9999-9999-9999-999999999999';

  const citizenActor: any = { id: ownerId, role: 'citizen' };
  const adminActor: any = { id: '22222222-2222-2222-2222-222222222222', role: 'admin' };

  // 1. Citizen (owner) views their own request: no audit recorded
  await recordAccessAudit(mockDb, citizenActor, requestId, ownerId, 'request_detail_view');
  assert.equal(auditRows.length, 0);

  // 2. Admin views request: records 1 audit row
  await recordAccessAudit(mockDb, adminActor, requestId, ownerId, 'request_detail_view');
  assert.equal(auditRows.length, 1);
  const row = auditRows[0];
  assert.equal(row.actor_id, adminActor.id);
  assert.equal(row.request_id, requestId);
  assert.equal(row.kind, 'request_detail_view');
  assert.equal((row as any).phone, undefined, 'Must not store phone number in audit table');
  assert.equal((row as any).lat, undefined, 'Must not store coordinates in audit table');
  assert.equal((row as any).lon, undefined, 'Must not store coordinates in audit table');

  // 3. Admin views again within 1 hour: throttled, no new row
  await recordAccessAudit(mockDb, adminActor, requestId, ownerId, 'request_detail_view');
  assert.equal(auditRows.length, 1, 'Throttled to at most 1 row per actor per request per hour');

  // 4. Batch audit: Admin views page of requests with contacts
  const pageIds = [
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    requestId, // Already viewed above within 1 hour
  ];
  await recordBatchAccessAudit(mockDb, adminActor, pageIds, 'list_contact_view');
  // Should add 2 new rows (for a and b), while requestId is throttled
  assert.equal(auditRows.length, 3);
  const batchAdded = auditRows.filter(r => r.kind === 'list_contact_view');
  assert.equal(batchAdded.length, 2);
});

test('recordAccessAudit catches write error and logs audit_write_failed without PII', async () => {
  const failingDb: any = {
    pool: {
      query: async () => {
        throw new Error('connection lost');
      },
    },
  };

  const capturedErrors: string[] = [];
  const originalError = console.error;
  console.error = (msg: string) => {
    capturedErrors.push(msg);
  };

  try {
    const rescueActor: any = { id: '33333333-3333-3333-3333-333333333333', role: 'rescue' };
    const requestId = '99999999-9999-9999-9999-999999999999';
    const ownerId = '11111111-1111-1111-1111-111111111111';

    // Must not throw, allows request to proceed
    await recordAccessAudit(failingDb, rescueActor, requestId, ownerId, 'dispatch_detail_view');

    assert.equal(capturedErrors.length, 1);
    const entry0 = capturedErrors[0] ?? '';
    const parsed = JSON.parse(entry0);
    assert.equal(parsed.event, 'audit_write_failed');
    assert.equal(parsed.requestId, requestId);
    assert.ok(!entry0.includes('phone'));
    assert.ok(!entry0.includes('lat'));
    assert.ok(!entry0.includes('lon'));

    // Also verify batch handles error safely
    const adminActor: any = { id: '22222222-2222-2222-2222-222222222222', role: 'admin' };
    await recordBatchAccessAudit(failingDb, adminActor, [requestId], 'list_contact_view');
    assert.equal(capturedErrors.length, 2);
    const entry1 = capturedErrors[1] ?? '';
    const parsedBatch = JSON.parse(entry1);
    assert.equal(parsedBatch.event, 'audit_write_failed');
    assert.deepEqual(parsedBatch.requestIds, [requestId]);
  } finally {
    console.error = originalError;
  }
});
