import 'dotenv/config';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { hash } from '@node-rs/argon2';
import { loadConfig } from '../src/common/config.js';
import { createDatabase } from '../src/common/database.js';
import { passwordOptions } from '../src/auth/auth.service.js';

async function main() {
  const config = loadConfig();
  if (config.NODE_ENV !== 'development') throw new Error('Development accounts are only available in NODE_ENV=development');
  const db = createDatabase(config.DATABASE_URL);
  const definitions = [
    { phone: '+12025550101', displayName: 'Tài khoản thử nghiệm người dân', role: 'citizen', permissions: [] },
    { phone: '+12025550102', displayName: 'Tài khoản thử nghiệm đội cứu hộ', role: 'rescue', permissions: [] },
    { phone: '+12025550103', displayName: 'Tài khoản thử nghiệm quản trị', role: 'admin', permissions: ['requests:read', 'requests:review'] },
  ];
  const credentials = [];
  try {
    for (const definition of definitions) {
      const password = randomBytes(20).toString('base64url');
      const passwordHash = await hash(password, passwordOptions);
      const result=await db.pool.query(`INSERT INTO accounts(id,phone,display_name,password_hash,role,permissions,phone_verified_at,team_approved,is_test_account)
        VALUES($1,$2,$3,$4,$5,$6,clock_timestamp(),$7,true)
        ON CONFLICT(phone) DO UPDATE SET display_name=EXCLUDED.display_name,password_hash=EXCLUDED.password_hash,
        role=EXCLUDED.role,permissions=EXCLUDED.permissions,phone_verified_at=EXCLUDED.phone_verified_at,
        team_approved=EXCLUDED.team_approved,is_test_account=true WHERE accounts.is_test_account=true RETURNING id`,
      [randomUUID(), definition.phone, definition.displayName, passwordHash, definition.role, definition.permissions, definition.role === 'rescue']);
      if(!result.rowCount)throw new Error('Refusing to overwrite a non-test account. Development seed stopped.');
      credentials.push({ ...definition, password, testOnly: true });
    }
    await mkdir('.local', { recursive: true });
    await writeFile('.local/dev-accounts.json', JSON.stringify(credentials, null, 2), { mode: 0o600 });
    console.log('Development-only accounts created. Credentials are in ignored .local/dev-accounts.json. No SMS was sent.');
  } finally { await db.pool.end(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
