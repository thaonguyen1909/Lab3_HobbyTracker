
import {before,beforeEach,after,test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {collection,doc,getDoc,getDocs,setDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp,Timestamp,query,where,runTransaction} from 'firebase/firestore';
let env;
const projectId='demo-hobby-admin';
const db=(uid='alice')=>env.authenticatedContext(uid).firestore();
const profile=(name)=>({role:'user',displayName:name,createdAt:new Date('2026-01-01')});
const publicProfile=(name,visible=true,allowMessages=true)=>({displayName:name,handle:'',bio:'',color:'mint',visible,allowMessages});
const hobby=(name='Guitar',priority='interested')=>({name,nameKey:name.toLowerCase(),description:'Practice',icon:'music',color:'mint',priority,archived:false,createdAt:serverTimestamp()});
const plan=(hobbyId='h1',other={})=>({hobbyId,title:'Practice',startsAt:Timestamp.fromDate(new Date('2027-01-02')),minutes:30,done:false,eventId:'',completionId:'',...other});
const history=(other={})=>({hobbyId:'h1',name:'Guitar',icon:'music',color:'mint',elapsedMs:1000,notes:'Learned a chord',finishedAt:serverTimestamp(),planId:'',...other});
const preferences=()=>({theme:'Light',displayName:'Alice',handle:'alice',bio:'',color:'mint',music:'youtube',search:'google',reminders:true,leadMinutes:15,messages:true,groups:true,weekly:false,autoTimer:false,pauseOnExit:true,sound:false,visible:false,allowMessages:false});
before(async()=>{env=await initializeTestEnvironment({projectId,firestore:{rules:fs.readFileSync(new URL('../../../tools/integration/firebase/firestore.rules',import.meta.url),'utf8')}});});
beforeEach(async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(async c=>{
 const d=c.firestore();await setDoc(doc(d,'users/alice'),profile('Alice'));await setDoc(doc(d,'users/bob'),profile('Bob'));await setDoc(doc(d,'users/charlie'),profile('Charlie'));
 await setDoc(doc(d,'profiles/alice'),publicProfile('Alice'));await setDoc(doc(d,'profiles/bob'),publicProfile('Bob'));await setDoc(doc(d,'profiles/charlie'),publicProfile('Charlie',false,false));
 await setDoc(doc(d,'users/alice/hobbies/h1'),{...hobby(),createdAt:new Date('2026-01-01')});await setDoc(doc(d,'users/alice/hobbyNames/guitar'),{hobbyId:'h1'});
 await setDoc(doc(d,'posts/p1'),{authorId:'alice',authorName:'Alice',text:'Progress',topic:'Guitar',createdAt:new Date()});
 await setDoc(doc(d,'groups/g1'),{ownerId:'alice',name:'Guitar Club',topic:'Guitar',description:'Practice',createdAt:new Date()});await setDoc(doc(d,'groups/g1/members/alice'),{uid:'alice',joinedAt:new Date()});
 await setDoc(doc(d,'directChats/d1'),{participants:['alice','bob'],createdAt:new Date()});
 await setDoc(doc(d,'events/e1'),{ownerId:'alice',title:'Practice together',topic:'Guitar',startsAt:new Date('2027-01-02'),createdAt:new Date()});
});});
after(async()=>{await env?.cleanup();});

