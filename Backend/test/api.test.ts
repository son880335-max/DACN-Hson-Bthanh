import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdtemp } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { hash } from '@node-rs/argon2';
import sharp from 'sharp';
import { createApp } from '../src/app.js';
import { loadConfig } from '../src/common/config.js';
import { createDatabase, Database } from '../src/common/database.js';
import { passwordOptions, AuthService } from '../src/auth/auth.service.js';
import { startTestPostgres } from './postgres.js';

let app: Awaited<ReturnType<typeof createApp>>, db: Database;
let postgres: Awaited<ReturnType<typeof startTestPostgres>>;
let citizen: string, other: string, admin: string, rescue: string, limited: string;
const ids: Record<string, string> = {};
const password = randomBytes(24).toString('base64url');
let config: ReturnType<typeof loadConfig>;
const data = () => ({ types: ['Sơ tán', 'Nước uống'], people: 4, elderly: 1, children: 1, disabled: 0,
  special: 0, specialNotes: '', description: 'Gia đình mắc kẹt, cần nước uống và sơ tán.', urgency: 'Cao',
  address: 'Địa điểm kiểm thử', landmark: '', latitude: 0, longitude: 0, locationSource: 'pin',
  locationConfirmedAt: new Date().toISOString(), clientActionAt: new Date().toISOString(), evidenceIds: [] as string[] });
const send = (method: string, url: string, token?: string, payload?: unknown, revision?: number) => app.inject({
  method: method as any, url: '/api/v1' + url, payload: payload as any,
  headers: { ...(token ? { authorization: 'Bearer ' + token } : {}), ...(revision ? { 'if-match': `"${revision}"` } : {}) },
});
async function account(name: string, phone: string, role = 'citizen', permissions: string[] = []) {
  const id = randomUUID(); ids[name] = id;
  await db.pool.query(`INSERT INTO accounts(id,phone,display_name,password_hash,role,permissions,phone_verified_at,team_approved,is_test_account)
    VALUES($1,$2,$3,$4,$5,$6,now(),$7,true)`, [id, phone, name, await hash(password, passwordOptions), role, permissions, role === 'rescue']);
  const result = await send('POST', '/auth/login', undefined, { phone, password });
  assert.equal(result.statusCode, 201, result.body);
  return result.json().token as string;
}
async function create(token = citizen, override: Record<string, unknown> = {}) {
  return send('POST', '/requests', token, { operationId: randomUUID(), data: { ...data(), ...override } });
}
async function clear() {
  await db.pool.query('TRUNCATE operation_receipts,notices,fraud_reports,request_history,evidence,assignments,relief_requests RESTART IDENTITY CASCADE');
}
before(async () => {
  postgres = await startTestPostgres();
  db = createDatabase(postgres.url);
  await db.migrate();
  config = loadConfig({ NODE_ENV: 'test', DATABASE_URL: postgres.url, LOGIN_ATTEMPTS_PER_MINUTE: '1000',
    MEDIA_DIRECTORY: await mkdtemp(join(tmpdir(), 'dacn-media-test-')) });
  app = await createApp(config, db);
  citizen = await account('citizen', '+12025550101');
  other = await account('other', '+12025550102');
  admin = await account('admin', '+12025550103', 'admin', ['requests:read', 'requests:review']);
  rescue = await account('rescue', '+12025550104', 'rescue');
  limited = await account('limited', '+12025550105', 'admin');
});
after(async () => { await app?.close(); await db?.pool.end(); await postgres?.stop(); });

test('authentication is real; registration never simulates phone verification', async () => {
  assert.equal((await send('GET', '/requests')).statusCode, 401);
  assert.equal((await send('POST', '/auth/login', undefined, { phone: '+12025550101', password: 'wrong' })).statusCode, 401);
  assert.equal((await send('POST', '/auth/register', undefined, {})).json().code, 'SMS_PROVIDER_NOT_CONFIGURED');
  const prod = new AuthService(db, { ...config, NODE_ENV: 'production' });
  await assert.rejects(() => prod.login({ phone: '+12025550101', password }), { status: 401 });
  await db.pool.query('UPDATE accounts SET locked_at=now() WHERE id=$1', [ids.other]);
  assert.equal((await send('GET', '/auth/me', other)).statusCode, 401);
  await db.pool.query('UPDATE accounts SET locked_at=NULL WHERE id=$1', [ids.other]);
  assert.equal((await send('GET', '/requests', limited)).statusCode, 403);
});

