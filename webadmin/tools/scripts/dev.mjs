import {spawn} from 'node:child_process';
import {existsSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const server=fileURLToPath(new URL('../../src/server/',import.meta.url));
if(!existsSync(new URL('../../src/server/.env.local',import.meta.url))){
  console.error('Thiếu src/server/.env.local. Cấu hình backend trước, hoặc dùng npm run dev:web để chỉ chạy giao diện.');
  process.exit(1);
}
const children=[];
let stopping=false;
function stop(code=0){
  if(stopping)return;
  stopping=true;
  for(const child of children)if(child.exitCode===null)child.kill('SIGTERM');
  process.exitCode=code;
}
for(const [cwd,args] of [[server,['--env-file=.env.local','src/live-local.mjs']],[root,['tools/scripts/run-framework.mjs','dev',...process.argv.slice(2)]]]){
  const child=spawn(process.execPath,args,{cwd,stdio:'inherit',windowsHide:true});
  children.push(child);
  child.on('error',error=>{console.error(error.message);stop(1)});
  child.on('exit',code=>{if(!stopping)stop(code??1)});
}
process.on('SIGINT',()=>stop());
process.on('SIGTERM',()=>stop());
