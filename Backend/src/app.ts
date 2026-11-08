import 'reflect-metadata';
import { Body, Controller, Delete, Get, Headers, Inject, Module, Param, Post, Put, Query, Req, Res } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import multipart from '@fastify/multipart';
import rateLimit from '@fastify/rate-limit';
import { S3Client } from '@aws-sdk/client-s3';
import { AuthService, requireRole } from './auth/auth.service.js';
import { AppConfig } from './common/config.js';
import { Database } from './common/database.js';
import { ApiError, ApiErrorFilter } from './common/errors.js';
import { Operations } from './common/operations.js';
import { EvidenceService } from './evidence/evidence.service.js';
import { LocalObjectStorage, ObjectStorage, S3ObjectStorage } from './evidence/storage.js';
import { RequestsService } from './requests/requests.service.js';
import { expectedRevision, reliefTypes, urgencyLevels } from './requests/schemas.js';

const SERVICES = Symbol('services');
interface Services { auth: AuthService; requests: RequestsService; evidence: EvidenceService; db: Database; }
@Controller('api/v1')
class ApiController {
  private activeUploads=0;
  constructor(@Inject(SERVICES) private readonly service: Services) {}
  @Post('auth/login') login(@Body() body: unknown) { return this.service.auth.login(body); }
  @Get('auth/me') me(@Headers('authorization') token?: string) { return this.service.auth.authenticate(token); }
  @Delete('auth/session') async logout(@Headers('authorization') token: string) {
    await this.service.auth.authenticate(token); await this.service.auth.logout(token); return { signedOut: true };
  }
  @Post('auth/register') registrationUnavailable() {
    throw new ApiError(503, 'SMS_PROVIDER_NOT_CONFIGURED', 'Đăng ký/xác minh số điện thoại thật chưa được cấu hình. Không có tài khoản nào được xác minh bởi thao tác này.');
  }
  @Post('auth/verify') verificationUnavailable() {
    throw new ApiError(503, 'SMS_PROVIDER_NOT_CONFIGURED', 'Chưa có dịch vụ xác minh OTP thật được cấu hình.');
  }
  @Post('auth/recovery') recoveryUnavailable() {
    throw new ApiError(503, 'SMS_PROVIDER_NOT_CONFIGURED', 'Chưa có dịch vụ khôi phục bằng số điện thoại được cấu hình.');
  }
  @Get('catalogs') async catalogs(@Headers('authorization') token: string) {
    await this.service.auth.authenticate(token); return { reliefTypes, urgencyLevels };
  }
  @Get('requests') async list(@Headers('authorization') token: string, @Query('before') before?: string) {
    return this.service.requests.list(await this.service.auth.authenticate(token), before);
  }
  @Get('requests/:id') async get(@Headers('authorization') token: string, @Param('id') id: string, @Res({ passthrough: true }) response: any) {
    const item = await this.service.requests.get(await this.service.auth.authenticate(token), id);
    response.header('ETag', `"${item.revision}"`); return item;
  }
  @Post('requests') async create(@Headers('authorization') token: string, @Body() body: unknown) {
    return this.service.requests.create(await this.service.auth.authenticate(token), body);
  }
  @Put('requests/:id') async update(@Headers('authorization') token: string, @Param('id') id: string,
    @Headers('if-match') version: string, @Body() body: unknown) {
    return this.service.requests.update(await this.service.auth.authenticate(token), id, body, expectedRevision(version));
  }
  @Post('requests/:id/cancel') async cancel(@Headers('authorization') token: string, @Param('id') id: string,
    @Headers('if-match') version: string, @Body() body: unknown) {
    return this.service.requests.cancel(await this.service.auth.authenticate(token), id, body, expectedRevision(version));
  }
  @Put('requests/:id/evidence') async attachEvidence(@Headers('authorization') token:string,@Param('id') id:string,
    @Headers('if-match') version:string,@Body() body:unknown) {
    return this.service.requests.attachEvidence(await this.service.auth.authenticate(token),id,body,expectedRevision(version));
  }
  @Post('requests/:id/reviews') async review(@Headers('authorization') token: string, @Param('id') id: string,
    @Headers('if-match') version: string, @Body() body: unknown) {
    return this.service.requests.review(await this.service.auth.authenticate(token), id, body, expectedRevision(version));
  }
  @Post('requests/:id/reports') async report(@Headers('authorization') token: string, @Param('id') id: string, @Body() body: unknown) {
    return this.service.requests.report(await this.service.auth.authenticate(token), id, body);
  }
  @Get('requests/:id/similar') async similar(@Headers('authorization') token: string, @Param('id') id: string) {
    return this.service.requests.similar(await this.service.auth.authenticate(token), id);
  }
  @Get('requests/:id/history') async history(@Headers('authorization') token: string,@Param('id') id: string,@Query('before') before?: string) {
    return this.service.requests.history(await this.service.auth.authenticate(token),id,before);
  }
  @Get('notices') async notices(@Headers('authorization') token: string, @Query('before') before?: string) {
    return this.service.requests.notices(await this.service.auth.authenticate(token), before);
  }
  @Put('notices/:id/read') async readNotice(@Headers('authorization') token: string, @Param('id') id: string) {
    return this.service.requests.readNotice(await this.service.auth.authenticate(token), id);
  }
  @Post('evidence') async upload(@Headers('authorization') token: string, @Req() request: any) {
    const actor = await this.service.auth.authenticate(token);
    requireRole(actor,'citizen');
    if(this.activeUploads>=2)throw new ApiError(503,'IMAGE_PROCESSOR_BUSY','Hệ thống đang xử lý ảnh. Yêu cầu chính vẫn có thể gửi trước; ảnh sẽ được thử lại.');
    this.activeUploads++;
    try {
    let metadata: unknown;
    let bytes: Buffer | undefined;
    for await (const part of request.parts()) {
      if (part.type === 'file') {
        if (bytes || part.fieldname !== 'image') throw new ApiError(422, 'INVALID_UPLOAD', 'Chỉ nhận một ảnh cho mỗi thao tác tải.');
        bytes = await part.toBuffer();
        if (part.file.truncated) throw new ApiError(413, 'IMAGE_TOO_LARGE', 'Ảnh vượt giới hạn xử lý.');
      } else if (part.fieldname === 'metadata' && metadata === undefined) {
        try { metadata = JSON.parse(String(part.value)); }
        catch { throw new ApiError(422, 'INVALID_UPLOAD', 'Thông tin ảnh chưa hợp lệ.'); }
      } else { throw new ApiError(422, 'INVALID_UPLOAD', 'Trường tải ảnh không được hỗ trợ.'); }
    }
    if (!bytes || !metadata) throw new ApiError(422, 'INVALID_UPLOAD', 'Thiếu ảnh hoặc thông tin ảnh.');
    return await this.service.evidence.upload(actor, bytes, metadata);
    } finally {this.activeUploads--;}
  }
  @Get('evidence/:id') async image(@Headers('authorization') token: string, @Param('id') id: string,
    @Query('thumbnail') thumbnail: string, @Headers('if-none-match') etag: string, @Res() response: any) {
    const result = await this.service.evidence.read(await this.service.auth.authenticate(token), id, thumbnail === '1',etag);
    response.header('Cache-Control', 'private, no-cache').header('Vary','Authorization, Origin').header('ETag', result.etag);
    if (result.notModified) return response.status(304).send();
    return response.type('image/jpeg').header('Content-Disposition', `inline; filename="${id}.jpg"`).send(result.bytes);
  }
}

