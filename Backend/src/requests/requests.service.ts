import { randomUUID } from 'node:crypto';
import { PoolClient } from 'pg';
import { z } from 'zod';
import { Actor, requireAdmin, requireRole } from '../auth/auth.service.js';
import { AppConfig } from '../common/config.js';
import { Database } from '../common/database.js';
import { ApiError } from '../common/errors.js';
import { Operations } from '../common/operations.js';
import { cancelSchema, reportSchema, RequestData, reviewSchema, submitSchema } from './schemas.js';

type Sql = Pick<PoolClient, 'query'>;
export class RequestsService {
  constructor(private readonly db: Database, private readonly operations: Operations, private readonly config: AppConfig) {}
  private async lockAccount(sql: Sql, actor: Actor) {
    const result = await sql.query('SELECT role,permissions,team_approved,phone_verified_at FROM accounts WHERE id=$1 AND locked_at IS NULL FOR SHARE', [actor.id]);
    const row = result.rows[0];
    if (!row || !row.phone_verified_at || row.role !== actor.role ||
      (actor.role === 'rescue' && !row.team_approved) ||
      actor.permissions.some(p => !row.permissions.includes(p))) {
      throw new ApiError(403, 'PERMISSIONS_CHANGED', 'Quyền tài khoản đã thay đổi. Hãy đăng nhập lại.');
    }
  }
  private async row(sql: Sql, id: string, lock = false) {
    z.string().uuid().parse(id);
    const result = await sql.query('SELECT * FROM relief_requests WHERE id=$1' + (lock ? ' FOR UPDATE' : ''), [id]);
    if (!result.rowCount) throw new ApiError(404, 'REQUEST_NOT_FOUND', 'Không tìm thấy yêu cầu.');
    return result.rows[0];
  }
  private owner(actor: Actor, row: any) {
    requireRole(actor, 'citizen');
    if (row.owner_id !== actor.id) throw new ApiError(404, 'REQUEST_NOT_FOUND', 'Không tìm thấy yêu cầu.');
  }
  private version(row: any, revision: number | null) {
    if (revision === null) throw new ApiError(428, 'VERSION_REQUIRED', 'Hãy tải phiên bản yêu cầu mới nhất trước khi thay đổi.');
    if (row.revision !== revision) throw new ApiError(409, 'VERSION_CONFLICT', 'Yêu cầu đã thay đổi. Hãy xem dữ liệu mới nhất trước khi gửi lại.');
  }
  private async requireWaiting(sql: Sql, row: any) {
    if (row.stage !== 'waiting') throw new ApiError(409, 'REQUEST_NOT_WAITING', 'Yêu cầu đã được tiếp nhận hoặc đã kết thúc.');
    const active = await sql.query('SELECT id FROM assignments WHERE request_id=$1 AND ended_at IS NULL', [row.id]);
    if (active.rowCount) throw new ApiError(409, 'REQUEST_ASSIGNED', 'Đã có đội đang phụ trách yêu cầu này.');
  }
  private async event(sql: Sql, row: any, actor: Actor, action: string, details: unknown = {}) {
    await sql.query('INSERT INTO request_history(request_id,actor_id,action,revision,details) VALUES($1,$2,$3,$4,$5::jsonb)',
      [row.id, actor.id, action, row.revision, JSON.stringify(details)]);
  }
  private receipt(row: any) {
    return { requestId: row.id, revision: row.revision, stage: row.stage, verification: row.verification,
      serverSavedAt: new Date(row.updated_at).toISOString(), receivedAt: new Date(row.received_at).toISOString() };
  }
  private async linkEvidence(sql: Sql, actor: Actor, id: string, data: RequestData) {
    if (data.evidenceIds.length > this.config.MAX_EVIDENCE_LINKS) {
      throw new ApiError(413, 'TOO_MANY_ATTACHMENTS', 'Số ảnh vượt giới hạn xử lý hiện tại. Bạn vẫn có thể gửi yêu cầu không có ảnh.');
    }
    if (data.evidenceIds.length) {
      const allowed = await sql.query(`SELECT id FROM evidence WHERE id=ANY($1::uuid[]) AND owner_id=$2
        AND (request_id IS NULL OR request_id=$3) FOR UPDATE`, [data.evidenceIds, actor.id, id]);
      if (allowed.rowCount !== data.evidenceIds.length) throw new ApiError(422, 'INVALID_EVIDENCE', 'Ảnh không tồn tại hoặc không thuộc yêu cầu của bạn.');
    }
    await sql.query('UPDATE evidence SET request_id=NULL WHERE request_id=$1 AND NOT(id=ANY($2::uuid[]))', [id, data.evidenceIds]);
    await sql.query('UPDATE evidence SET request_id=$1 WHERE id=ANY($2::uuid[]) AND owner_id=$3', [id, data.evidenceIds, actor.id]);
  }
  async create(actor: Actor, input: unknown) {
    requireRole(actor, 'citizen');
    const body = submitSchema.parse(input);
    try {
      return await this.operations.run(actor, body.operationId, 'request.create', body.data, async sql => {
        await this.lockAccount(sql, actor);
        const id = randomUUID();
        const result = await sql.query(`INSERT INTO relief_requests(id,owner_id,data,latitude,longitude,client_action_at)
          VALUES($1,$2,$3::jsonb,$4,$5,$6) RETURNING *`, [id, actor.id, JSON.stringify(body.data), body.data.latitude, body.data.longitude, body.data.clientActionAt]);
        const row = result.rows[0];
        await this.linkEvidence(sql, actor, id, body.data);
        await this.event(sql, row, actor, 'submitted');
        return this.receipt(row);
      });
    } catch (error) {
      if ((error as any)?.code === '23505' && (error as any)?.constraint === 'one_open_request_per_owner') {
        throw new ApiError(409, 'OPEN_REQUEST_EXISTS', 'Bạn đã có yêu cầu đang mở. Hãy sửa yêu cầu đó hoặc chờ kết thúc trước khi gửi mới.');
      }
      throw error;
    }
  }
  async update(actor: Actor, id: string, input: unknown, revision: number | null) {
    requireRole(actor, 'citizen');
    const body = submitSchema.parse(input);
    return this.operations.run(actor, body.operationId, `request.update:${id}`, { data: body.data, revision }, async sql => {
      await this.lockAccount(sql, actor);
      const prior = await this.row(sql, id, true);
      this.owner(actor, prior); this.version(prior, revision);
      await this.requireWaiting(sql, prior);
      const result = await sql.query(`UPDATE relief_requests SET data=$2::jsonb,latitude=$3,longitude=$4,client_action_at=$5,
        verification='pending',review_reason='',revision=revision+1,updated_at=clock_timestamp() WHERE id=$1 RETURNING *`,
      [id, JSON.stringify(body.data), body.data.latitude, body.data.longitude, body.data.clientActionAt]);
      const row = result.rows[0];
      await this.linkEvidence(sql, actor, id, body.data);
      const changedFields = Object.keys(body.data).filter(key => JSON.stringify((prior.data as any)[key]) !== JSON.stringify((body.data as any)[key]));
      await this.event(sql, row, actor, 'updated', { previousVerification: prior.verification, changedFields });
      return this.receipt(row);
    });
  }
  async cancel(actor: Actor, id: string, input: unknown, revision: number | null) {
    requireRole(actor, 'citizen');
    const body = cancelSchema.parse(input);
    return this.operations.run(actor, body.operationId, `request.cancel:${id}`, { confirmed: body.confirmed, revision }, async sql => {
      await this.lockAccount(sql, actor);
      const row = await this.row(sql, id, true);
      this.owner(actor, row); this.version(row, revision);
      await this.requireWaiting(sql, row);
      const result = await sql.query(`UPDATE relief_requests SET stage='cancelled',cancelled_at=clock_timestamp(),
        revision=revision+1,updated_at=clock_timestamp() WHERE id=$1 RETURNING *`, [id]);
      await this.event(sql, result.rows[0], actor, 'cancelled');
      return this.receipt(result.rows[0]);
    });
  }
  async attachEvidence(actor: Actor,id: string,input: unknown,revision: number|null) {
    requireRole(actor,'citizen');
    const body=z.object({operationId:z.string().uuid(),evidenceIds:z.array(z.string().uuid()).min(1)}).strict().parse(input);
    return this.operations.run(actor,body.operationId,`request.evidence:${id}`,{evidenceIds:body.evidenceIds,revision},async sql=>{
      const prior=await this.row(sql,id,true);this.owner(actor,prior);this.version(prior,revision);await this.requireWaiting(sql,prior);
      const data={...prior.data,evidenceIds:[...new Set([...prior.data.evidenceIds,...body.evidenceIds])]} as RequestData;
      await this.linkEvidence(sql,actor,id,data);
      const updated=await sql.query('UPDATE relief_requests SET data=$2::jsonb,revision=revision+1,updated_at=clock_timestamp() WHERE id=$1 RETURNING *',[id,JSON.stringify(data)]);
      await this.event(sql,updated.rows[0],actor,'evidence_attached',{evidenceIds:body.evidenceIds});
      return this.receipt(updated.rows[0]);
    });
  }
  async review(actor: Actor, id: string, input: unknown, revision: number | null) {
    requireAdmin(actor, 'requests:review');
    requireAdmin(actor, 'requests:read');
    const body = reviewSchema.parse(input);
    return this.operations.run(actor, body.operationId, `request.review:${id}`, { decision: body.decision, reason: body.reason, revision }, async sql => {
      await this.lockAccount(sql, actor);
      const prior = await this.row(sql, id, true); this.version(prior, revision);
      if (prior.stage === 'cancelled' || prior.stage === 'completed') throw new ApiError(409, 'REQUEST_CLOSED', 'Yêu cầu đã kết thúc, không thể đổi kết quả xác minh.');
      const result = await sql.query(`UPDATE relief_requests SET verification=$2,review_reason=$3,
        revision=revision+1,updated_at=clock_timestamp() WHERE id=$1 RETURNING *`, [id, body.decision, body.reason]);
      await this.event(sql, result.rows[0], actor, 'reviewed', { decision: body.decision, reason: body.reason });
      const label = { valid: 'hợp lệ', needs_info: 'cần bổ sung thông tin', invalid: 'không hợp lệ' }[body.decision];
      await sql.query('INSERT INTO notices(account_id,request_id,kind,message) VALUES($1,$2,$3,$4)',
        [prior.owner_id, id, 'review', `Yêu cầu của bạn được đánh dấu ${label}.${body.reason ? ' ' + body.reason : ''}`]);
      return this.receipt(result.rows[0]);
    });
  }
  async report(actor: Actor, id: string, input: unknown) {
    requireRole(actor, 'rescue');
    const body = reportSchema.parse(input);
    return this.operations.run(actor, body.operationId, `request.report:${id}`, { reason: body.reason }, async sql => {
      await this.lockAccount(sql, actor);
      const row = await this.row(sql, id, true);
      const reportId = randomUUID();
      await sql.query('INSERT INTO fraud_reports(id,request_id,reporter_id,reason) VALUES($1,$2,$3,$4)', [reportId, id, actor.id, body.reason]);
      const result = await sql.query('UPDATE relief_requests SET revision=revision+1,updated_at=clock_timestamp() WHERE id=$1 RETURNING *', [id]);
      await this.event(sql, result.rows[0], actor, 'reported');
      await sql.query('INSERT INTO notices(account_id,request_id,kind,message) VALUES($1,$2,$3,$4)',
        [row.owner_id, id, 'verification_needed', 'Yêu cầu có thông tin cần quản trị kiểm tra thêm. Đây chưa phải kết luận giả mạo.']);
      return { reportId, requestId: id, serverSavedAt: new Date(result.rows[0].updated_at).toISOString() };
    });
  }
  async canReadPrivate(actor: Actor, id: string, sql: Sql = this.db.pool) {
    const row = await this.row(sql, id);
    if (actor.role === 'citizen') { this.owner(actor, row); return row; }
    if (actor.role === 'admin') { requireAdmin(actor, 'requests:read'); return row; }
    const assigned = await sql.query('SELECT id FROM assignments WHERE request_id=$1 AND rescuer_id=$2 AND ended_at IS NULL', [id, actor.id]);
    if (!assigned.rowCount) throw new ApiError(404, 'REQUEST_NOT_FOUND', 'Không tìm thấy yêu cầu hoặc bạn chưa được phân công.');
    return row;
  }
  private summary(row: any) {
    return { id: row.id, stage: row.stage, verification: row.verification, revision: row.revision,
      types: row.data.types, people: row.data.people, urgency: row.data.urgency,
      createdAt: new Date(row.created_at).toISOString(), updatedAt: new Date(row.updated_at).toISOString() };
  }
  async get(actor: Actor, id: string) {
    const row = await this.canReadPrivate(actor, id);
    const [owner, photos, history, reports] = await Promise.all([
      this.db.pool.query('SELECT display_name,phone FROM accounts WHERE id=$1', [row.owner_id]),
      this.db.pool.query('SELECT id,byte_length,captured_at,latitude,longitude,received_at FROM evidence WHERE request_id=$1 ORDER BY received_at,id', [id]),
      this.db.pool.query('SELECT id,action,revision,details,created_at FROM request_history WHERE request_id=$1 ORDER BY id DESC LIMIT 21', [id]),
      actor.role === 'admin' ? this.db.pool.query('SELECT id,reason,created_at FROM fraud_reports WHERE request_id=$1 ORDER BY created_at DESC LIMIT 100', [id]) : Promise.resolve({ rows: [] }),
    ]);
    return { ...this.summary(row), data: row.data,
      contact: { name: owner.rows[0].display_name, phone: owner.rows[0].phone },
      reviewReason: row.review_reason, clientActionAt: new Date(row.client_action_at).toISOString(),
      receivedAt: new Date(row.received_at).toISOString(),
      clockDifferenceSeconds: Math.round((new Date(row.client_action_at).getTime() - new Date(row.received_at).getTime()) / 1000),
      evidence: photos.rows.map(p => ({ id: p.id, byteLength: p.byte_length, capturedAt: new Date(p.captured_at).toISOString(),
        latitude: p.latitude, longitude: p.longitude, receivedAt: new Date(p.received_at).toISOString() })),
      history: history.rows.slice(0,20).map(h => ({ id: String(h.id), action: h.action, revision: h.revision, details: h.details, at: new Date(h.created_at).toISOString() })),
      historyNextCursor: history.rows.length>20 ? String(history.rows[19].id) : null,
      reports: reports.rows.map(r => ({ id: r.id, reason: r.reason, at: new Date(r.created_at).toISOString() })),
    };
  }
  async history(actor: Actor, id: string, before?: string) {
    await this.canReadPrivate(actor,id);
    const cursor=before ? z.string().regex(/^\d{1,18}$/).parse(before) : null;
    const result=await this.db.pool.query('SELECT id,action,revision,details,created_at FROM request_history WHERE request_id=$1 AND ($2::bigint IS NULL OR id<$2) ORDER BY id DESC LIMIT 21',[id,cursor]);
    const rows=result.rows.slice(0,20);
    return {items:rows.map(h=>({id:String(h.id),action:h.action,revision:h.revision,details:h.details,at:new Date(h.created_at).toISOString()})),
      nextCursor:result.rows.length>20?String(rows.at(-1).id):null};
  }
  async list(actor: Actor, before?: string) {
    if (actor.role === 'admin') requireAdmin(actor, 'requests:read');
    const cursor = before ? z.string().uuid().parse(before) : null;
    const result = await this.db.pool.query(`SELECT r.*,a.display_name,a.phone FROM relief_requests r JOIN accounts a ON a.id=r.owner_id WHERE
      ($1='admin' OR ($1='citizen' AND r.owner_id=$2) OR ($1='rescue' AND EXISTS
        (SELECT 1 FROM assignments a WHERE a.request_id=r.id AND a.rescuer_id=$2 AND a.ended_at IS NULL)))
      AND ($3::uuid IS NULL OR (r.created_at,r.id)<(SELECT created_at,id FROM relief_requests WHERE id=$3))
      ORDER BY r.created_at DESC,r.id DESC LIMIT 31`, [actor.role, actor.id, cursor]);
    const rows = result.rows.slice(0, 30);
    return { items: rows.map(r => ({ ...this.summary(r), address: r.data.address,
      ...(actor.role === 'admin' ? { contact: { name: r.display_name, phone: r.phone } } : {}) })),
      nextCursor: result.rows.length > 30 ? rows.at(-1).id : null };
  }
  async similar(actor: Actor, id: string) {
    requireAdmin(actor, 'requests:review');
    requireAdmin(actor, 'requests:read');
    const request = await this.row(this.db.pool, id);
    const words = (s: string) => new Set(s.normalize('NFC').toLocaleLowerCase('vi').match(/[\p{L}\p{N}]+/gu) ?? []);
    const query = [...words(request.data.description)].slice(0,64).map(w => `'${w}'`).join(' | ');
    const result = await this.db.pool.query(`WITH spatial AS (SELECT id,data,latitude,longitude FROM relief_requests
      WHERE id<>$1 AND stage IN ('waiting','accepted') ORDER BY
      ((latitude-$2)*(latitude-$2)+(longitude-$3)*(longitude-$3)),id LIMIT 30),
      textual AS (SELECT id,data,latitude,longitude FROM relief_requests WHERE id<>$1 AND stage IN ('waiting','accepted')
        AND search_document@@to_tsquery('simple',$4) ORDER BY ts_rank(search_document,to_tsquery('simple',$4)) DESC,id LIMIT 30)
      SELECT * FROM spatial UNION SELECT * FROM textual`, [id, request.latitude, request.longitude, query || "'empty'"]);
    const source = words(request.data.description);
    return { criteria: 'ranked_candidates_not_a_fraud_decision', items: result.rows.map(row => {
      const target = words(row.data.description);
      const common = [...source].filter(w => target.has(w)).length;
      const union = new Set([...source, ...target]).size;
      const rad = Math.PI / 180;
      const a = Math.sin((row.latitude-request.latitude)*rad/2)**2 + Math.cos(request.latitude*rad)*Math.cos(row.latitude*rad)*Math.sin((row.longitude-request.longitude)*rad/2)**2;
      return { id: row.id, description: row.data.description,
        sameCoordinates: row.latitude === request.latitude && row.longitude === request.longitude,
        sharedWords: common, contentSimilarity: union ? common/union : 0,
        distanceMetres: Math.round(6371000*2*Math.asin(Math.sqrt(Math.min(1,Math.max(0,a))))),
      };
    }).sort((a,b) => Number(b.sameCoordinates)-Number(a.sameCoordinates) || b.contentSimilarity-a.contentSimilarity || a.distanceMetres-b.distanceMetres).slice(0,10) };
  }
  async notices(actor: Actor, before?: string) {
    const cursor = before ? z.string().regex(/^\d{1,18}$/).parse(before) : null;
    const result = await this.db.pool.query('SELECT id,request_id,kind,message,created_at,read_at FROM notices WHERE account_id=$1 AND ($2::bigint IS NULL OR id<$2) ORDER BY id DESC LIMIT 31', [actor.id, cursor]);
    const rows = result.rows.slice(0,30);
    return { items: rows.map(n => ({ id: String(n.id), requestId: n.request_id, kind: n.kind, message: n.message,
      createdAt: new Date(n.created_at).toISOString(), read: !!n.read_at })), nextCursor: result.rows.length>30 ? String(rows.at(-1).id) : null };
  }
  async readNotice(actor: Actor, id: string) {
    z.string().regex(/^\d{1,18}$/).parse(id);
    const result = await this.db.pool.query('UPDATE notices SET read_at=COALESCE(read_at,clock_timestamp()) WHERE id=$1 AND account_id=$2 RETURNING id', [id, actor.id]);
    if (!result.rowCount) throw new ApiError(404, 'NOTICE_NOT_FOUND', 'Không tìm thấy thông báo.');
    return { id, read: true };
  }
}
