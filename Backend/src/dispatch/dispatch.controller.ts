import { randomUUID } from 'node:crypto';
import { Body, Controller, Get, Headers, Param, Post, Query } from '@nestjs/common';
import { z } from 'zod';
import { Actor, AuthService, requireAdmin, requireRole } from '../auth/auth.service.js';
import { Database } from '../common/database.js';
import { ApiError } from '../common/errors.js';
import { Operations } from '../common/operations.js';
import { reliefTypes, urgencyLevels } from '../requests/schemas.js';

const id = z.uuid();
const reason = z.string().trim().min(1).max(2000);
const command = z.discriminatedUnion('action', [
  z.object({action:z.literal('claim')}),
  z.object({action:z.literal('return'),reason}),
  z.object({action:z.literal('progress'),progress:z.enum(['travelling','arrived'])}),
  z.object({action:z.literal('assign'),teamId:id,reason}),
  z.object({action:z.literal('link'),primaryId:id,reason}),
]);
const mutation = z.object({operationId:id,revision:z.number().int().positive(),command});
const modes = z.enum(['mine','waiting','assigned','admin']);
const query = z.object({
  mode:modes,before:id.optional(),search:z.string().trim().max(160).optional(),
  status:z.enum(['waiting','accepted','travelling','arrived','completed','cancelled','invalid']).optional(),
  type:z.enum(reliefTypes).optional(),urgency:z.enum(urgencyLevels).optional(),
  lat:z.coerce.number().min(-90).max(90).optional(),lon:z.coerce.number().min(-180).max(180).optional(),
  km:z.coerce.number().positive().max(500).optional(),
}).refine(v=>v.km===undefined || (v.lat!==undefined && v.lon!==undefined));

const projection = `
 SELECT r.id,r.revision,r.stage,r.verification,r.primary_request_id,r.data,
   r.updated_at,r.created_at,r.latitude,r.longitude,owner.display_name owner_name,owner.phone,
   a.rescuer_id,t.display_name team_name,
   CASE WHEN coalesce(p.stage,r.stage)='accepted' THEN coalesce(a.progress,'accepted')
        WHEN coalesce(p.stage,r.stage)='waiting' AND coalesce(p.verification,r.verification)='invalid' THEN 'invalid'
        ELSE coalesce(p.stage,r.stage) END status
 FROM relief_requests r JOIN accounts owner ON owner.id=r.owner_id
 LEFT JOIN relief_requests p ON p.id=r.primary_request_id
 LEFT JOIN assignments a ON a.request_id=coalesce(p.id,r.id) AND a.ended_at IS NULL
 LEFT JOIN accounts t ON t.id=a.rescuer_id`;

