import test from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import {createAdminApp} from '../src/app.mjs';
function fixture(role='superadmin'){
 let listed=0;
 const auth={verifyIdToken:async()=>({uid:'staff',adminRole:role}),getUser:async uid=>({uid,displayName:'Minh'}),listUsers:async()=>{listed++;return{users:[{uid:'member-id',displayName:'Minh',email:'private@example.test'}],pageToken:'next-page'}}};
 const db={doc:path=>({path,get:async()=>path==='adminStaff/staff'?{exists:true,data:()=>({status:'active',adminRole:role,displayName:'Nhân viên'})}:{exists:true,data:()=>({name:'Guitar',hobbyId:'hobby-id',elapsedMs:60000,notes:'private'})}}),runTransaction:async fn=>fn({get:async()=>({data:()=>({count:0})}),set(){}})};
 const app=createAdminApp({auth,db,FieldValue:{},Timestamp:{fromMillis:value=>value}});
 return{get:path=>request(app).get(path).set('Authorization','Bearer fixture'),listed:()=>listed};
}
test('lookup permissions reject disallowed modules and field enumeration before reading users',async()=>{
 const analyst=fixture('analyst');assert.equal((await analyst.get('/options/groups/ownerId')).status,403);assert.equal(analyst.listed(),0);
 const admin=fixture();assert.equal((await admin.get('/options/groups/privateKey')).status,403);assert.equal(admin.listed(),0);
});
test('reference choices retain identifiers for submitting but only use names as labels',async()=>{
 const admin=fixture();const result=await admin.get('/options/groups/ownerId');assert.equal(result.status,200);assert.deepEqual(result.body.items,[{id:'member-id',label:'Minh',description:'private@example.test'}]);assert.equal(result.body.nextCursor,'next-page');
 const moderator=fixture('moderator');const limited=await moderator.get('/options/groups/ownerId');assert.equal(limited.status,200);assert.equal(limited.body.items[0].description,undefined);
});
test('practice details decode only the expected owner collection, redact notes and resolve names',async()=>{
 const f=fixture();const id=Buffer.from('users/member-id/history/record').toString('base64url');const result=await f.get(`/data/history/${id}`);
 assert.equal(result.status,200);assert.equal(result.body.ownerName,'Minh');assert.equal(result.body.hobbyName,'Guitar');assert.equal(result.body.notes,undefined);assert.equal(result.body.id,id);
 for(const path of ['adminStaff/staff','users/member-id/hobbies/record','users/../history/record'])assert.equal((await f.get(`/data/history/${Buffer.from(path).toString('base64url')}`)).status,400);
 assert.equal((await fixture('support').get(`/data/history/${id}`)).status,403);
});