test('validates confirmed coordinates and fields; optional photo; owner data stays private', async () => {
  await clear();
  assert.equal((await create(citizen, { people: 0 })).statusCode, 422);
  assert.equal((await create(citizen, { locationConfirmedAt: '' })).statusCode, 422);
  assert.equal((await create(citizen, { latitude: 91 })).statusCode, 422);
  assert.equal((await create(citizen, { urgency: 'Trung' })).statusCode, 422);
  assert.equal((await create(citizen, { ownerId: ids.other })).statusCode, 422);
  const response = await create(); assert.equal(response.statusCode, 201, response.body);
  const id = response.json().requestId;
  const item = await send('GET', '/requests/' + id, citizen);
  assert.equal(item.statusCode, 200); assert.equal(item.json().data.latitude, 0);
  assert.equal(item.json().contact.phone, '+12025550101');
  assert.deepEqual(item.json().evidence, []);
  assert.equal((await send('GET', '/requests/' + id, other)).statusCode, 404);
  assert.equal((await send('GET', '/requests/' + id, rescue)).statusCode, 404);
  assert.equal((await send('GET', '/requests/' + id, admin)).statusCode, 200);
});

test('parallel retries and competing new operations commit exactly one open request', async () => {
  await clear();
  const body = { operationId: randomUUID(), data: data() };
  const responses = await Promise.all(Array.from({ length: 6 }, () => send('POST', '/requests', citizen, body)));
  for (const response of responses) assert.equal(response.statusCode, 201, response.body);
  assert.equal(new Set(responses.map(r => r.json().requestId)).size, 1);
  assert.equal((await db.pool.query('SELECT count(*)::int n FROM request_history')).rows[0].n, 1);
  assert.equal((await send('POST', '/requests', citizen, { ...body, data: { ...body.data, people: 5 } })).statusCode, 409);
  assert.equal((await create()).json().code, 'OPEN_REQUEST_EXISTS');
});

test('Sprint 2 rejects missing and invalid request fields with useful Vietnamese messages', async () => {
  await clear();
  const invalid: Record<string, unknown>[] = [
    { types: [] }, { types: ['Không có trong danh mục'] }, { types: ['Sơ tán', 'Sơ tán'] },
    { people: undefined }, { people: 0 }, { people: -1 }, { people: 1.5 },
    ...['elderly', 'children', 'disabled', 'special'].flatMap(key => [{ [key]: -1 }, { [key]: 5 }]),
    { description: ' ' }, { urgency: 'Trung' }, { address: '', landmark: '' },
    { latitude: 91 }, { longitude: 181 }, { locationConfirmedAt: undefined },
    { clientActionAt: 'invalid' }, { locationSource: 'unknown' },
  ];
  for (const override of invalid) {
    const response = await create(citizen, override);
    assert.equal(response.statusCode, 422, response.body);
    const body = response.json();
    assert.equal(body.code, 'VALIDATION_FAILED');
    assert.ok(body.fields.length > 0);
    for (const field of body.fields) {
      assert.match(field.message, /[\u00c0-\u1ef9]/, 'Validation must explain the problem in Vietnamese');
      assert.doesNotMatch(field.message, /Invalid input|expected|undefined|ZodError/i);
    }
  }
  assert.equal((await db.pool.query('SELECT count(*)::int n FROM relief_requests')).rows[0].n, 0);
  for (const override of [{}, { address: '', landmark: 'Cổng màu xanh' },
    { elderly: 4, children: 4, disabled: 4, special: 4 }, { latitude: 0, longitude: 0 }]) {
    await clear();
    assert.equal((await create(citizen, override)).statusCode, 201);
  }
});