export function dispatchController(db: Database, auth: AuthService, operations: Operations) {
  @Controller('api/v1/dispatch')
  class DispatchController {
    @Get()
    async list(@Headers('authorization') token:string,@Query() input:unknown) {
      const actor=await auth.authenticate(token), f=query.parse(input);
      if(f.mode==='mine') requireRole(actor,'citizen');
      else if(f.mode==='admin') requireAdmin(actor,'requests:read');
      else requireRole(actor,'rescue');
      const distance=`6371*2*asin(sqrt(least(1.0,power(sin(radians(r.latitude-$6::double precision)/2),2)
         +cos(radians($6::double precision))*cos(radians(r.latitude))*power(sin(radians(r.longitude-$7::double precision)/2),2))))`;
      const result=await db.pool.query(`
        WITH visible AS (${projection}, LATERAL (SELECT ${distance} AS km) d
         WHERE ($3::uuid IS NULL OR (r.created_at,r.id)<(SELECT created_at,id FROM relief_requests WHERE id=$3))
         AND CASE $1::text
          WHEN 'mine' THEN r.owner_id=$2
          WHEN 'waiting' THEN r.stage='waiting' AND r.verification='valid' AND r.primary_request_id IS NULL AND a.rescuer_id IS NULL
          WHEN 'assigned' THEN r.primary_request_id IS NULL AND a.rescuer_id=$2
          ELSE true END
         AND ($4::text IS NULL OR (r.data->'types') ? $4)
         AND ($5::text IS NULL OR r.data->>'urgency'=$5)
         AND ($8::double precision IS NULL OR d.km <= $8))
        SELECT visible.*,CASE WHEN $6::double precision IS NULL OR $7::double precision IS NULL
          THEN NULL ELSE ${distance.replaceAll('r.latitude','visible.latitude').replaceAll('r.longitude','visible.longitude')} END km
        FROM visible WHERE ($9::text IS NULL OR status=$9)
          AND ($10::text IS NULL OR strpos(lower(id::text),lower($10))>0 OR strpos(lower(coalesce(data->>'address','')),lower($10))>0)
        ORDER BY created_at DESC,id DESC LIMIT 31`,
        [f.mode,actor.id,f.before??null,f.type??null,f.urgency??null,f.lat??null,f.lon??null,f.km??null,f.status??null,f.search||null]);
      const rows=result.rows.slice(0,30);
      return {items:rows.map(r=>card(r,f.mode==='waiting')),nextCursor:result.rows.length>30?rows.at(-1).id:null};
    }

    @Get('teams')
    async teams(@Headers('authorization') token:string) {
      const actor=await auth.authenticate(token);
      requireAdmin(actor,'requests:read');
      requireAdmin(actor,'requests:review');
      const result=await db.pool.query(`SELECT id,display_name AS name FROM accounts WHERE role='rescue'
        AND team_approved AND locked_at IS NULL AND phone_verified_at IS NOT NULL ORDER BY display_name,id`);
      return {items:result.rows};
    }

    @Get(':id')
    async detail(@Headers('authorization') token:string,@Param('id') raw:string) {
      const actor=await auth.authenticate(token), requestId=id.parse(raw);
      if(actor.role==='admin') requireAdmin(actor,'requests:read');
      // Authorize and read sensitive fields from the same database snapshot.
      const result=await db.pool.query(`SELECT v.*,
        (SELECT coalesce(jsonb_agg(h ORDER BY h.id::bigint DESC),'[]') FROM (
          SELECT id::text,action,created_at AS at,
            CASE WHEN $3='admin' THEN details ELSE '{}'::jsonb END AS details
          FROM request_history WHERE (request_id=v.id OR request_id=v.primary_request_id)
          AND action LIKE 'dispatch.%' ORDER BY request_history.id DESC LIMIT 50
        ) h) AS events
        FROM (${projection} WHERE r.id=$1 AND (
          ($3='citizen' AND r.owner_id=$2) OR $3='admin' OR
          ($3='rescue' AND r.primary_request_id IS NULL AND a.rescuer_id=$2))) v`,
        [requestId,actor.id,actor.role]);
      const row=result.rows[0];
      if(!row) throw new ApiError(404,'REQUEST_NOT_FOUND','Không tìm thấy yêu cầu trong phạm vi truy cập.');
      return {...card(row,false),data:row.data,contact:{name:row.owner_name,phone:row.phone},
        location:{latitude:row.latitude,longitude:row.longitude},events:row.events};
    }

    @Post(':id/actions')
    async act(@Headers('authorization') token:string,@Param('id') raw:string,@Body() input:unknown) {
      const actor=await auth.authenticate(token), requestId=id.parse(raw), payload=mutation.parse(input);
      const cmd=payload.command;
      if(cmd.action==='assign'||cmd.action==='link') {
        requireAdmin(actor,'requests:read');
        requireAdmin(actor,'requests:review');
      } else requireRole(actor,'rescue');
      if(cmd.action==='link' && cmd.primaryId===requestId) throw new ApiError(422,'SELF_LINK','Chọn một yêu cầu chính khác.');
      return operations.run(actor,payload.operationId,'dispatch:'+requestId,payload,async sql=>{
        const ids=cmd.action==='link'?[requestId,cmd.primaryId]:[requestId];
        const locked=await sql.query('SELECT * FROM relief_requests WHERE id=ANY($1::uuid[]) ORDER BY id FOR UPDATE',[ids]);
        const row=locked.rows.find(r=>r.id===requestId);
        if(!row) throw new ApiError(404,'REQUEST_NOT_FOUND','Không tìm thấy yêu cầu.');
        const assignment=(await sql.query('SELECT * FROM assignments WHERE request_id=$1 AND ended_at IS NULL',[requestId])).rows[0];
        if(cmd.action==='claim' && assignment?.rescuer_id===actor.id) return {id:requestId,status:assignment.progress,teamName:actor.displayName};
        if(cmd.action==='claim' && assignment) throw new ApiError(409,'TASK_TAKEN','Nhiệm vụ vừa được đội khác tiếp nhận.');
        if(row.revision!==payload.revision) throw new ApiError(409,'STALE_TASK','Nhiệm vụ đã thay đổi. Hãy tải lại.');
        if(row.primary_request_id || !['waiting','accepted'].includes(row.stage) ||
            (row.verification!=='valid' && cmd.action!=='return')) {
          throw new ApiError(409,'TASK_UNAVAILABLE','Yêu cầu hiện không đủ điều kiện điều phối.');
        }
        let stage=row.stage, progress=assignment?.progress??'accepted', teamName:string|null=null;
        let event:string, details:Record<string,string>={};
        if(cmd.action==='link') {
          const primary=locked.rows.find(r=>r.id===cmd.primaryId);
          const children=await sql.query('SELECT 1 FROM relief_requests WHERE primary_request_id=$1 LIMIT 1',[requestId]);
          if(assignment || row.stage!=='waiting' || children.rowCount || !primary ||
              primary.primary_request_id || primary.verification!=='valid' || !['waiting','accepted'].includes(primary.stage)) {
            throw new ApiError(409,'LINK_UNAVAILABLE','Chỉ liên kết đơn đang chờ với đơn chính hợp lệ. Không tạo chuỗi liên kết.');
          }
          await sql.query('UPDATE relief_requests SET primary_request_id=$2 WHERE id=$1',[requestId,cmd.primaryId]);
          event='linked';details={primaryId:cmd.primaryId,reason:cmd.reason};
        } else if(cmd.action==='return'||cmd.action==='progress') {
          if(assignment?.rescuer_id!==actor.id) throw new ApiError(403,'NOT_ASSIGNED','Chỉ đội đang phụ trách được cập nhật.');
          teamName=actor.displayName;
          if(cmd.action==='return') {
            await sql.query('UPDATE assignments SET ended_at=clock_timestamp() WHERE id=$1',[assignment.id]);
            stage='waiting';event='returned';details={teamId:actor.id,teamName,reason:cmd.reason};
            teamName=null;
          } else {
            if((progress==='accepted'?'travelling':progress==='travelling'?'arrived':null)!==cmd.progress) {
              throw new ApiError(409,'INVALID_PROGRESS','Hãy cập nhật tiến độ theo đúng thứ tự.');
            }
            progress=cmd.progress;event=progress;
            await sql.query('UPDATE assignments SET progress=$2 WHERE id=$1',[assignment.id,progress]);
          }
        } else {
          const teamId=cmd.action==='claim'?actor.id:cmd.teamId;
          if(assignment?.rescuer_id===teamId) throw new ApiError(409,'ALREADY_ASSIGNED','Đội này đang phụ trách nhiệm vụ.');
          const team=(await sql.query(`SELECT display_name FROM accounts WHERE id=$1 AND role='rescue'
            AND team_approved AND locked_at IS NULL AND phone_verified_at IS NOT NULL FOR SHARE`,[teamId])).rows[0];
          if(!team) throw new ApiError(422,'TEAM_NOT_AVAILABLE','Đội đích chưa đủ điều kiện hoạt động.');
          if(assignment) await sql.query('UPDATE assignments SET ended_at=clock_timestamp() WHERE id=$1',[assignment.id]);
          await sql.query('INSERT INTO assignments(id,request_id,rescuer_id) VALUES($1,$2,$3)',[randomUUID(),requestId,teamId]);
          teamName=team.display_name;
          stage='accepted';progress='accepted';event=cmd.action==='claim'?'accepted':assignment?'transferred':'assigned';
          details={teamId,teamName:team.display_name,...(cmd.action==='assign'?{reason:cmd.reason}:{}),
            ...(assignment?{previousTeamId:assignment.rescuer_id}:{})};
        }
        const revision=(await sql.query(`UPDATE relief_requests SET stage=$2,revision=revision+1,
          updated_at=clock_timestamp() WHERE id=$1 RETURNING revision`,[requestId,stage])).rows[0].revision;
        await sql.query('INSERT INTO request_history(request_id,actor_id,action,revision,details) VALUES($1,$2,$3,$4,$5)',
          [requestId,actor.id,'dispatch.'+event,revision,details]);
        return {id:requestId,revision,status:stage==='accepted'?progress:stage,teamName};
      });
    }
  }
  return DispatchController;
}

function card(row:any,redacted:boolean) {
  const summary={id:row.id,revision:row.revision,status:row.status,verification:row.verification,
    people:row.data.people,types:row.data.types,urgency:row.data.urgency};
  if(redacted) return {...summary,distanceKm:row.km==null?null:Math.ceil(row.km)};
  return {...summary,region:row.data.address,teamName:row.team_name,linked:row.primary_request_id!=null,
    createdAt:row.created_at,updatedAt:row.updated_at};
}
