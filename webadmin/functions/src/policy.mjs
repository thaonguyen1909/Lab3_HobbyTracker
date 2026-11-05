export const roles=['superadmin','admin','moderator','support','analyst'];
const read={superadmin:['*'],admin:['*'],moderator:['dashboard','posts','groups','events','reports','chats','audit','settings'],support:['dashboard','users','tickets','reports','files','audit','settings'],analyst:['dashboard','analytics','settings']};
const write={superadmin:['*'],admin:['users','posts','groups','events','reports','notifications','tickets','content','files','config'],moderator:['posts','groups','events','reports'],support:['tickets','reports']};
export function can(role,module,action='read'){
 if(!roles.includes(role))return false;
 const set=action==='read'||action==='export'?read[role]:(write[role]||[]);
 if(action==='export'&&['chats','audit','files'].includes(module)&&role!=='superadmin')return false;
 return set.includes('*')||set.includes(module);
}
export const ACTIONS={users:['disable','enable','revoke','resetPassword','restrictPost','restrictMessage','unrestrict'],posts:['hide','restore','pin','unpin'],comments:['hide','restore'],groups:['lock','unlock','edit','transferOwner'],events:['edit','publish','cancel','archive','restore'],reports:['assign','resolve','dismiss','reopen'],notifications:['edit','send','cancel'],tickets:['assign','reply','note','resolve','reopen'],content:['edit','publish','archive','restore'],admins:['changeRole','revokeRole'],files:['download'],operations:['retry']};
export function authorizeAction(role,module,action){return can(role,module==='comments'?'posts':module,'write')&&(ACTIONS[module]||[]).includes(action);}
export function csvCell(v){const value=String(v??'').replace(/[\r\n]+/g,' ');return '"'+(/^[=+@\-\t]/.test(value)?"'"+value:value).replaceAll('"','""')+'"';}

// Availability is separate from role permission. Unknown lifecycle states fail closed.
export function actionAvailable(module,action,row,actorId='',now=Date.now()){
 const status=row.status||(module==='users'?(row.disabled?'disabled':'active'):['posts','comments','groups'].includes(module)?'active':'');
 if(module==='users'){
  if(status==='disabled')return action==='enable';
  if(!['active','restricted'].includes(status))return false;
  if(['disable','revoke'].includes(action))return row.id!==actorId&&!row.isAdmin;
  if(action==='resetPassword')return !!row.email&&row.providers?.includes('password')===true;
  if(action==='restrictPost')return !row.postingRestricted&&status!=='restricted'||status==='restricted'&&row.postingRestricted===false;
  if(action==='restrictMessage')return !row.messagingRestricted&&status!=='restricted'||status==='restricted'&&row.messagingRestricted===false;
  if(action==='unrestrict')return !!(row.postingRestricted||row.messagingRestricted||status==='restricted');
  return false;
 }
 if(module==='posts')return status==='hidden'?action==='restore':['active','pinned'].includes(status)&&(['hide',row.pinned||status==='pinned'?'unpin':'pin'].includes(action));
 if(module==='comments')return status==='hidden'?action==='restore':status==='active'&&action==='hide';
 if(module==='groups')return ['active','locked'].includes(status)&&['edit','transferOwner',status==='locked'||row.locked?'unlock':'lock'].includes(action);
 if(module==='events'){
  const actions={draft:['edit','publish','archive'],published:['edit','cancel','archive'],cancelled:['edit','restore','archive'],archived:['restore']};
  return (actions[status]||[]).includes(action)&&(action!=='publish'||new Date(row.startsAt).getTime()>now);
 }
 if(module==='notifications')return ['draft','scheduled'].includes(status)&&['edit','send','cancel'].includes(action);
 if(module==='reports')return ['resolved','dismissed'].includes(status)?action==='reopen':['new','processing'].includes(status)&&['assign','resolve','dismiss'].includes(action);
 if(module==='tickets')return status==='resolved'?['note','reopen'].includes(action):['open','processing'].includes(status)&&['assign','reply','note','resolve'].includes(action);
 if(module==='content')return ({draft:['edit','publish','archive'],published:['edit','archive'],archived:['restore']}[status]||[]).includes(action);
 if(module==='admins')return row.id!==actorId&&!row.lastSuperAdmin&&(status==='active'?['changeRole','revokeRole'].includes(action):status==='disabled'&&action==='changeRole');
 if(module==='files')return status==='available'&&action==='download';
 return false;
}
/** @returns {string[]} */
export function availableActions(role,module,row,actorId='',now=Date.now()){return (ACTIONS[module]||[]).filter(action=>authorizeAction(role,module,action)&&actionAvailable(module,action,row,actorId,now))}
