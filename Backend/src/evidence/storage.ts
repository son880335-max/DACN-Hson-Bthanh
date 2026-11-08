import { createHash, randomUUID } from 'node:crypto';
import { mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';

export interface ObjectStorage { put(key: string, bytes: Buffer): Promise<void>; get(key: string): Promise<Buffer>; }
function validKey(key: string) {
  if (!/^[a-f0-9-]{36}(?:\.thumb)?\.jpg$/.test(key)) throw new Error('Invalid internal media key');
  return key;
}
export class LocalObjectStorage implements ObjectStorage {
  constructor(private readonly root: string) {}
  async put(key: string, bytes: Buffer) {
    await mkdir(this.root, { recursive: true });
    const target = resolve(this.root, validKey(key));
    const temporary = resolve(this.root, randomUUID() + '.upload');
    try {
      await writeFile(temporary, bytes, { flag: 'wx', mode: 0o600 });
      await rename(temporary, target);
    } catch (error) { await unlink(temporary).catch(() => undefined); throw error; }
  }
  get(key: string) { return readFile(resolve(this.root, validKey(key))); }
}
export class S3ObjectStorage implements ObjectStorage {
  constructor(private readonly client: S3Client, private readonly bucket: string) {}
  async put(key: string, bytes: Buffer) {
    await this.client.send(new PutObjectCommand({ Bucket: this.bucket, Key: validKey(key), Body: bytes,
      ContentType: 'image/jpeg', ServerSideEncryption: 'AES256',
      ChecksumSHA256: createHash('sha256').update(bytes).digest('base64') }));
  }
  async get(key: string) {
    const object = await this.client.send(new GetObjectCommand({ Bucket: this.bucket, Key: validKey(key) }));
    if (!object.Body) throw new Error('Missing media body');
    return Buffer.from(await object.Body.transformToByteArray());
  }
}
