import { resolve } from 'node:path';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().url(),
  HOST: z.string().default('127.0.0.1'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  CORS_ORIGINS: z.string().default(''),
  MEDIA_DIRECTORY: z.string().default('.local/media'),
  SESSION_HOURS: z.coerce.number().int().min(1).max(720).default(12),
  MAX_IMAGE_BYTES: z.coerce.number().int().positive().default(8 * 1024 * 1024),
  MAX_IMAGE_PIXELS: z.coerce.number().int().positive().default(20_000_000),
  MAX_EVIDENCE_LINKS: z.coerce.number().int().min(1).max(100).default(20),
  LOGIN_ATTEMPTS_PER_MINUTE: z.coerce.number().int().positive().default(10),
});

export function loadConfig(env: NodeJS.ProcessEnv = process.env) {
  const value = envSchema.parse(env);
  if (value.NODE_ENV === 'production' && value.CORS_ORIGINS.split(',').includes('*')) {
    throw new Error('Wildcard CORS is not allowed in production');
  }
  return {
    ...value,
    mediaDirectory: resolve(value.MEDIA_DIRECTORY),
    origins: value.CORS_ORIGINS.split(',').map(v => v.trim()).filter(Boolean),
  };
}
export type AppConfig = ReturnType<typeof loadConfig>;
