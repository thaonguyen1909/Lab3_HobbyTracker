const WEEK=7*24*60*60*1000;
function timestamp(value){if(value?.toDate)value=value.toDate();if(value&&typeof value==='object'&&(value.seconds??value._seconds)!=null)value=(value.seconds??value._seconds)*1000;const t=new Date(value??NaN).getTime();return Number.isFinite(t)?t:null}
function localDay(time){return new Date(time).toLocaleDateString('sv-SE',{timeZone:'Asia/Ho_Chi_Minh'})}
// Return to practice, not a proxy for app opens or Google Analytics retention.
export function practiceReturnRate(records,now=Date.now(),truncated=false){
 const end=timestamp(now);if(end===null)throw new Error('Invalid report time.');
 if(truncated)return {status:'limited',eligible:0,returned:0,waiting:0,percentage:null,windowDays:7};
 const users=new Map();
 for(const record of records){const time=timestamp(record.finishedAt),owner=record.ownerId;if(!owner||time===null||time>end)continue;if(!users.has(owner))users.set(owner,[]);users.get(owner).push(time)}
 let eligible=0,returned=0,waiting=0;
 for(const sessions of users.values()){
  sessions.sort((a,b)=>a-b);const first=sessions[0];if(first+WEEK>end){waiting++;continue}
  eligible++;if(sessions.some(time=>time>first&&time<=first+WEEK&&localDay(time)!==localDay(first)))returned++;
 }
 return {status:eligible?'ready':'waiting',eligible,returned,waiting,percentage:eligible?Math.round(returned/eligible*1000)/10:null,windowDays:7};
}