test('edit uses version; cancellation needs explicit confirmation and server receipt before reopening', async () => {
  await clear(); const id = (await create()).json().requestId;
  const update = { operationId: randomUUID(), data: { ...data(), longitude: 106, address: 'Đã sửa địa chỉ' } };
  assert.equal((await send('PUT', '/requests/' + id, citizen, update)).statusCode, 428);
  assert.equal((await send('PUT', '/requests/' + id, citizen, update, 1)).json().revision, 2);
  assert.equal((await send('PUT', '/requests/' + id, citizen, { ...update, operationId: randomUUID() }, 1)).statusCode, 409);
  assert.equal((await send('GET', '/requests/' + id, citizen)).json().data.longitude, 106);
  assert.equal((await send('POST', '/requests/' + id + '/cancel', citizen, { operationId: randomUUID(), confirmed: false }, 2)).statusCode, 422);
  const operation = { operationId: randomUUID(), confirmed: true };
  const cancelled = await send('POST', '/requests/' + id + '/cancel', citizen, operation, 2);
  assert.equal(cancelled.json().stage, 'cancelled', cancelled.body);
  assert.deepEqual((await send('POST', '/requests/' + id + '/cancel', citizen, operation, 2)).json(), cancelled.json());
  assert.equal((await create()).statusCode, 201);
  assert.equal((await send('GET', '/requests/' + id, citizen)).json().history[0].action, 'cancelled');
});

test('verification and reports are authorized, audited and notify without automatically cancelling', async () => {
  await clear(); const id = (await create()).json().requestId;
  const path = '/requests/' + id;
  const review = { operationId: randomUUID(), decision: 'needs_info', reason: 'Vui lòng bổ sung hướng dẫn vị trí' };
  assert.equal((await send('POST', path + '/reviews', citizen, review, 1)).statusCode, 403);
  assert.equal((await send('POST', path + '/reviews', limited, review, 1)).statusCode, 403);
  assert.equal((await send('POST', path + '/reviews', admin, { ...review, reason: '' }, 1)).statusCode, 422);
  assert.equal((await send('POST', path + '/reviews', admin, review, 1)).json().verification, 'needs_info');
  assert.equal((await send('GET', '/notices', citizen)).json().items.length, 1);
  assert.equal((await send('GET', '/notices', other)).json().items.length, 0);
  const report = { operationId: randomUUID(), reason: 'Địa điểm cần kiểm tra lại' };
  assert.equal((await send('POST', path + '/reports', citizen, report)).statusCode, 403);
  assert.equal((await send('POST', path + '/reports', rescue, report)).statusCode, 201);
  assert.equal((await send('POST', path + '/reviews', admin, { ...review, operationId: randomUUID(), decision: 'invalid', reason: 'Thông tin chưa khớp' }, 3)).json().stage, 'waiting');
  assert.equal((await create()).json().code, 'OPEN_REQUEST_EXISTS');
  const detail = (await send('GET', path, admin)).json();
  assert.equal(detail.reports.length, 1); assert.equal(typeof detail.clockDifferenceSeconds, 'number');
  assert.equal((await send('GET', path + '/similar', citizen)).statusCode, 403);
  await assert.rejects(() => db.pool.query("UPDATE request_history SET action='edited'"), /append.only/);
});

