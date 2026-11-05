import test from 'node:test';
import assert from 'node:assert/strict';
import {availableActions,actionAvailable} from '../src/policy.mjs';
const actions=(module,row,actor='staff')=>availableActions('superadmin',module,{id:'other',...row},actor);
test('account controls distinguish locked, restricted and active accounts',()=>{
 assert.deepEqual(actions('users',{status:'disabled'}),['enable']);
 const normal=actions('users',{status:'active',email:'u@example.test',providers:['password'],postingRestricted:false,messagingRestricted:false});
 assert.deepEqual(normal,['disable','revoke','resetPassword','restrictPost','restrictMessage']);
 assert.deepEqual(actions('users',{status:'restricted',postingRestricted:true,messagingRestricted:false}),['disable','revoke','restrictMessage','unrestrict']);
 assert.ok(!actions('users',{status:'active',email:'u@example.test',providers:['google.com']}).includes('resetPassword'));
 for(const row of [{id:'staff',status:'active'},{status:'active',isAdmin:true}])for(const action of ['disable','revoke'])assert.ok(!actions('users',row).includes(action));
});
test('posts never offer pin/unpin or hide/restore together',()=>{
 assert.deepEqual(actions('posts',{status:'active'}),['hide','pin']);assert.deepEqual(actions('posts',{status:'pinned'}),['hide','unpin']);assert.deepEqual(actions('posts',{status:'active',pinned:true}),['hide','unpin']);assert.deepEqual(actions('posts',{status:'hidden'}),['restore']);
 assert.deepEqual(actions('comments',{status:'active'}),['hide']);assert.deepEqual(actions('comments',{status:'hidden'}),['restore']);
});
test('groups offer only the opposite lock action',()=>{
 assert.deepEqual(actions('groups',{status:'active'}),['lock','edit','transferOwner']);assert.deepEqual(actions('groups',{status:'locked'}),['unlock','edit','transferOwner']);
});
test('events use explicit draft, published, cancelled and archived transitions',()=>{
 const future=new Date(Date.now()+86400000).toISOString();
 assert.deepEqual(actions('events',{status:'draft',startsAt:future}),['edit','publish','archive']);
 assert.deepEqual(actions('events',{status:'draft',startsAt:'2000-01-01'}),['edit','archive']);
 assert.deepEqual(actions('events',{status:'published'}),['edit','cancel','archive']);assert.deepEqual(actions('events',{status:'cancelled'}),['edit','archive','restore']);assert.deepEqual(actions('events',{status:'archived'}),['restore']);
});
test('notification campaigns cannot be sent again after sending or failure',()=>{
 for(const status of ['draft','scheduled'])assert.deepEqual(actions('notifications',{status}),['edit','send','cancel']);
 for(const status of ['sending','sent','cancelled','failed','partial','completed_with_errors'])assert.deepEqual(actions('notifications',{status}),[]);
});
test('resolved reports reopen and resolved tickets require reopen before public reply',()=>{
 for(const status of ['new','processing'])assert.deepEqual(actions('reports',{status}),['assign','resolve','dismiss']);
 for(const status of ['resolved','dismissed'])assert.deepEqual(actions('reports',{status}),['reopen']);
 assert.deepEqual(actions('tickets',{status:'open'}),['assign','reply','note','resolve']);assert.deepEqual(actions('tickets',{status:'resolved'}),['note','reopen']);
});
test('content actions follow publication state and archived content is restore-only',()=>{
 assert.deepEqual(actions('content',{status:'draft'}),['edit','publish','archive']);assert.deepEqual(actions('content',{status:'published'}),['edit','archive']);assert.deepEqual(actions('content',{status:'archived'}),['restore']);
});
test('admin self-management, last-super-admin and pending sync states are protected',()=>{
 assert.deepEqual(actions('admins',{status:'active'}),['changeRole','revokeRole']);assert.deepEqual(actions('admins',{status:'disabled'}),['changeRole']);
 for(const row of [{status:'active',id:'staff'},{status:'active',lastSuperAdmin:true},{status:'pending'}])assert.deepEqual(actions('admins',row),[]);
});
test('role restrictions and unsupported states fail closed',()=>{
 assert.deepEqual(availableActions('analyst','posts',{status:'active'}),[]);assert.deepEqual(availableActions('support','users',{status:'active'}),[]);
 for(const module of ['posts','groups','events','reports','tickets','content','notifications','admins','files'])assert.deepEqual(actions(module,{status:'unexpected'}),[]);
 assert.deepEqual(actions('files',{status:'available'}),['download']);assert.deepEqual(actions('operations',{status:'failed'}),[]);
});
test('bulk actions must be valid for every selected row, not only some rows',()=>{
 const selected=[{status:'active'},{status:'hidden'}];assert.equal(selected.every(row=>actionAvailable('posts','hide',row)),false);assert.equal(selected.every(row=>actionAvailable('posts','restore',row)),false);
 assert.equal([{status:'new'},{status:'processing'}].every(row=>actionAvailable('reports','resolve',row)),true);
});
