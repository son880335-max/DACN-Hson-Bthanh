import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Pool, PoolClient } from 'pg';

export class Database {
  constructor(readonly pool: Pool) {}
  async transaction<T>(action: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query("SET LOCAL statement_timeout = '10s'");
      await client.query("SET LOCAL lock_timeout = '5s'");
      const result = await action(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally { client.release(); }
  }
  async migrate(directory = resolve('migrations')) {
    await this.transaction(async client => {
      await client.query("SELECT pg_advisory_xact_lock(hashtext('flood-relief-migrations'))");
      await client.query('CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())');
      const files = (await readdir(directory)).filter(f => /^\d+.*\.sql$/.test(f)).sort();
      for (const file of files) {
        const sql = await readFile(resolve(directory, file), 'utf8');
        const checksum = createHash('sha256').update(sql).digest('hex');
        const existing = await client.query('SELECT checksum FROM schema_migrations WHERE name=$1', [file]);
        if (existing.rowCount) {
          if (existing.rows[0].checksum !== checksum) throw new Error(`Applied migration changed: ${file}`);
          continue;
        }
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations(name,checksum) VALUES($1,$2)', [file, checksum]);
      }
    });
  }
}

export function createDatabase(connectionString: string) {
  return new Database(new Pool({ connectionString, max: 5, connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30_000, application_name: 'flood-relief-api' }));
}
