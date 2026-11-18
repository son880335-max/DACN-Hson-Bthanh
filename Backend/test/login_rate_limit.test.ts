import test from 'node:test';
import assert from 'node:assert/strict';
import { hash } from '@node-rs/argon2';
import { AuthService, passwordOptions } from '../src/auth/auth.service.js';
import { loadConfig } from '../src/common/config.js';
import { ApiError } from '../src/common/errors.js';

test('AuthService rate limits by (phone + IP) pair (5 fails) and phone threshold (20 fails), without locking out other IPs', async () => {
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

  const ipAttacker = '192.168.1.100';
  const ipVictim = '192.168.1.200';

  // 1. Attacker fails 5 times for victim phone on ipAttacker
  for (let i = 1; i <= 5; i++) {
    await assert.rejects(
      () => auth.login({ phone: '0912345678', password: 'wrong-password' }, ipAttacker),
      (err: any) => {
        assert.ok(err instanceof ApiError);
        assert.equal(err.status, 401);
        assert.equal(err.code, 'INVALID_CREDENTIALS');
        assert.equal(err.message, 'Số điện thoại hoặc mật khẩu không đúng.');
        return true;
      }
    );
  }

  // 6th attempt from ipAttacker is blocked with 429 + Retry-After
  await assert.rejects(
    () => auth.login({ phone: '+84 912 345 678', password: 'wrong-password' }, ipAttacker),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 429);
      assert.equal(err.code, 'RATE_LIMITED');
      assert.ok(err.headers?.['Retry-After']);
      assert.ok(Number(err.headers['Retry-After']) > 0);
      return true;
    }
  );

  // 2. Legitimate user on ipVictim is NOT blocked by attacker's failed attempts (DoS prevention)
  const legitSuccess = await auth.login({ phone: '0912345678', password: correctPassword }, ipVictim);
  assert.ok(legitSuccess.token, 'Victim on different IP can still log in');

  // Successful login only clears pairFailures for that pair (phone:ipVictim)
  assert.equal(auth.pairFailures.has('+84912345678:192.168.1.200'), false);
  // Attacker IP pair remains blocked
  assert.equal(auth.pairFailures.has('+84912345678:192.168.1.100'), true);

  // 3. Global phone threshold: 20 failures within 15 minutes across any IPs triggers global phone lock
  // Step 1 recorded 5 failures in phoneFailures.
  // Generate 15 more failures from unique IPs to reach 20 failures for this phone.
  for (let i = 6; i <= 20; i++) {
    await assert.rejects(
      () => auth.login({ phone: '0912345678', password: 'wrong' }, `10.0.0.${i}`),
      (err: any) => {
        assert.equal(err.status, 401);
        return true;
      }
    );
  }

  // 21st attempt from a brand new IP (10.0.0.99) is now blocked by the 20-failure global phone threshold
  await assert.rejects(
    () => auth.login({ phone: '0912345678', password: correctPassword }, '10.0.0.99'),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 429);
      assert.equal(err.code, 'RATE_LIMITED');
      assert.ok(err.headers?.['Retry-After']);
      return true;
    }
  );

  // 4. Non-existent account fails with identical message
  await assert.rejects(
    () => auth.login({ phone: '0987654321', password: 'wrong' }, '1.2.3.4'),
    (err: any) => {
      assert.ok(err instanceof ApiError);
      assert.equal(err.status, 401);
      assert.equal(err.code, 'INVALID_CREDENTIALS');
      assert.equal(err.message, 'Số điện thoại hoặc mật khẩu không đúng.');
      return true;
    }
  );
});

