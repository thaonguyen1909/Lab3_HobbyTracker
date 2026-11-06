import test from 'node:test';
import assert from 'node:assert/strict';
import {practiceReturnRate} from '../src/server/src/practice-retention.mjs';
const now=Date.parse('2026-11-06T12:00:00+07:00');
const row=(ownerId,finishedAt)=>({ownerId,finishedAt});
test('uses eligible first-time practitioners and counts each returning person once',()=>{
 const r=practiceReturnRate([row('a','2026-10-20T10:00:00+07:00'),row('a','2026-10-21T10:00:00+07:00'),row('a','2026-10-22T10:00:00+07:00'),row('b','2026-10-20T10:00:00+07:00'),row('b','2026-11-01T10:00:00+07:00'),row('new','2026-11-05T10:00:00+07:00')],now);
 assert.deepEqual(r,{status:'ready',eligible:2,returned:1,waiting:1,percentage:50,windowDays:7});
});
test('additional sessions on the same Vietnam calendar day are not a return',()=>{
 assert.equal(practiceReturnRate([row('a','2026-10-20T01:00:00+07:00'),row('a','2026-10-20T23:00:00+07:00')],now).percentage,0);
});
test('calendar days use Vietnam time rather than UTC date',()=>{
 const result=practiceReturnRate([row('a','2026-10-20T16:50:00Z'),row('a','2026-10-20T17:10:00Z')],now);
 assert.equal(result.returned,1);
});
test('requires a full seven-day observation window and includes the exact boundary',()=>{
 const first=Date.parse('2026-10-30T12:00:00+07:00');
 assert.equal(practiceReturnRate([row('a',first)],now-1).eligible,0);
 assert.equal(practiceReturnRate([row('a',first),row('a',now)],now).returned,1);
 assert.equal(practiceReturnRate([row('a',first),row('a',now+1)],now+1).returned,0);
});
test('sorts history, ignores invalid/future/missing-owner records and handles timestamps',()=>{
 const r=practiceReturnRate([row('a','2026-10-22'),row('a',{seconds:Date.parse('2026-10-20')/1000}),row('a','bad'),row('','2026-10-01'),row('future','2027-01-01')],now);
 assert.equal(r.eligible,1);assert.equal(r.returned,1);
});
test('empty or immature data is not reported as a fabricated zero percentage',()=>{
 assert.equal(practiceReturnRate([],now).percentage,null);
 const r=practiceReturnRate([row('new','2026-11-06T10:00:00+07:00')],now);assert.equal(r.status,'waiting');assert.equal(r.waiting,1);assert.equal(r.percentage,null);
});
test('truncated history never produces a misleading partial rate',()=>{
 const r=practiceReturnRate([row('a','2026-10-01')],now,true);assert.equal(r.status,'limited');assert.equal(r.percentage,null);
});
