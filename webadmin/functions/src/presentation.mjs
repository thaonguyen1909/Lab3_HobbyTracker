// Resolve public display names without changing identifiers or fetching private notes/messages.
const userRefs={ownerId:'ownerName',authorId:'authorName',userId:'userName',senderId:'senderName',actorId:'actorName',reporterId:'reporterName',assignee:'assigneeName',updatedBy:'updatedByName',uid:'displayName'};
export function createPresenter({auth,db}){
 return async function present(payload,module=''){
  const users=new Map(),documents=new Map();
  async function userName(uid){
   if(!uid)return 'Chưa chọn';
   if(!users.has(uid))users.set(uid,(async()=>{try{const u=await auth.getUser(uid);return u.displayName||'Thành viên chưa đặt tên'}catch{return 'Tài khoản không còn thông tin'}})());
   return users.get(uid);
  }
  async function documentName(path,fallback){
   if(!documents.has(path))documents.set(path,(async()=>{try{const snap=await db.doc(path).get();const d=snap.data();return d?.name||d?.title||d?.subject||(d?.text?d.text.slice(0,100):null)||fallback}catch{return fallback}})());
   return documents.get(path);
  }
  async function enrich(row){
   if(!row||typeof row!=='object')return row;
   if(Array.isArray(row))return Promise.all(row.map(enrich));
   const out={...row};
   await Promise.all(Object.entries(userRefs).filter(([key])=>typeof row[key]==='string'&&row[key]).map(async([key,name])=>{if(!row[name]||row[name]===row[key])out[name]=await userName(row[key])}));
   if(module==='admins'&&row.id&&!row.displayName)out.displayName=await userName(row.id);
   if(module==='members'&&row.id&&!row.displayName)out.displayName=await userName(row.uid||row.id);
   if(row.hobbyId&&row.ownerId)out.hobbyName=await documentName(`users/${row.ownerId}/hobbies/${row.hobbyId}`,'Sở thích đã được xóa');
   if(row.planId&&row.ownerId)out.planName=await documentName(`users/${row.ownerId}/plans/${row.planId}`,'Lịch luyện tập không còn tồn tại');
   if(row.eventId)out.eventName=await documentName(`events/${row.eventId}`,'Sự kiện không còn tồn tại');
   if(row.groupId)out.groupName=await documentName(`groups/${row.groupId}`,'Nhóm không còn tồn tại');
   if(row.postId)out.postName=await documentName(`posts/${row.postId}`,'Bài viết không còn tồn tại');
   if(row.audienceId){if(row.audience==='user')out.audienceName=await userName(row.audienceId);else if(['group','event'].includes(row.audience))out.audienceName=await documentName(`${row.audience==='group'?'groups':'events'}/${row.audienceId}`,'Đối tượng không còn tồn tại')}
   // Reports may identify private chats: keep their content behind the evidence permission gate.
   if(row.targetPath){const types={post:'Bài viết được báo cáo',comment:'Bình luận được báo cáo',group:'Nhóm được báo cáo',event:'Sự kiện được báo cáo',user:'Tài khoản được báo cáo',message:'Tin nhắn được báo cáo'};out.targetLabel=types[row.targetType]||'Nội dung được báo cáo'}
   for(const key of ['items','recentAudit','recentReports','eventsList','evidence','before','after','replies'])if(out[key])out[key]=await enrich(out[key]);
   return out;
  }
  return enrich(payload);
 };
}
