import test from 'node:test';
import assert from 'node:assert/strict';
import { ApiErrorFilter, ApiError } from '../src/common/errors.js';

test('ApiErrorFilter masks 5xx errors without leaking SQL or stack traces, and includes requestId', () => {
  const filter = new ApiErrorFilter();

  let sentStatus: number | null = null;
  let sentBody: any = null;
  const loggedErrors: string[] = [];

  const mockResponse = {
    header: () => mockResponse,
    status: (code: number) => {
      sentStatus = code;
      return mockResponse;
    },
    send: (body: any) => {
      sentBody = body;
      return mockResponse;
    },
  };

  const mockRequest = {
    id: 'req-test-12345',
  };

  const mockHost: any = {
    switchToHttp: () => ({
      getResponse: () => mockResponse,
      getRequest: () => mockRequest,
    }),
  };

  const originalConsoleError = console.error;
  console.error = (msg: string) => { loggedErrors.push(msg); };

  try {
    // 1. Database error containing raw SQL and stack
    const dbError = new Error('syntax error at or near "SELECT * FROM accounts WHERE password_hash = ...');
    dbError.name = 'DatabaseError';
    (dbError as any).stack = 'DatabaseError: syntax error...\n at pg.query (/node_modules/pg/client.js:123)';

    filter.catch(dbError, mockHost);

    assert.equal(sentStatus, 500);
    assert.equal(sentBody.code, 'INTERNAL_ERROR');
    assert.equal(sentBody.requestId, 'req-test-12345');
    assert.equal(sentBody.message, 'Hệ thống chưa xử lý được. Hãy giữ thông tin và thử lại.');
    assert.ok(!JSON.stringify(sentBody).includes('SELECT'), 'Client body must not leak SQL');
    assert.ok(!JSON.stringify(sentBody).includes('stack'), 'Client body must not leak stack');
    assert.ok(!JSON.stringify(sentBody).includes('/node_modules/'), 'Client body must not leak stack trace paths');

    // Server log should have recorded requestId
    assert.ok(loggedErrors.some(log => log.includes('req-test-12345')), 'Server log must contain requestId');

    // 2. ApiError with 500
    sentStatus = null;
    sentBody = null;
    const api500 = new ApiError(500, 'CRITICAL_FAILURE', 'Sensitive backend details');
    filter.catch(api500, mockHost);

    assert.equal(sentStatus, 500);
    assert.equal(sentBody.code, 'CRITICAL_FAILURE');
    assert.equal(sentBody.requestId, 'req-test-12345');
    assert.equal(sentBody.message, 'Hệ thống chưa xử lý được. Hãy giữ thông tin và thử lại.');
  } finally {
    console.error = originalConsoleError;
  }
});
