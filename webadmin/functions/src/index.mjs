import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore,FieldValue,Timestamp} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {getMessaging} from 'firebase-admin/messaging';
import {onRequest} from 'firebase-functions/v2/https';
import {createAdminApp} from './app.mjs';
initializeApp();
const allowedOrigins=(process.env.ADMIN_ALLOWED_ORIGINS||'https://hobby-tracker-admin-minh-20261106.minhvuplu09.chatgpt.site,http://localhost:4173,http://localhost:3000').split(',').map(s=>s.trim());
const app=createAdminApp({auth:getAuth(),db:getFirestore(),bucket:process.env.ADMIN_STORAGE_BUCKET?getStorage().bucket(process.env.ADMIN_STORAGE_BUCKET):null,messaging:getMessaging(),FieldValue,Timestamp,allowedOrigins});
export const adminApi=onRequest({invoker:'public',region:'asia-southeast1',timeoutSeconds:60,memory:'512MiB',maxInstances:5},app);

// Opt-in scheduler: deploy this export only after reviewing FCM preferences on test devices.
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {sendCampaign} from './campaigns.mjs';
export const adminCampaignScheduler=onSchedule({schedule:'every 5 minutes',region:'asia-southeast1',timeZone:'Asia/Ho_Chi_Minh',maxInstances:1},async()=>{const db=getFirestore();const due=await db.collection('adminCampaigns').where('status','==','scheduled').where('scheduledAt','<=',Timestamp.now()).limit(10).get();for(const doc of due.docs){try{await sendCampaign({db,auth:getAuth(),messaging:getMessaging(),FieldValue,campaignId:doc.id,actor:{uid:'scheduler',displayName:'Lịch gửi'},reason:'Gửi theo lịch đã được quản trị viên xác nhận'})}catch(e){console.error('campaign-failed',doc.id,e.code||e.name)}}});
import {createMobileApp} from './mobile.mjs';
export const mobileApi=onRequest({invoker:'public',region:'asia-southeast1',timeoutSeconds:30,memory:'256MiB',maxInstances:5},createMobileApp({auth:getAuth(),db:getFirestore(),FieldValue,Timestamp}));
