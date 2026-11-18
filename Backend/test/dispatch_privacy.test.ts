import test from 'node:test';
import assert from 'node:assert/strict';
import { dispatchController } from '../src/dispatch/dispatch.controller.js';
import { ApiError } from '../src/common/errors.js';

test('DispatchController enforces location privacy, km validation, and 30 req/min location rate limit', async () => {
  const actor = {
    id: '22222222-2222-2222-2222-222222222222',
    phone: '+84988888888',
    displayName: 'Rescue Team',
    role: 'rescue' as const,
    permissions: [],
    verified: true,
    teamApproved: true,
    testAccount: false,
  };

  const executedQueries: Array<{ sql: string; params: any[] }> = [];

  const mockDb: any = {
    pool: {
      query: async (sql: string, params: any[]) => {
        executedQueries.push({ sql, params });
        return { rows: [] };
      },
    },
  };

  const mockAuth: any = {
    authenticate: async () => actor,
  };

  const mockOperations: any = {};

  const ControllerClass = dispatchController(mockDb, mockAuth, mockOperations);
  const controller = new ControllerClass();

  // 1. km parameter validation: accepts 1, 3, 5, 10, 20, 50
  for (const km of [1, 3, 5, 10, 20, 50]) {
    await controller.list('token', { mode: 'waiting', lat: '16.46', lon: '107.59', km: String(km) });
  }

  // Rejects invalid km values (e.g. 2, 25, 100)
  for (const invalidKm of [2, 25, 100, 500]) {
    await assert.rejects(
      () => controller.list('token', { mode: 'waiting', lat: '16.46', lon: '107.59', km: String(invalidKm) }),
      /Khoảng cách km chỉ nhận một trong các giá trị: 1, 3, 5, 10, 20, 50/
    );
  }

  // 2. Mode=waiting calculates distance from coordinates rounded to 2 decimal places
  const waitingQuery = executedQueries.find(q => q.params[0] === 'waiting');
  assert.ok(waitingQuery, 'Must have executed a query for mode=waiting');
  assert.ok(waitingQuery.sql.includes('round(r.latitude::numeric, 2)'), 'Waiting mode distance must use rounded latitude');
  assert.ok(waitingQuery.sql.includes('round(r.longitude::numeric, 2)'), 'Waiting mode distance must use rounded longitude');

  // 3. Rate limiting: 30 requests per minute per account with lat/lon
  // We already performed 6 queries above with lat/lon. Perform 24 more queries to hit 30.
  for (let i = 7; i <= 30; i++) {
    await controller.list('token', { mode: 'waiting', lat: '16.46', lon: '107.59', km: '5' });
  }

  // 31st query with lat/lon must be rejected with 429 RATE_LIMITED
  await assert.rejects(
    () => controller.list('token', { mode: 'waiting', lat: '16.46', lon: '107.59', km: '5' }),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 429);
      assert.equal(err.code, 'RATE_LIMITED');
      assert.ok(err.headers?.['Retry-After']);
      return true;
    }
  );

  // Queries WITHOUT lat/lon are NOT blocked by the location query rate limit
  await controller.list('token', { mode: 'waiting' });
});