test('custom hobby and canonical name claim must be atomic',async()=>{
 const d=db(),b=writeBatch(d);b.set(doc(d,'users/alice/hobbies/h2'),hobby('Chess'));b.set(doc(d,'users/alice/hobbyNames/chess'),{hobbyId:'h2'});await assertSucceeds(b.commit());
 await assertSucceeds(getDocs(collection(d,'users/alice/hobbies')));
 await assertFails(setDoc(doc(d,'users/alice/hobbies/missing-claim'),hobby('Reading')));
});
test('same normalized hobby name cannot be claimed by another document',async()=>{
 const d=db(),b=writeBatch(d);b.set(doc(d,'users/alice/hobbies/h2'),hobby('GUITAR'));b.set(doc(d,'users/alice/hobbyNames/guitar'),{hobbyId:'h2'});await assertFails(b.commit());
 const bad=writeBatch(d);bad.set(doc(d,'users/alice/hobbies/h3'),{...hobby('Guitar'),nameKey:'bypass'});bad.set(doc(d,'users/alice/hobbyNames/bypass'),{hobbyId:'h3'});await assertFails(bad.commit());
});
test('rename releases old claim and preserves unrelated plans/history',async()=>{
 const d=db();await assertSucceeds(setDoc(doc(d,'users/alice/plans/p1'),plan()));await assertSucceeds(setDoc(doc(d,'users/alice/history/r1'),history()));
 const b=writeBatch(d);b.update(doc(d,'users/alice/hobbies/h1'),{name:'Piano',nameKey:'piano',priority:'active'});b.set(doc(d,'users/alice/hobbyNames/piano'),{hobbyId:'h1'});b.delete(doc(d,'users/alice/hobbyNames/guitar'));await assertSucceeds(b.commit());
 assert.equal((await getDoc(doc(d,'users/alice/plans/p1'))).data().hobbyId,'h1');assert.equal((await getDoc(doc(d,'users/alice/history/r1'))).data().name,'Guitar');
});
test('logical removal requires releasing name; new schedules denied and history retained',async()=>{
 const d=db();await assertSucceeds(setDoc(doc(d,'users/alice/history/r1'),history()));await assertFails(updateDoc(doc(d,'users/alice/hobbies/h1'),{archived:true}));
 const b=writeBatch(d);b.update(doc(d,'users/alice/hobbies/h1'),{archived:true});b.delete(doc(d,'users/alice/hobbyNames/guitar'));await assertSucceeds(b.commit());await assertFails(setDoc(doc(d,'users/alice/plans/p2'),plan()));await assertSucceeds(getDoc(doc(d,'users/alice/history/r1')));
});
for(const name of ['hobbies','hobbyNames','plans','history','settings','rsvps','groupLinks','devices'])test(`cross-user ${name} is private`,async()=>{
 const d=db('bob');await assertFails(getDocs(collection(d,`users/alice/${name}`)));await assertFails(getDoc(doc(d,`users/alice/${name}/h1`)));await assertFails(setDoc(doc(d,`users/alice/${name}/h1`),{}));
});
test('both Interested and Active may schedule; invalid duration and fake done denied',async()=>{
 const d=db();await assertSucceeds(setDoc(doc(d,'users/alice/plans/p1'),plan()));await assertSucceeds(updateDoc(doc(d,'users/alice/hobbies/h1'),{priority:'active'}));await assertSucceeds(setDoc(doc(d,'users/alice/plans/p2'),plan()));await assertFails(setDoc(doc(d,'users/alice/plans/bad'),plan('h1',{minutes:-5})));await assertFails(updateDoc(doc(d,'users/alice/plans/p1'),{done:true,completionId:'missing'}));
});
test('Finish transaction creates one immutable record and completes matching plan',async()=>{
 const d=db();await setDoc(doc(d,'users/alice/plans/p1'),plan());
 const finish=()=>runTransaction(d,async tx=>{const r=doc(d,'users/alice/history/session-1');if((await tx.get(r)).exists())return;tx.set(r,history({planId:'p1'}));tx.update(doc(d,'users/alice/plans/p1'),{done:true,completionId:'session-1'});});
 await assertSucceeds(finish());await assertSucceeds(finish());assert.equal((await getDocs(collection(d,'users/alice/history'))).size,1);assert.equal((await getDoc(doc(d,'users/alice/plans/p1'))).data().done,true);
 await assertFails(updateDoc(doc(d,'users/alice/history/session-1'),{elapsedMs:2}));await assertFails(deleteDoc(doc(d,'users/alice/history/session-1')));
});
test('history rejects forged snapshots, invalid duration, client time and unlinked plan',async()=>{
 const d=db();for(const bad of [{name:'Fake'},{elapsedMs:-1},{elapsedMs:86400001},{finishedAt:new Date('2000-01-01')},{planId:'missing'},{notes:'x'.repeat(2001)}])await assertFails(setDoc(doc(d,'users/alice/history/bad'),history(bad)));
});
test('preferences and public projection validate shapes and privacy query',async()=>{
 const d=db();await assertSucceeds(setDoc(doc(d,'users/alice/settings/preferences'),preferences()));await assertFails(setDoc(doc(d,'users/alice/settings/preferences'),{...preferences(),role:'admin'}));
 await assertSucceeds(updateDoc(doc(d,'profiles/alice'),{visible:false,allowMessages:false}));await assertFails(getDoc(doc(db('bob'),'profiles/alice')));await assertFails(updateDoc(doc(db('bob'),'profiles/alice'),{visible:true}));await assertSucceeds(getDocs(query(collection(db('bob'),'profiles'),where('visible','==',true))));await assertFails(getDocs(collection(db('bob'),'profiles')));
});
test('posts use real author and schema; anonymous/impersonation denied',async()=>{
 const d=db();const p={authorId:'alice',authorName:'Alice',text:'Made progress today',topic:'Guitar',createdAt:serverTimestamp()};await assertSucceeds(setDoc(doc(d,'posts/new'),p));await assertSucceeds(getDocs(collection(db('bob'),'posts')));await assertFails(setDoc(doc(db('bob'),'posts/fake'),p));await assertFails(setDoc(doc(d,'posts/extra'),{...p,password:'forbidden'}));await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(),'posts')));
});
test('likes and comments permit self; impersonation and oversized input denied',async()=>{
 const d=db();await assertSucceeds(setDoc(doc(d,'posts/p1/likes/alice'),{uid:'alice',createdAt:serverTimestamp()}));await assertFails(setDoc(doc(db('bob'),'posts/p1/likes/alice'),{uid:'alice',createdAt:serverTimestamp()}));await assertSucceeds(deleteDoc(doc(d,'posts/p1/likes/alice')));
 const c={authorId:'alice',authorName:'Alice',text:'Nice progress',createdAt:serverTimestamp()};await assertSucceeds(setDoc(doc(d,'posts/p1/comments/c1'),c));await assertFails(setDoc(doc(db('bob'),'posts/p1/comments/c2'),c));await assertFails(setDoc(doc(d,'posts/p1/comments/c3'),{...c,text:'x'.repeat(301)}));
});
test('group creator/member/link atomic, non-members denied chat; join enables chat',async()=>{
 const d=db(),b=writeBatch(d);b.set(doc(d,'groups/new'),{ownerId:'alice',name:'New group',topic:'Music',description:'',createdAt:serverTimestamp()});b.set(doc(d,'groups/new/members/alice'),{uid:'alice',joinedAt:serverTimestamp()});b.set(doc(d,'users/alice/groupLinks/new'),{name:'New group'});await assertSucceeds(b.commit());
 const bob=db('bob');await assertFails(getDocs(collection(bob,'groupChats/g1/messages')));await assertFails(setDoc(doc(bob,'groupChats/g1/messages/m1'),{senderId:'bob',text:'hello',createdAt:serverTimestamp()}));
 const join=writeBatch(bob);join.set(doc(bob,'groups/g1/members/bob'),{uid:'bob',joinedAt:serverTimestamp()});join.set(doc(bob,'users/bob/groupLinks/g1'),{name:'Guitar Club'});await assertSucceeds(join.commit());await assertSucceeds(setDoc(doc(bob,'groupChats/g1/messages/m1'),{senderId:'bob',text:'hello',createdAt:serverTimestamp()}));await assertSucceeds(getDocs(collection(bob,'groupChats/g1/messages')));await assertFails(setDoc(doc(bob,'groupChats/g1/messages/spoof'),{senderId:'alice',text:'hello',createdAt:serverTimestamp()}));
});
test('DM participants immutable, opt-in enforced, outside account denied',async()=>{
 const d=db();await assertSucceeds(setDoc(doc(d,'directChats/new'),{participants:['alice','bob'],createdAt:serverTimestamp()}));await assertFails(setDoc(doc(d,'directChats/private'),{participants:['alice','charlie'],createdAt:serverTimestamp()}));await assertFails(updateDoc(doc(d,'directChats/d1'),{participants:['alice','charlie']}));await assertFails(getDoc(doc(db('charlie'),'directChats/d1')));await assertFails(getDocs(collection(db('charlie'),'directChats/d1/messages')));
 await assertSucceeds(setDoc(doc(d,'directChats/d1/messages/m1'),{senderId:'alice',text:'hello',createdAt:serverTimestamp()}));await assertFails(setDoc(doc(db('bob'),'directChats/d1/messages/m2'),{senderId:'alice',text:'spoof',createdAt:serverTimestamp()}));
 await assertSucceeds(updateDoc(doc(db('bob'),'profiles/bob'),{allowMessages:false}));await assertFails(setDoc(doc(d,'directChats/d1/messages/m3'),{senderId:'alice',text:'blocked',createdAt:serverTimestamp()}));await assertSucceeds(getDocs(collection(d,'directChats/d1/messages')));
});
test('RSVP alone adds no calendar entry; explicit Add to Home requires RSVP',async()=>{
 const d=db();await assertFails(setDoc(doc(d,'users/alice/plans/event_e1'),plan('h1',{eventId:'e1'})));await assertSucceeds(setDoc(doc(d,'users/alice/rsvps/e1'),{going:true}));assert.equal((await getDocs(collection(d,'users/alice/plans'))).size,0);await assertSucceeds(setDoc(doc(d,'users/alice/plans/event_e1'),plan('h1',{eventId:'e1'})));await assertFails(setDoc(doc(d,'users/alice/plans/duplicate_event'),plan('h1',{eventId:'e1'})));
 const cancel=writeBatch(d);cancel.set(doc(d,'users/alice/rsvps/e1'),{going:false});cancel.delete(doc(d,'users/alice/plans/event_e1'));await assertSucceeds(cancel.commit());assert.equal((await getDocs(collection(d,'users/alice/plans'))).size,0);
});
test('events and device tokens validate owner and types; unknown paths denied',async()=>{
 const d=db();const e={ownerId:'alice',title:'Photo walk',topic:'Photo',startsAt:Timestamp.fromDate(new Date('2027-03-01')),createdAt:serverTimestamp()};await assertSucceeds(setDoc(doc(d,'events/new'),e));await assertFails(setDoc(doc(db('bob'),'events/spoof'),e));await assertFails(setDoc(doc(d,'events/past'),{...e,startsAt:new Date('2000-01-01')}));await assertSucceeds(setDoc(doc(d,'users/alice/devices/device1'),{token:'test-only-token',updatedAt:serverTimestamp()}));await assertFails(getDoc(doc(db('bob'),'users/alice/devices/device1')));await assertFails(setDoc(doc(d,'admin/config'),{role:'admin'}));
});
