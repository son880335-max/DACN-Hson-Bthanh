import { createHash, randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { z } from 'zod';
import { Actor, requireRole } from '../auth/auth.service.js';
import { AppConfig } from '../common/config.js';
import { Database } from '../common/database.js';
import { ApiError } from '../common/errors.js';
import { Operations } from '../common/operations.js';
import { RequestsService } from '../requests/requests.service.js';
import { ObjectStorage } from './storage.js';

const metadataSchema = z.object({ operationId: z.string().uuid(), capturedAt: z.string().datetime({ offset: true }),
  latitude: z.number().finite().min(-90).max(90).nullable().default(null),
  longitude: z.number().finite().min(-180).max(180).nullable().default(null),
}).strict().refine(v => (v.latitude === null) === (v.longitude === null), 'GPS ảnh cần đủ hai tọa độ hoặc để trống.');
sharp.cache({ memory: 32, files: 0, items: 20 });
sharp.concurrency(2);

export class EvidenceService {
  constructor(private readonly db: Database, private readonly operations: Operations,
    private readonly requests: RequestsService, private readonly storage: ObjectStorage, private readonly config: AppConfig) {}
  async upload(actor: Actor, bytes: Buffer, metadata: unknown) {
    requireRole(actor, 'citizen');
    const data = metadataSchema.parse(metadata);
    if (!bytes.length || bytes.length > this.config.MAX_IMAGE_BYTES) {
      throw new ApiError(413, 'IMAGE_TOO_LARGE', 'Ảnh vượt giới hạn xử lý. Bạn có thể gửi yêu cầu không có ảnh.');
    }
    const inputHash = createHash('sha256').update(bytes).digest('hex');
    return this.operations.run(actor, data.operationId, 'evidence.upload', { inputHash, metadata: data }, async sql => {
      let image: Buffer, thumbnail: Buffer;
      try {
        const original = sharp(bytes, { limitInputPixels: this.config.MAX_IMAGE_PIXELS, failOn: 'error' });
        const info = await original.metadata();
        if (!['jpeg', 'png', 'webp'].includes(info.format ?? '') || (info.pages ?? 1) > 1) throw new Error('Unsupported image');
        const resized = await original.rotate().resize({ width: 1280, height: 1280, fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 78 }).toBuffer({ resolveWithObject: true });
        const date = new Date(data.capturedAt).toISOString();
        const coordinates = data.latitude === null ? 'Coordinates unavailable' : `Reference ${data.latitude.toFixed(6)}, ${data.longitude!.toFixed(6)}`;
        const width = resized.info.width;
        const footer = Buffer.from(`<svg width="${width}" height="64"><rect width="100%" height="100%" fill="#083c43"/>
          <text x="8" y="24" font-family="sans-serif" font-size="14" fill="white">Device UTC ${date}</text>
          <text x="8" y="48" font-family="sans-serif" font-size="14" fill="white">${coordinates}</text></svg>`);
        image = await sharp(resized.data).extend({ bottom: 64, background: '#083c43' }).composite([{ input: footer, gravity: 'south' }])
          .jpeg({ quality: 78 }).toBuffer();
        thumbnail = await sharp(image).resize({ width: 320, withoutEnlargement: true }).jpeg({ quality: 70 }).toBuffer();
      } catch {
        throw new ApiError(422, 'INVALID_IMAGE', 'Không đọc được ảnh hoặc ảnh vượt giới hạn xử lý. Hãy chụp lại hoặc tiếp tục không có ảnh.');
      }
      const id = randomUUID();
      const key = id + '.jpg';
      await this.storage.put(key, image);
      await this.storage.put(id + '.thumb.jpg', thumbnail);
      await sql.query(`INSERT INTO evidence(id,owner_id,storage_key,sha256,byte_length,captured_at,latitude,longitude,thumbnail_sha256)
        VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)`, [id, actor.id, key, createHash('sha256').update(image).digest('hex'),
        image.length, data.capturedAt, data.latitude, data.longitude,createHash('sha256').update(thumbnail).digest('hex')]);
      return { id, byteLength: image.length, capturedAt: data.capturedAt, latitude: data.latitude, longitude: data.longitude };
    });
  }
  async read(actor: Actor, id: string, thumbnail: boolean, ifNoneMatch?: string) {
    z.string().uuid().parse(id);
    const result = await this.db.pool.query('SELECT id,owner_id,request_id,storage_key,sha256,thumbnail_sha256 FROM evidence WHERE id=$1', [id]);
    const row = result.rows[0];
    if (!row) throw new ApiError(404, 'EVIDENCE_NOT_FOUND', 'Không tìm thấy ảnh.');
    if (row.owner_id !== actor.id) {
      if (!row.request_id) throw new ApiError(404, 'EVIDENCE_NOT_FOUND', 'Không tìm thấy ảnh.');
      await this.requests.canReadPrivate(actor, row.request_id);
    }
    const expected=thumbnail?row.thumbnail_sha256:row.sha256;
    const etag=expected?'"'+expected+'"':null;
    if(etag&&ifNoneMatch===etag)return {etag,notModified:true,bytes:undefined};
    const bytes = await this.storage.get(thumbnail ? id + '.thumb.jpg' : row.storage_key);
    const actual=createHash('sha256').update(bytes).digest('hex');
    if(expected&&actual!==expected)throw new ApiError(500,'IMAGE_INTEGRITY_ERROR','Ảnh đang cần được kiểm tra lại. Yêu cầu cứu trợ vẫn được giữ.');
    if(thumbnail&&!expected)await this.db.pool.query('UPDATE evidence SET thumbnail_sha256=$2 WHERE id=$1 AND thumbnail_sha256 IS NULL',[id,actual]);
    return { bytes, etag:'"'+actual+'"',notModified:false };
  }
}
