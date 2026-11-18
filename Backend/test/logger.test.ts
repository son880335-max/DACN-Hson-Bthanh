import test from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';
import { loadConfig } from '../src/common/config.js';

test('Fastify request logger serializes req without query string and excludes lat, lon, and search params', async () => {
  const config = loadConfig({
    DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db',
    NODE_ENV: 'test',
  });

  const rescueActor = {
    id: '44444444-4444-4444-4444-444444444444',
    phone: '+84988888888',
    display_name: 'Rescue Team',
    role: 'rescue',
    permissions: [],
    phone_verified_at: new Date(),
    team_approved: true,
    is_test_account: false,
    locked_at: null,
  };

  const mockDb: any = {
    pool: {
      query: async (sql: string) => {
        if (sql.includes('SELECT a.* FROM accounts')) {
          return { rows: [rescueActor] };
        }
        return { rows: [] };
      },
    },
  };

  const mockStorage: any = {
    put: async () => {},
    get: async () => Buffer.from(''),
    delete: async () => {},
  };

  const capturedLogs: string[] = [];
  const originalWrite = process.stdout.write;
  process.stdout.write = (chunk: any) => {
    capturedLogs.push(chunk.toString());
    return true;
  };

  let app: any;
  try {
    app = await createApp(config, mockDb, mockStorage);
    const validToken = '1234567890123456789012345678901234567890123';
    const response = await app.inject({
      method: 'GET',
      url: '/api/v1/dispatch?mode=waiting&lat=10.5&lon=106.5&km=5',
      headers: {
        authorization: 'Bearer ' + validToken,
      },
    });

    assert.equal(response.statusCode, 200, response.body);

    const logOutput = capturedLogs.join('\n');
    assert.ok(logOutput.length > 0, 'Logger should have recorded request logs');

    // Find the req log
    const reqLogs = capturedLogs
      .map(line => {
        try { return JSON.parse(line); } catch { return null; }
      })
      .filter(entry => entry && entry.req);

    assert.ok(reqLogs.length > 0, 'Should have logged req object');
    for (const entry of reqLogs) {
      assert.equal(entry.req.method, 'GET');
      assert.equal(entry.req.url, '/api/v1/dispatch');
      assert.ok(entry.req.id, 'Must contain req id');
    }

    // Verify coordinates and query parameters are NOT in any logged line
    assert.ok(!logOutput.includes('10.5'), 'Must not log lat coordinate 10.5');
    assert.ok(!logOutput.includes('106.5'), 'Must not log lon coordinate 106.5');
    assert.ok(!logOutput.includes('lat='), 'Must not log query string lat=');
  } finally {
    process.stdout.write = originalWrite;
    await app?.close();
  }
});