test('cancellation and assignment cannot both succeed; accepted request cannot be cancelled or edited', async () => {
  await clear(); const id = (await create()).json().requestId;
  const client = await db.pool.connect();
  await client.query('BEGIN');
  await client.query('SELECT id FROM relief_requests WHERE id=$1 FOR UPDATE', [id]);
  const cancellation = send('POST', '/requests/' + id + '/cancel', citizen, { operationId: randomUUID(), confirmed: true }, 1);
  await client.query('INSERT INTO assignments(id,request_id,rescuer_id) VALUES($1,$2,$3)', [randomUUID(), id, ids.rescue]);
  await client.query("UPDATE relief_requests SET stage='accepted',revision=revision+1 WHERE id=$1", [id]);
  await client.query('COMMIT'); client.release();
  assert.equal((await cancellation).statusCode, 409);
  assert.equal((await send('GET', '/requests/' + id, rescue)).statusCode, 200);
  assert.equal((await send('PUT', '/requests/' + id, citizen, { operationId: randomUUID(), data: data() }, 2)).statusCode, 409);
  const impossible = await db.pool.connect();
  try {
    await impossible.query('BEGIN');
    await impossible.query("UPDATE relief_requests SET stage='cancelled',cancelled_at=now() WHERE id=$1", [id]);
    await assert.rejects(() => impossible.query('COMMIT'), /consistently/);
  } finally { await impossible.query('ROLLBACK'); impossible.release(); }
});

