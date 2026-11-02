
import {before,after,test} from 'node:test';
import fs from 'node:fs';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {ref,uploadBytes,getBytes,deleteObject} from 'firebase/storage';
let env;
const bytes=new TextEncoder().encode('%PDF-1.4\nTest fixture only\n%%EOF');
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-hobbytracker-storage',storage:{host:'127.0.0.1',port:9199,rules:fs.readFileSync(new URL('../storage.rules',import.meta.url),'utf8')}});});
after(async()=>{await env?.cleanup();});
test('owner uploads PDF, reads own bytes and deletes own report',async()=>{
 const storage=env.authenticatedContext('alice').storage(),file=ref(storage,'reports/alice/own.pdf');await assertSucceeds(uploadBytes(file,bytes,{contentType:'application/pdf'}));await assertSucceeds(getBytes(file));await assertSucceeds(deleteObject(file));
});
test('other user and anonymous cannot read or write report',async()=>{
 const owner=env.authenticatedContext('alice').storage();await uploadBytes(ref(owner,'reports/alice/private.pdf'),bytes,{contentType:'application/pdf'});
 for(const context of [env.authenticatedContext('bob'),env.unauthenticatedContext()]){const storage=context.storage();await assertFails(getBytes(ref(storage,'reports/alice/private.pdf')));await assertFails(uploadBytes(ref(storage,'reports/alice/forged.pdf'),bytes,{contentType:'application/pdf'}));}
});
test('wrong type, extension, zero bytes and files over 10MB denied',async()=>{
 const storage=env.authenticatedContext('alice').storage();await assertFails(uploadBytes(ref(storage,'reports/alice/file.txt'),bytes,{contentType:'application/pdf'}));await assertFails(uploadBytes(ref(storage,'reports/alice/file.pdf'),bytes,{contentType:'text/plain'}));await assertFails(uploadBytes(ref(storage,'reports/alice/empty.pdf'),new Uint8Array(),{contentType:'application/pdf'}));await assertFails(uploadBytes(ref(storage,'reports/alice/huge.pdf'),new Uint8Array(10*1024*1024+1),{contentType:'application/pdf'}));
});
test('unknown storage folders are closed',async()=>{
 const storage=env.authenticatedContext('alice').storage();await assertFails(uploadBytes(ref(storage,'public/leak.pdf'),bytes,{contentType:'application/pdf'}));await assertFails(uploadBytes(ref(storage,'reports/alice/nested/leak.pdf'),bytes,{contentType:'application/pdf'}));
});
