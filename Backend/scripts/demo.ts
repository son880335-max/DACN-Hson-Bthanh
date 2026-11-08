import { randomBytes } from 'node:crypto';
import { execFile,spawn } from 'node:child_process';
import { mkdir,readFile,writeFile,access,unlink } from 'node:fs/promises';
import { dirname,resolve,join } from 'node:path';
import { promisify } from 'node:util';
import { createApp } from '../src/app.js';
import { loadConfig } from '../src/common/config.js';
import { createDatabase } from '../src/common/database.js';
import { LocalObjectStorage } from '../src/evidence/storage.js';

async function main(){
  if(process.platform!=='win32')throw new Error('This local convenience command supports Windows. Use PostgreSQL with DATABASE_URL on other systems.');
  const binaries=await import('@embedded-postgres/'+'windows-x64') as {initdb:string;postgres:string};
  const execute=promisify(execFile),root=resolve('.local'),data=join(root,'postgres'),settingsPath=join(root,'dev-database.json');
  await mkdir(root,{recursive:true});
  let settings:{password:string;port:number};
  try{settings=JSON.parse(await readFile(settingsPath,'utf8'));}
  catch(error){if((error as NodeJS.ErrnoException).code!=='ENOENT')throw error;
    settings={password:randomBytes(32).toString('hex'),port:54323};await writeFile(settingsPath,JSON.stringify(settings),{mode:0o600,flag:'wx'});}
  let initialized=true;try{await access(join(data,'PG_VERSION'));}catch{initialized=false;}
  if(!initialized){
    const temporary=join(root,'init-password');await writeFile(temporary,settings.password,{mode:0o600});
    try{await execute(binaries.initdb,['-D',data,'--username=postgres','--auth=scram-sha-256','--encoding=UTF8','--locale=C','--pwfile='+temporary],{windowsHide:true});}
    finally{await unlink(temporary);}
  }
  const child=spawn(binaries.postgres,['-D',data,'-h','127.0.0.1','-p',String(settings.port)],{windowsHide:true,stdio:['ignore','ignore','pipe']});
  await new Promise<void>((resolve,reject)=>{
    const timer=setTimeout(()=>reject(new Error('Local database did not start; check whether another demo instance is running.')),20_000);
    child.once('error',error=>{clearTimeout(timer);reject(error);});
    child.once('exit',()=>{clearTimeout(timer);reject(new Error('Local database could not start. No other instance was stopped.'));});
    child.stderr.on('data',chunk=>{if(String(chunk).includes('database system is ready to accept connections')){clearTimeout(timer);resolve();}});
  });
  const databaseUrl=`postgresql://postgres:${settings.password}@127.0.0.1:${settings.port}/postgres`;
  const db=createDatabase(databaseUrl);
  let app:Awaited<ReturnType<typeof createApp>>|undefined,stopping=false;
  async function stop(){if(stopping)return;stopping=true;await app?.close();await db.pool.end();await execute(join(dirname(binaries.postgres),'pg_ctl.exe'),['-D',data,'-m','fast','-w','stop'],{windowsHide:true});}
  process.once('SIGINT',()=>void stop());process.once('SIGTERM',()=>void stop());
  try{
    await db.migrate();
    try{await access(join(root,'dev-accounts.json'));}catch{
      await execute(process.execPath,['--import','tsx','scripts/seed-dev.ts'],{windowsHide:true,
        env:{...process.env,NODE_ENV:'development',DATABASE_URL:databaseUrl}});
    }
    const config=loadConfig({NODE_ENV:'development',DATABASE_URL:databaseUrl,HOST:'127.0.0.1',PORT:'3000',
      MEDIA_DIRECTORY:join(root,'media'),CORS_ORIGINS:'http://localhost:8080,http://127.0.0.1:8080'});
    app=await createApp(config,db,new LocalObjectStorage(config.mediaDirectory));
    await app.listen(config.PORT,config.HOST);
    console.log('Local API: http://127.0.0.1:3000/api/v1. Development credentials: .local/dev-accounts.json. No SMS is sent. Ctrl+C stops this instance.');
  }catch(error){await stop();throw error;}
}
main().catch(error=>{console.error(error instanceof Error?error.message:'Local demo failed');process.exitCode=1;});