function multipartImage(bytes: Buffer, metadata: unknown) {
  const boundary = 'test-' + randomUUID();
  return { boundary, payload: Buffer.concat([Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n${JSON.stringify(metadata)}\r\n--${boundary}\r\nContent-Disposition: form-data; name="image"; filename="camera.jpg"\r\nContent-Type: image/jpeg\r\n\r\n`), bytes, Buffer.from(`\r\n--${boundary}--\r\n`)]) };
}
test('real image decode, watermark, thumbnail, idempotent upload and private authenticated download', async () => {
  await clear();
  const bytes = await sharp({ create: { width: 640, height: 480, channels: 3, background: '#aabbcc' } }).jpeg().toBuffer();
  const meta = { operationId: randomUUID(), capturedAt: new Date().toISOString(), latitude: 0, longitude: 0 };
  const postImage = async (image: Buffer, metadata = meta) => {
    const part = multipartImage(image, metadata);
    return app.inject({ method: 'POST', url: '/api/v1/evidence', headers: { authorization: 'Bearer ' + citizen, 'content-type': 'multipart/form-data; boundary=' + part.boundary }, payload: part.payload });
  };
  assert.equal((await postImage(Buffer.from('not a real image'))).statusCode, 422);
  const uploaded = await postImage(bytes); assert.equal(uploaded.statusCode, 201, uploaded.body);
  const imageId = uploaded.json().id;
  assert.equal((await postImage(bytes)).json().id, imageId);
  const id = (await create(citizen, { evidenceIds: [imageId] })).json().requestId;
  const downloaded = await send('GET', '/evidence/' + imageId, citizen);
  assert.equal(downloaded.statusCode, 200);
  assert.equal((await sharp(downloaded.rawPayload).metadata()).height, 544);
  const thumb = await send('GET', '/evidence/' + imageId + '?thumbnail=1', admin);
  assert.equal((await sharp(thumb.rawPayload).metadata()).width, 320);
  assert.equal((await send('GET', '/evidence/' + imageId, other)).statusCode, 404);
  assert.equal((await send('GET', '/evidence/' + imageId)).statusCode, 401);
  const cached = await app.inject({ method: 'GET', url: '/api/v1/evidence/' + imageId, headers: { authorization: 'Bearer ' + citizen, 'if-none-match': String(downloaded.headers.etag) } });
  assert.equal(cached.statusCode, 304);
  assert.equal((await send('GET', '/requests/' + id, admin)).json().evidence.length, 1);
  const bad = await create(other, { evidenceIds: [imageId] }); assert.equal(bad.json().code, 'INVALID_EVIDENCE');
  assert.equal((await db.pool.query('SELECT count(*)::int n FROM relief_requests WHERE owner_id=$1', [ids.other])).rows[0].n, 0);
  await send('POST','/requests/'+id+'/cancel',citizen,{operationId:randomUUID(),confirmed:true},1);
  const main=(await create()).json();
  const newImage=await postImage(bytes,{...meta,operationId:randomUUID()});
  assert.equal(newImage.statusCode,201,newImage.body);
  const append={operationId:randomUUID(),evidenceIds:[newImage.json().id]};
  const linked=await send('PUT','/requests/'+main.requestId+'/evidence',citizen,append,1);
  assert.equal(linked.json().revision,2,linked.body);
  assert.deepEqual((await send('PUT','/requests/'+main.requestId+'/evidence',citizen,append,1)).json(),linked.json());
  assert.equal((await send('PUT','/requests/'+main.requestId+'/evidence',citizen,{...append,operationId:randomUUID()},1)).statusCode,409);
});

test('similarity includes distant matching text as well as nearby candidates; history is authorized and paginated',async()=>{
  await clear();
  const source=(await create()).json().requestId;
  const distant=(await create(other,{latitude:50,longitude:60})).json().requestId;
  const people=await db.pool.query(`INSERT INTO accounts(id,phone,display_name,password_hash,role,phone_verified_at,is_test_account)
    SELECT gen_random_uuid(),'+1202555'||lpad((200+n)::text,4,'0'),'Fixture',a.password_hash,'citizen',now(),true
    FROM generate_series(1,32)n CROSS JOIN (SELECT password_hash FROM accounts WHERE id=$1)a RETURNING id`,[ids.citizen]);
  for(let i=0;i<people.rows.length;i++){
    const values={...data(),description:'Nội dung khác biệt',latitude:0.001*(i+1),longitude:0};
    await db.pool.query('INSERT INTO relief_requests(id,owner_id,data,latitude,longitude,client_action_at) VALUES($1,$2,$3::jsonb,$4,$5,$6)',
      [randomUUID(),people.rows[i].id,JSON.stringify(values),values.latitude,0,values.clientActionAt]);
  }
  const result=await send('GET','/requests/'+source+'/similar',admin);
  assert.equal(result.statusCode,200,result.body);
  assert.equal(result.json().items.some((item:any)=>item.id===distant),true);
  assert.equal((await send('GET','/requests/'+source+'/similar',limited)).statusCode,403);
  for(let i=0;i<24;i++)await db.pool.query("INSERT INTO request_history(request_id,actor_id,action,revision,details) VALUES($1,$2,'fixture',1,'{}')",[source,ids.citizen]);
  const page=await send('GET','/requests/'+source+'/history',citizen);
  assert.equal(page.json().items.length,20);
  const tail=await send('GET','/requests/'+source+'/history?before='+page.json().nextCursor,citizen);
  assert.equal(tail.json().items.length,5);
  assert.equal((await send('GET','/requests/'+source+'/history',other)).statusCode,404);
});

test('login throttling, expired sessions and unverified accounts fail safely',async()=>{
  const throttled=await createApp({...config,LOGIN_ATTEMPTS_PER_MINUTE:2},db);
  try{
    for(let i=0;i<2;i++)assert.equal((await throttled.inject({method:'POST',url:'/api/v1/auth/login',payload:{phone:'+12025550101',password:'wrong'}})).statusCode,401);
    const blocked=await throttled.inject({method:'POST',url:'/api/v1/auth/login',payload:{phone:'+12025550101',password}});
    assert.equal(blocked.statusCode,429);assert.ok(blocked.headers['retry-after']);
  }finally{await throttled.close();}
  await db.pool.query('UPDATE accounts SET phone_verified_at=NULL WHERE id=$1',[ids.other]);
  assert.equal((await send('POST','/auth/login',undefined,{phone:'+12025550102',password})).statusCode,403);
  await db.pool.query('UPDATE accounts SET phone_verified_at=now() WHERE id=$1',[ids.other]);
  await db.pool.query('UPDATE sessions SET expires_at=now()-interval \'1 minute\' WHERE account_id=$1',[ids.other]);
  assert.equal((await send('GET','/auth/me',other)).statusCode,401);
});

test('committed operations survive app restart and migrations can be run twice', async () => {
  await clear(); const body = { operationId: randomUUID(), data: data() };
  const first = (await send('POST', '/requests', citizen, body)).json();
  await app.close(); await db.migrate(); app = await createApp(config, db);
  assert.deepEqual((await send('POST', '/requests', citizen, body)).json(), first);
});
