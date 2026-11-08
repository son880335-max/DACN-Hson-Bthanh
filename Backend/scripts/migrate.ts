import 'dotenv/config';
import { loadConfig } from '../src/common/config.js';
import { createDatabase } from '../src/common/database.js';

async function main() {
  const db = createDatabase(loadConfig().DATABASE_URL);
  try { await db.migrate(); console.log('Migrations applied.'); }
  finally { await db.pool.end(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
