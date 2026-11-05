import crypto from 'node:crypto';
import {ApiError,notificationEligible} from './domain.mjs';
// Each delivery is claimed before calling FCM. An uncertain delivery is not retried
// automatically: this avoids duplicate pushes after a crash between send and record.
export async function sendCampaign({db,auth,messaging,FieldValue,campaignId,actor,reason}){
 const ref=db.doc(`adminCampaigns/${campaignId}`);let c;
 await db.runTransaction(async tx=>{const snap=await tx.get(ref);if(!snap.exists)throw new ApiError(404,'Không có chiến dịch.');c=snap.data();if(!['draft','scheduled'].includes(c.status))throw new ApiError(409,'Chiến dịch đã gửi, đang xử lý hoặc đã hủy.');tx.update(ref,{status:'sending',startedAt:FieldValue.serverTimestamp(),startedBy:actor.uid})});
 let sent=0,failed=0,skipped=0,uncertain=0,hasMore=false;try{
 let uids=[];if(c.audience==='user'){await auth.getUser(c.audienceId);uids=[c.audienceId]}
 else if(c.audience==='group'){const members=await db.collection(`groups/${c.audienceId}/members`).limit(1001).get();uids=members.docs.map(d=>d.id)}
 else if(c.audience==='event'){const r=await db.collectionGroup('rsvps').limit(1001).get();uids=r.docs.filter(d=>d.id===c.audienceId&&d.data().going===true).map(d=>d.ref.parent.parent.id);hasMore=r.size>1000}
 else {const result=await auth.listUsers(1000);uids=result.users.filter(u=>!u.disabled).map(u=>u.uid);hasMore=!!result.pageToken}
 if(uids.length>1000||hasMore)throw new ApiError(400,'Đối tượng vượt phạm vi 1.000 tài khoản hoặc RSVP. Chia chiến dịch thành nhóm nhỏ trước khi gửi.');
 for(const uid of [...new Set(uids)]){const [prefs,restriction,devices]=await Promise.all([db.doc(`users/${uid}/settings/preferences`).get(),db.doc(`adminRestrictions/${uid}`).get(),db.collection(`users/${uid}/devices`).limit(10).get()]);if(restriction.data()?.disabled||!notificationEligible(prefs.data(),c.category)){skipped++;continue}const user=await auth.getUser(uid).catch(()=>null);if(!user||user.disabled){skipped++;continue}
 for(const device of devices.docs){const token=device.data().token;if(typeof token!=='string'||!token)continue;const hash=crypto.createHash('sha256').update(`${campaignId}:${uid}:${token}`).digest('hex'),delivery=db.doc(`adminDeliveries/${hash}`);let claimed=false;
 await db.runTransaction(async tx=>{const exists=await tx.get(delivery);if(exists.exists)return;tx.create(delivery,{campaignId,ownerId:uid,status:'claimed',createdAt:FieldValue.serverTimestamp()});claimed=true});if(!claimed){skipped++;continue}
 try{const messageId=await messaging.send({token,notification:{title:c.title,body:c.body},data:{ownerId:uid,path:c.path,title:c.title,body:c.body,category:c.category,campaignId},android:{priority:'normal',ttl:3600000}});sent++;await delivery.update({status:'accepted_by_fcm',messageId,updatedAt:FieldValue.serverTimestamp()})}catch(e){failed++;if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(e.code))await device.ref.delete();await delivery.update({status:'failed',errorCode:e.code||'unknown',updatedAt:FieldValue.serverTimestamp()}).catch(()=>{uncertain++})}
 }
 }
 await ref.update({status:failed?'completed_with_errors':'sent',sentCount:sent,failedCount:failed,skippedCount:skipped,uncertainCount:uncertain,completedAt:FieldValue.serverTimestamp()});await db.collection('adminAudit').add({actorId:actor.uid,actorName:actor.displayName,module:'notifications',action:'send',targetId:campaignId,reason,after:{sent,failed,skipped,uncertain},createdAt:FieldValue.serverTimestamp()});return{id:campaignId,status:failed?'completed_with_errors':'sent',sentCount:sent,failedCount:failed,notice:'FCM đã chấp nhận yêu cầu gửi; chưa chứng minh thiết bị đã nhận hoặc đã đọc.'};
 }catch(e){await ref.update({status:sent?'partial':'failed',sentCount:sent,failedCount:failed,error:e.status?e.message:'Lỗi dịch vụ gửi. Kiểm tra delivery trước khi xử lý thủ công.',completedAt:FieldValue.serverTimestamp()});throw e}
}
