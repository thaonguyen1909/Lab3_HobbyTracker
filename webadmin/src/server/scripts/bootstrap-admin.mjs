import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore,FieldValue} from 'firebase-admin/firestore';
const [projectId,email]=process.argv.slice(2);if(!projectId||!email){console.error('Usage: node functions/scripts/bootstrap-admin.mjs PROJECT_ID ADMIN_EMAIL');process.exit(1)}
initializeApp({projectId});const db=getFirestore(),auth=getAuth();
const user=await auth.getUserByEmail(email);const ref=db.doc(`adminStaff/${user.uid}`);
// A one-time operation: never promotes a second person through the bootstrap route.
await db.runTransaction(async tx=>{const lock=db.doc('adminSystem/bootstrap'),existing=await tx.get(lock),staff=await tx.get(db.collection('adminStaff').where('status','==','active').limit(1));if(existing.exists||!staff.empty)throw new Error('Bootstrap already used. Use Super Admin UI for subsequent roles.');tx.create(lock,{uid:user.uid,createdAt:FieldValue.serverTimestamp()});tx.set(ref,{adminRole:'superadmin',status:'pending',email:user.email,displayName:user.displayName||user.email,createdAt:FieldValue.serverTimestamp()})});
try{await auth.setCustomUserClaims(user.uid,{...user.customClaims,adminRole:'superadmin'});await auth.revokeRefreshTokens(user.uid);await ref.update({status:'active'});await db.collection('adminAudit').add({actorId:user.uid,actorName:user.displayName||user.email,module:'admins',action:'bootstrap',targetId:user.uid,reason:'Khởi tạo Super Admin qua CLI có quyền Google Cloud',createdAt:FieldValue.serverTimestamp()});console.log('Super Admin ready. Sign out and sign in again.')}catch(e){console.error('Bootstrap incomplete; staff remains pending. Review Auth claims and adminSystem/bootstrap before retrying.');throw e}
