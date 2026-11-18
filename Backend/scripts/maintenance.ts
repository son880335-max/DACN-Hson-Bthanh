import 'dotenv/config';
import { S3Client } from '@aws-sdk/client-s3';
import { loadConfig } from '../src/common/config.js';
import { createDatabase } from '../src/common/database.js';
import { LocalObjectStorage, S3ObjectStorage } from '../src/evidence/storage.js';
import { runMaintenance } from '../src/common/maintenance.js';

async function main() {
  const isDryRun = process.argv.includes('--dry-run');
  const config = loadConfig();
  const db = createDatabase(config.DATABASE_URL);

  let storage;
  if (process.env.STORAGE_BACKEND === 's3') {
    if (!process.env.S3_BUCKET || !process.env.AWS_REGION) throw new Error('S3_BUCKET and AWS_REGION are required');
    storage = new S3ObjectStorage(new S3Client({ region: process.env.AWS_REGION, endpoint: process.env.S3_ENDPOINT }), process.env.S3_BUCKET);
  } else {
    storage = new LocalObjectStorage(config.mediaDirectory);
  }

  try {
    console.log(`Starting maintenance${isDryRun ? ' [DRY RUN]' : ''}...`);
    const result = await runMaintenance(db, storage, {
      dryRun: isDryRun,
      retentionDays: config.OPERATION_RETENTION_DAYS,
    });
    console.log(JSON.stringify({
      event: 'maintenance_completed',
      dryRun: result.dryRun,
      sessionsCleaned: result.sessions,
      operationReceiptsCleaned: result.operationReceipts,
      unlinkedEvidenceCleaned: result.unlinkedEvidence,
    }, null, 2));
  } finally {
    await db.pool.end();
  }
}

main().catch(err => {
  console.error('Maintenance task failed:', err);
  process.exit(1);
});
