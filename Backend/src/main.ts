import 'dotenv/config';
import { createApp } from './app.js';
import { loadConfig } from './common/config.js';
import { createDatabase } from './common/database.js';

async function main() {
  const config = loadConfig();
  const db = createDatabase(config.DATABASE_URL);
  const app = await createApp(config, db);
  const close = async () => { await app.close(); await db.pool.end(); };
  process.once('SIGINT', () => void close());
  process.once('SIGTERM', () => void close());
  await app.listen(config.PORT, config.HOST);
}
main().catch(error => { console.error(error instanceof Error ? error.message : 'Startup failed'); process.exitCode = 1; });
