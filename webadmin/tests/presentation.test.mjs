import test from 'node:test';
import assert from 'node:assert/strict';
import {formatValue,displayFields,formatDate,fieldLabel} from '../src/lib/admin/presentation.mjs';
import {createPresenter} from '../src/server/src/presentation.mjs';

test('stored enums display their functional names in tables, forms and exports',()=>{
 for(const [key,value,expected] of [['type','direct','Hội thoại riêng'],['type','privacy','Chính sách riêng tư'],['category','weekly','Tóm tắt tuần'],['path','/community/feed','Bảng tin cộng đồng'],['adminRole','moderator','Kiểm duyệt viên'],['action','bootstrap','Khởi tạo quản trị viên cấp cao'],['module','reports','Báo cáo vi phạm'],['priority','interested','Quan tâm']])assert.equal(formatValue(key,value),expected);
 assert.equal(formatValue('providers',['google.com','password']),'Google, Email và mật khẩu');
 assert.equal(formatValue('status','future_internal_code'),'Chưa xác định');
 assert.equal(formatValue('text','An actual user wrote {example: true}'),'An actual user wrote {example: true}');
});
test('configuration review and structured details have labels and localized values',()=>{
 assert.equal(fieldLabel('community_enabled'),'Cộng đồng');assert.equal(formatValue('community_enabled',true),'Bật');
 assert.equal(formatValue('emailVerified',false),'Không');assert.equal(formatValue('elapsedMs',3660000),'1 giờ 1 phút');
 assert.equal(formatValue('minutes',30),'30 phút');assert.equal(formatValue('size',1048576),'1 MB');
 assert.equal(formatValue('before',{maintenance:false}),'Chế độ bảo trì: Tắt');
});
test('references use names without displaying identifiers or duplicate name fields',()=>{
 const row={id:'encoded-id',ownerId:'uid-123',ownerName:'Minh',hobbyId:'h-1',hobbyName:'Guitar',notes:'private',status:'active'};
 assert.equal(formatValue('ownerId',row.ownerId,row),'Minh');assert.equal(formatValue('hobbyId',row.hobbyId,row),'Guitar');
 assert.equal(formatValue('ownerId','missing'),'Không còn thông tin tham chiếu');
 assert.deepEqual(displayFields(row).map(([k])=>k),['ownerId','hobbyId','status']);
});
test('malformed dates do not crash screens and Firestore timestamps use Vietnam time',()=>{
 assert.equal(formatDate('invalid'),'Chưa có thông tin');assert.equal(formatDate(null),'Chưa có thông tin');
 assert.equal(formatDate({seconds:0}),'01/01/1970');assert.equal(formatDate('2026-11-05T18:00:00Z'),'06/11/2026');
});
test('public names are resolved once per response and original identifiers remain intact',async()=>{
 let reads=0;const present=createPresenter({auth:{getUser:async uid=>{reads++;return {displayName:'Minh',email:'private@example.test'}}},db:{doc:path=>({get:async()=>({data:()=>({name:'Guitar'})})})}});
 const result=await present({items:[{id:'a',ownerId:'u',ownerName:'u',hobbyId:'h'},{id:'b',authorId:'u',authorName:'u'}]});
 assert.equal(reads,1);assert.equal(result.items[0].ownerName,'Minh');assert.equal(result.items[0].hobbyName,'Guitar');assert.equal(result.items[1].authorName,'Minh');assert.equal(result.items[0].ownerId,'u');assert.equal(result.items[0].id,'a');
});
test('report labels do not bypass the evidence permission gate',async()=>{
 const present=createPresenter({auth:{},db:{doc:()=>{throw new Error('Must not read reported content')}}});
 for(const [targetType,targetPath] of [['post','posts/p'],['message','directChats/c/messages/m'],['comment','posts/p/comments/c']]){
 const result=await present({targetType,targetPath});assert.ok(result.targetLabel.includes('được báo cáo'));assert.equal(result.targetPath,targetPath);
 }
});
test('deleted users and unavailable references use honest fallback labels',async()=>{
 const present=createPresenter({auth:{getUser:async()=>{throw new Error('not-found')}},db:{doc:()=>({get:async()=>({data:()=>undefined})})}});
 const result=await present({ownerId:'deleted',hobbyId:'gone'});assert.equal(result.ownerName,'Tài khoản không còn thông tin');assert.equal(result.hobbyName,'Sở thích đã được xóa');
});
test('members and replies show names while never using email as a public name',async()=>{
 const present=createPresenter({auth:{getUser:async()=>({email:'private@example.test'})},db:{}});
 const result=await present({items:[{id:'u'}]},'members');assert.equal(result.items[0].displayName,'Thành viên chưa đặt tên');
});