@Controller('health')
class HealthController {
  constructor(@Inject(SERVICES) private readonly service: Services) {}
  @Get('live') live() { return { status: 'ok' }; }
  @Get('ready') async ready() { await this.service.db.pool.query('SELECT 1'); return { status: 'ready' }; }
}

export async function createApp(config: AppConfig, db: Database, storage?: ObjectStorage) {
  const operations = new Operations(db);
  const auth = new AuthService(db, config);
  const requests = new RequestsService(db, operations, config);
  if (!storage) {
    if (process.env.STORAGE_BACKEND === 's3') {
      if (!process.env.S3_BUCKET || !process.env.AWS_REGION) throw new Error('S3_BUCKET and AWS_REGION are required');
      if (process.env.S3_ENDPOINT && !process.env.S3_ENDPOINT.startsWith('https://')) throw new Error('S3 endpoint requires HTTPS');
      storage = new S3ObjectStorage(new S3Client({ region: process.env.AWS_REGION, endpoint: process.env.S3_ENDPOINT }), process.env.S3_BUCKET);
    } else {
      if (config.NODE_ENV === 'production' && process.env.MEDIA_PERSISTENT_VOLUME !== 'true') {
        throw new Error('Production local media requires an explicitly configured persistent volume, or STORAGE_BACKEND=s3');
      }
      storage = new LocalObjectStorage(config.mediaDirectory);
    }
  }
  const services: Services = { auth, requests, evidence: new EvidenceService(db, operations, requests, storage, config), db };
  @Module({ controllers: [ApiController, HealthController], providers: [{ provide: SERVICES, useValue: services }] })
  class AppModule {}
  const app = await NestFactory.create<NestFastifyApplication>(AppModule,
    new FastifyAdapter({ bodyLimit: 256 * 1024, logger: false, trustProxy: false,
      requestTimeout:35_000,connectionTimeout:10_000,keepAliveTimeout:5000 }), { logger: ['error', 'warn'] });
  app.useGlobalFilters(new ApiErrorFilter());
  await app.register(helmet);
  await app.register(cors, { origin: (origin, done) => done(null, !origin || config.origins.includes(origin)), credentials: false });
  await app.register(multipart, { limits: { fileSize: config.MAX_IMAGE_BYTES, files: 1, fields: 1, fieldSize: 8192, parts: 2 } });
  await app.register(rateLimit, { max: 180, timeWindow: '1 minute',
    errorResponseBuilder: () => ({ code: 'RATE_LIMITED', message: 'Có quá nhiều thao tác. Vui lòng thử lại sau.' }) });
  const loginRequests = new Map<string, { count: number; resetAt: number }>();
  app.getHttpAdapter().getInstance().addHook('onRequest', async (request: any, response: any) => {
    response.header('Cache-Control', 'no-store');
    if (request.url.split('?')[0] !== '/api/v1/auth/login') return;
    const now = Date.now();
    for (const [key, value] of loginRequests) if (value.resetAt <= now) loginRequests.delete(key);
    const entry = loginRequests.get(request.ip) ?? { count: 0, resetAt: now + 60_000 };
    entry.count++; loginRequests.set(request.ip, entry);
    if (entry.count > config.LOGIN_ATTEMPTS_PER_MINUTE) {
      return response.code(429).header('Retry-After', Math.ceil((entry.resetAt-now)/1000))
        .send({ code: 'RATE_LIMITED', message: 'Có quá nhiều lần đăng nhập. Hãy thử lại sau.' });
    }
  });
  await app.init();
  await app.getHttpAdapter().getInstance().ready();
  return app;
}
