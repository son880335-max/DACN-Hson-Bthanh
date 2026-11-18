import test from 'node:test';
import assert from 'node:assert/strict';
import { loadConfig } from '../src/common/config.js';

test('loadConfig validates sslmode on production DATABASE_URL unless DB_ALLOW_INSECURE is true', () => {
  const baseEnv = {
    HOST: '127.0.0.1',
    PORT: '3000',
    CORS_ORIGINS: 'https://example.com',
  };

  // Development: non-ssl is allowed
  const devConfig = loadConfig({
    ...baseEnv,
    NODE_ENV: 'development',
    DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db',
  });
  assert.equal(devConfig.NODE_ENV, 'development');
  assert.equal(devConfig.TRUST_PROXY, false);

  // Production without sslmode: throws error
  assert.throws(
    () => loadConfig({
      ...baseEnv,
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db',
    }),
    /Production DATABASE_URL must include sslmode=require or sslmode=verify-full/
  );

  // Production with sslmode=disable: throws error
  assert.throws(
    () => loadConfig({
      ...baseEnv,
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db?sslmode=disable',
    }),
    /Production DATABASE_URL must include sslmode=require or sslmode=verify-full/
  );

  // Production with sslmode=require: succeeds
  const prodRequire = loadConfig({
    ...baseEnv,
    NODE_ENV: 'production',
    DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db?sslmode=require',
  });
  assert.equal(prodRequire.NODE_ENV, 'production');

  // Production with sslmode=verify-full: succeeds
  const prodVerify = loadConfig({
    ...baseEnv,
    NODE_ENV: 'production',
    DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db?sslmode=verify-full',
  });
  assert.equal(prodVerify.NODE_ENV, 'production');

  // Production without sslmode but DB_ALLOW_INSECURE=true: succeeds
  const prodInsecure = loadConfig({
    ...baseEnv,
    NODE_ENV: 'production',
    DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db',
    DB_ALLOW_INSECURE: 'true',
    TRUST_PROXY: 'true',
  });
  assert.equal(prodInsecure.NODE_ENV, 'production');
  assert.equal(prodInsecure.DB_ALLOW_INSECURE, true);
  assert.equal(prodInsecure.TRUST_PROXY, true);
});
