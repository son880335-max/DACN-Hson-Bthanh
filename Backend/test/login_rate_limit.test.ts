import test from 'node:test';
import assert from 'node:assert/strict';
import { hash } from '@node-rs/argon2';
import { AuthService, passwordOptions } from '../src/auth/auth.service.js';
import { loadConfig } from '../src/common/config.js';
import { ApiError } from '../src/common/errors.js';

test('AuthService rate limits 5 failed login attempts per normalized phone within 15 minutes', async () => {
  const config = loadConfig({
    DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db',
    NODE_ENV: 'test',
  });

  const correctPassword = 'CorrectPassword123!';
  const passwordHash = await hash(correctPassword, passwordOptions);

  const fakeAccount = {
    id: '11111111-1111-1111-1111-111111111111',
    phone: '+84912345678',
    password_hash: passwordHash,
    display_name: 'Test Citizen',
    role: 'citizen',
    permissions: [],
    phone_verified_at: new Date(),
    team_approved: true,
    is_test_account: false,
    locked_at: null,
  };

  const fakeDb: any = {
    pool: {
      query: async (sql: string, params: any[]) => {
        if (sql.includes('SELECT * FROM accounts WHERE phone=')) {
          if (params[0] === '+84912345678') {
            return { rows: [fakeAccount] };
          }
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO sessions')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
    },
  };

  const auth = new AuthService(fakeDb, config);

  // 1. First 4 failures return 401 INVALID_CREDENTIALS
  for (let i = 1; i <= 4; i++) {
    await assert.rejects(
      () => auth.login({ phone: '0912345678', password: 'wrong-password' }),
      (err: any) => {
        assert.ok(err instanceof ApiError);
        assert.equal(err.status, 401);
        assert.equal(err.code, 'INVALID_CREDENTIALS');
        assert.equal(err.message, 'Số điện thoại hoặc mật khẩu không đúng.');
        return true;
      }
    );
  }

  // 2. 5th failure also returns 401
  await assert.rejects(
    () => auth.login({ phone: '+84 912 345 678', password: 'wrong-password' }),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 401);
      assert.equal(err.code, 'INVALID_CREDENTIALS');
      return true;
    }
  );

  // 3. 6th attempt with the same phone (even normalized differently) is blocked with 429 + Retry-After
  await assert.rejects(
    () => auth.login({ phone: '0912345678', password: 'any-password' }),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 429);
      assert.equal(err.code, 'RATE_LIMITED');
      assert.ok(err.headers?.['Retry-After']);
      assert.ok(Number(err.headers['Retry-After']) > 0);
      return true;
    }
  );

  // 4. Non-existent account fails with the exact same error and also counts towards phone rate limit
  const unknownPhone = '0987654321';
  await assert.rejects(
    () => auth.login({ phone: unknownPhone, password: 'random-password' }),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 401);
      assert.equal(err.code, 'INVALID_CREDENTIALS');
      assert.equal(err.message, 'Số điện thoại hoặc mật khẩu không đúng.');
      return true;
    }
  );

  // 5. Successful login resets counter
  // Reset the blocked phone's failure map entry to simulate timer expiration or fresh state
  auth.phoneFailures.delete('+84912345678');
  // First make 2 failures
  await assert.rejects(() => auth.login({ phone: '0912345678', password: 'wrong' }));
  await assert.rejects(() => auth.login({ phone: '0912345678', password: 'wrong' }));
  assert.equal(auth.phoneFailures.get('+84912345678')?.count, 2);

  // Successful login
  const success = await auth.login({ phone: '0912345678', password: correctPassword });
  assert.ok(success.token);
  assert.equal(auth.phoneFailures.has('+84912345678'), false, 'Successful login must reset phone failure counter');
});
