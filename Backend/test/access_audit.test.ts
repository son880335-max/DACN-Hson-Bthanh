import test from 'node:test';
import assert from 'node:assert/strict';
import { recordAccessAudit } from '../src/common/audit.js';

test('recordAccessAudit logs non-owner views, throttles to 1 per actor/request/hour, and never stores phone or coordinates', async () => {
  const auditRows: any[] = [];

  const mockDb: any = {
    pool: {
      query: async (sql: string, params: any[]) => {
        if (sql.includes('INSERT INTO access_audit')) {
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
        return { rows: [] };
      },
    },
  };

  const ownerId = '11111111-1111-1111-1111-111111111111';
  const requestId = '99999999-9999-9999-9999-999999999999';

  const citizenOwner = {
    id: ownerId,
    phone: '+84912345678',
    displayName: 'Citizen Owner',
    role: 'citizen' as const,
    permissions: [],
    verified: true,
    teamApproved: false,
    testAccount: false,
  };

  const adminActor = {
    id: '33333333-3333-3333-3333-333333333333',
    phone: '+84999999999',
    displayName: 'Admin User',
    role: 'admin' as const,
    permissions: ['requests:read'],
    verified: true,
    teamApproved: false,
    testAccount: false,
  };

  const rescueActor = {
    id: '44444444-4444-4444-4444-444444444444',
    phone: '+84988888888',
    displayName: 'Rescue Team',
    role: 'rescue' as const,
    permissions: [],
    verified: true,
    teamApproved: true,
    testAccount: false,
  };

  // 1. Citizen viewing their own request: must NOT record audit
  await recordAccessAudit(mockDb, citizenOwner, requestId, ownerId, 'request_detail_view');
  assert.equal(auditRows.length, 0);

  // 2. Admin viewing request: records exactly 1 audit row
  await recordAccessAudit(mockDb, adminActor, requestId, ownerId, 'request_detail_view');
  assert.equal(auditRows.length, 1);
  const row1 = auditRows[0];
  assert.equal(row1.actor_id, adminActor.id);
  assert.equal(row1.request_id, requestId);
  assert.equal(row1.kind, 'request_detail_view');
  assert.ok(!('phone' in row1), 'Must not store phone');
  assert.ok(!('latitude' in row1), 'Must not store latitude');
  assert.ok(!('longitude' in row1), 'Must not store longitude');

  // 3. Admin viewing the same request again within 1 hour: throttled, does not create a second row
  await recordAccessAudit(mockDb, adminActor, requestId, ownerId, 'request_detail_view');
  assert.equal(auditRows.length, 1, 'Throttled to at most 1 row per actor per request per hour');

  // 4. Rescue team viewing the request: records another row for that rescue actor
  await recordAccessAudit(mockDb, rescueActor, requestId, ownerId, 'dispatch_detail_view');
  assert.equal(auditRows.length, 2);
  const row2 = auditRows[1];
  assert.equal(row2.actor_id, rescueActor.id);
  assert.equal(row2.request_id, requestId);
  assert.equal(row2.kind, 'dispatch_detail_view');

  // 5. Rescue viewing again within 1 hour: throttled
  await recordAccessAudit(mockDb, rescueActor, requestId, ownerId, 'dispatch_detail_view');
  assert.equal(auditRows.length, 2);
});
