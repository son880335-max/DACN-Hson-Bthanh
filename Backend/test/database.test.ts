import test from 'node:test';
import assert from 'node:assert/strict';
import { createDatabase } from '../src/common/database.js';

test('database pool registers error listener that logs generic message without leaking credentials', () => {
  const connectionString = 'postgresql://secret_user:super_secret_password@127.0.0.1:5432/test_db';
  const db = createDatabase(connectionString);
  try {
    assert.equal(db.pool.listenerCount('error'), 1);

    const logged: string[] = [];
    const originalError = console.error;
    console.error = (msg: string) => { logged.push(msg); };
    try {
      db.pool.emit('error', new Error('Connection terminated unexpectedly in postgresql://secret_user:super_secret_password@127.0.0.1:5432/test_db'));
      assert.equal(logged.length, 1);
      const entry = logged[0] ?? '';
      const parsed = JSON.parse(entry);
      assert.equal(parsed.event, 'database_pool_error');
      assert.ok(!entry.includes('super_secret_password'), 'Must not leak connection password');
    } finally {
      console.error = originalError;
    }
  } finally {
    void db.pool.end();
  }
});
