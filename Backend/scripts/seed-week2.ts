import { randomBytes, randomUUID } from 'node:crypto';
import { access, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { hash } from '@node-rs/argon2';
import sharp from 'sharp';
import { createApp } from '../src/app.js';
import { passwordOptions } from '../src/auth/auth.service.js';
import { loadConfig } from '../src/common/config.js';
import { createDatabase } from '../src/common/database.js';

// Development fixtures only. Never accepts a caller-provided DATABASE_URL.
const marker = 'WEEK2_FIXTURE_ONLY';
const definitions = [
  { phone: '+12025550111', role: 'citizen', name: 'Tuần 2 — Người dân A', permissions: [] },
  { phone: '+12025550112', role: 'citizen', name: 'Tuần 2 — Người dân B (dữ liệu mẫu)', permissions: [] },
  { phone: '+12025550113', role: 'rescue', name: 'Tuần 2 — Đội cứu hộ thử', permissions: [] },
  { phone: '+12025550114', role: 'admin', name: 'Tuần 2 — Quản trị thử', permissions: ['requests:read', 'requests:review'] },
];
type Credential = { phone: string; role: string; name: string; password: string; testOnly: true };

async function main() {
  if (process.env.NODE_ENV && process.env.NODE_ENV !== 'development') {
    throw new Error('Week 2 fixtures require NODE_ENV=development.');
  }
  const local = resolve('.local');
  const settings = JSON.parse(await readFile(resolve(local, 'dev-database.json'), 'utf8'));
  await access(resolve(local, 'postgres/PG_VERSION'));
  if (!Number.isInteger(settings.port) || settings.port < 1024 || settings.port > 65535 ||
      typeof settings.password !== 'string' || !/^[a-f0-9]{64}$/.test(settings.password)) {
    throw new Error('Invalid local demo settings. Start npm run demo in this Backend directory first.');
  }
  const db = createDatabase(`postgresql://postgres:${settings.password}@127.0.0.1:${settings.port}/postgres`);
  let app: Awaited<ReturnType<typeof createApp>> | undefined;
  try {
    const real = await db.pool.query('SELECT 1 FROM accounts WHERE is_test_account=false LIMIT 1');
    if (real.rowCount) throw new Error('Refusing to seed a database containing non-test accounts.');
    let saved: Credential[] = [];
    try { saved = JSON.parse(await readFile(resolve(local, 'week2-accounts.json'), 'utf8')); }
    catch (error) { if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error; }
    const credentials: Credential[] = [];
    const ids = new Map<string, string>();
    await db.transaction(async client => {
      for (const definition of definitions) {
        const existing = await client.query('SELECT id,is_test_account,display_name FROM accounts WHERE phone=$1 FOR UPDATE', [definition.phone]);
        if (existing.rowCount && (!existing.rows[0].is_test_account || existing.rows[0].display_name !== definition.name)) {
          throw new Error('Fixture phone already belongs to another account; no existing account was overwritten.');
        }
        const previous = saved.find(item => item.phone === definition.phone && item.role === definition.role);
        const password = previous?.password ?? randomBytes(20).toString('base64url');
        const id = existing.rows[0]?.id ?? randomUUID();
        await client.query(`INSERT INTO accounts(id,phone,display_name,password_hash,role,permissions,phone_verified_at,team_approved,is_test_account)
          VALUES($1,$2,$3,$4,$5,$6,clock_timestamp(),$7,true)
          ON CONFLICT(phone) DO UPDATE SET password_hash=EXCLUDED.password_hash`,
        [id, definition.phone, definition.name, await hash(password, passwordOptions), definition.role, definition.permissions, definition.role === 'rescue']);
        ids.set(definition.phone, id);
        credentials.push({ phone: definition.phone, role: definition.role, name: definition.name, password, testOnly: true });
      }
    });
    await writeFile(resolve(local, 'week2-accounts.json'), JSON.stringify(credentials, null, 2), { mode: 0o600 });
    app = await createApp(loadConfig({ NODE_ENV: 'development',
      DATABASE_URL: `postgresql://postgres:${settings.password}@127.0.0.1:${settings.port}/postgres`,
      MEDIA_DIRECTORY: resolve(local, 'media'),
    }), db);
    const api = async (method: 'POST' | 'GET', path: string, token: string | undefined, payload?: unknown) => {
      const response = await app!.inject({ method, url: '/api/v1' + path,
        headers: token ? { authorization: 'Bearer ' + token } : {}, payload: payload as any });
      if (response.statusCode >= 400) throw new Error('Fixture API step failed: ' + method + ' ' + path + ' (' + response.statusCode + ')');
      return response.json();
    };
    const login = async (phone: string) => {
      const credential = credentials.find(item => item.phone === phone)!;
      return (await api('POST', '/auth/login', undefined, { phone, password: credential.password })).token as string;
    };
    const citizenB = await login('+12025550112');
    const existing = await db.pool.query("SELECT id,data,stage FROM relief_requests WHERE owner_id=$1 AND stage IN ('waiting','accepted')", [ids.get('+12025550112')]);
    let requestId: string;
    if (existing.rowCount) {
      if (existing.rows[0].data.specialNotes !== marker) throw new Error('Citizen B has an unrelated open request; it was preserved.');
      requestId = existing.rows[0].id;
    } else {
      const now = new Date(Date.now() - 5 * 60_000).toISOString();
      const image = await sharp({ create: { width: 640, height: 480, channels: 3, background: '#176B64' } }).jpeg().toBuffer();
      const boundary = 'week2-' + randomUUID();
      const metadata = { operationId: randomUUID(), capturedAt: now, latitude: 10.77, longitude: 106.7 };
      const payload = Buffer.concat([
        Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n${JSON.stringify(metadata)}\r\n--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="fixture.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`),
        image, Buffer.from(`\r\n--${boundary}--\r\n`),
      ]);
      const uploaded = await app.inject({ method: 'POST', url: '/api/v1/evidence', payload,
        headers: { authorization: 'Bearer ' + citizenB, 'content-type': 'multipart/form-data; boundary=' + boundary } });
      if (uploaded.statusCode !== 201) throw new Error('Synthetic fixture image upload failed.');
      const created = await api('POST', '/requests', citizenB, { operationId: randomUUID(), data: {
        types: ['Sơ tán', 'Nước uống'], people: 4, elderly: 1, children: 1, disabled: 1, special: 1,
        specialNotes: marker, description: 'TUẦN 2 — Cần nước uống và sơ tán tại điểm thử.', urgency: 'Cao',
        address: 'ĐIỂM THỬ TUẦN 2 (dữ liệu giả)', landmark: '', latitude: 10.77, longitude: 106.7,
        locationSource: 'pin', locationConfirmedAt: now, clientActionAt: now, evidenceIds: [uploaded.json().id],
      } });
      requestId = created.requestId;
    }
    await db.transaction(async client => {
      const result = await client.query('SELECT stage,revision FROM relief_requests WHERE id=$1 FOR UPDATE', [requestId]);
      const active = await client.query('SELECT rescuer_id FROM assignments WHERE request_id=$1 AND ended_at IS NULL', [requestId]);
      if (active.rowCount) {
        if (active.rows[0].rescuer_id !== ids.get('+12025550113')) throw new Error('Fixture request belongs to a different team; assignment preserved.');
        return;
      }
      if (result.rows[0].stage !== 'waiting') throw new Error('Fixture request is not waiting; it was preserved.');
      await client.query('INSERT INTO assignments(id,request_id,rescuer_id) VALUES($1,$2,$3)', [randomUUID(), requestId, ids.get('+12025550113')]);
      const changed = await client.query("UPDATE relief_requests SET stage='accepted',revision=revision+1,updated_at=clock_timestamp() WHERE id=$1 RETURNING revision", [requestId]);
      await client.query(`INSERT INTO request_history(request_id,actor_id,action,revision,details) VALUES($1,$2,'fixture_assigned',$3,$4::jsonb)`,
        [requestId, ids.get('+12025550114'), changed.rows[0].revision, JSON.stringify({ fixtureOnly: true, reason: 'Week 2 manual test setup; not a real acceptance workflow.' })]);
    });
    const rescue = await login('+12025550113');
    const tasks = await api('GET', '/requests', rescue);
    if (!tasks.items.some((item: { id: string }) => item.id === requestId)) throw new Error('Fixture is missing from the rescue list.');
    const detail = await api('GET', '/requests/' + requestId, rescue);
    if (detail.stage !== 'accepted' || detail.evidence.length !== 1) throw new Error('Fixture detail is incomplete.');
    await writeFile(resolve(local, 'week2-fixtures.json'), JSON.stringify({ fixtureOnly: true,
      assignedRequestId: requestId, coordinates: { latitude: 10.77, longitude: 106.7 },
      description: 'TUẦN 2 — Cần nước uống và sơ tán tại điểm thử.',
      credentialFile: '.local/week2-accounts.json',
      note: 'Assignment is test setup only. No real accept/return/complete workflow was implemented.',
    }, null, 2));
    console.log('Week 2 fixtures ready. Credentials: .local/week2-accounts.json. Request: .local/week2-fixtures.json. No existing user requests were reset.');
  } finally { await app?.close(); await db.pool.end(); }
}

main().catch(error => { console.error(error instanceof Error ? error.message : 'Week 2 fixture setup failed'); process.exitCode = 1; });
