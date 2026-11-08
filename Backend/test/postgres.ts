import { randomBytes } from 'node:crypto';
import { execFile, spawn } from 'node:child_process';
import { mkdtemp, writeFile, unlink } from 'node:fs/promises';
import { createServer } from 'node:net';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { promisify } from 'node:util';

const execute = promisify(execFile);
export async function startTestPostgres() {
  if (process.env.TEST_DATABASE_URL) return { url: process.env.TEST_DATABASE_URL, stop: async () => {} };
  if (process.platform !== 'win32') throw new Error('Set TEST_DATABASE_URL to a dedicated, disposable PostgreSQL database');
  const binaries = await import('@embedded-postgres/' + 'windows-x64') as { initdb: string; postgres: string };
  const directory = await mkdtemp(join(tmpdir(), 'dacn-postgres-test-'));
  const data = join(directory, 'data');
  const password = randomBytes(32).toString('hex');
  const passwordFile = join(directory, 'init-password');
  const listener = createServer();
  await new Promise<void>(resolve => listener.listen(0, '127.0.0.1', resolve));
  const address = listener.address();
  if (!address || typeof address === 'string') throw new Error('No test port');
  const port = address.port;
  await new Promise<void>((resolve, reject) => listener.close(error => error ? reject(error) : resolve()));
  await writeFile(passwordFile, password, { mode: 0o600 });
  try {
    await execute(binaries.initdb, ['-D', data, '--username=postgres', '--auth=scram-sha-256', '--encoding=UTF8', '--locale=C', '--pwfile=' + passwordFile], { windowsHide: true });
  } finally { await unlink(passwordFile); }
  const child = spawn(binaries.postgres, ['-D', data, '-h', '127.0.0.1', '-p', String(port)], { windowsHide: true, stdio: ['ignore', 'ignore', 'pipe'] });
  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('PostgreSQL startup timed out')), 20_000);
    child.once('error', error => { clearTimeout(timer); reject(error); });
    child.once('exit', code => { clearTimeout(timer); reject(new Error('PostgreSQL exited: ' + code)); });
    child.stderr.on('data', chunk => {
      if (String(chunk).includes('database system is ready to accept connections')) { clearTimeout(timer); resolve(); }
    });
  });
  return {
    url: `postgresql://postgres:${password}@127.0.0.1:${port}/postgres`,
    stop: async () => {
      await execute(join(dirname(binaries.postgres), 'pg_ctl.exe'), ['-D', data, '-m', 'fast', '-w', 'stop'], { windowsHide: true });
    },
  };
}
