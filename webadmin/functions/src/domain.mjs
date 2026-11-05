import {z} from 'zod';
import {roles,can,authorizeAction} from './policy.mjs';
export class ApiError extends Error{constructor(status,message){super(message);this.status=status}}
export const id=z.string().min(1).max(128).regex(/^[A-Za-z0-9_.:@-]+$/);
const short=(min=0,max=120)=>z.string().trim().min(min).max(max);
const reason=short(5,500);
const date=z.string().datetime({offset:true});
const safePath=z.string().min(1).max(512).regex(/^[A-Za-z0-9_.:@/-]+$/).refine(p=>!p.includes('..')&&!p.includes('//'));
export const moduleCollections={posts:'posts',groups:'groups',events:'events',reports:'adminReports',notifications:'adminCampaigns',tickets:'supportTickets',content:'appContent',admins:'adminStaff',audit:'adminAudit',operations:'adminJobs'};
export const createSchemas={
 posts:z.object({text:short(3,800),topic:short(0,50),reason}),
 groups:z.object({name:short(3,60),topic:short(0,50),description:short(0,300),ownerId:id,reason}),
 events:z.object({title:short(3,120),topic:short(0,50),description:short(0,2000).default(''),startsAt:date,endsAt:date.optional(),location:short(0,300).default(''),capacity:z.number().int().min(1).max(100000).optional(),status:z.enum(['draft','published','cancelled']),reason}),
 reports:z.object({title:short(3,120),targetType:z.enum(['post','comment','group','event','message','user']),targetPath:safePath,description:short(5,2000),priority:z.enum(['low','normal','high']),reason}),
 notifications:z.object({title:short(3,120),body:short(3,1000),audience:z.enum(['all','user','group','event']),audienceId:short(0,128).optional(),category:z.enum(['messages','groups','reminders','weekly']),path:z.enum(['/home','/hobbies','/community/feed','/community/groups','/community/activities','/community/chats','/settings/notifications']),scheduledAt:date.optional(),reason}).superRefine((v,c)=>{if(v.audience!=='all'&&!v.audienceId)c.addIssue({code:'custom',message:'Cần mã đối tượng nhận.'});if(v.scheduledAt&&new Date(v.scheduledAt)<=new Date())c.addIssue({code:'custom',message:'Lịch gửi phải ở tương lai.'})}),
 tickets:z.object({subject:short(3,120),userId:id,body:short(3,2000),priority:z.enum(['low','normal','high']),reason}),
 content:z.object({title:short(3,120),type:z.enum(['banner','faq','guide','terms','privacy','onboarding']),body:short(3,10000),status:z.enum(['draft','published','archived']),reason}),
 admins:z.object({email:z.string().email(),adminRole:z.enum(roles),reason}),
};
const editSchemas={posts:createSchemas.posts.omit({reason:true}),groups:createSchemas.groups.omit({reason:true}),events:createSchemas.events.omit({reason:true}),content:createSchemas.content.omit({reason:true}),notifications:z.object({title:short(3,120),body:short(3,1000),audience:z.enum(['all','user','group','event']),audienceId:short(0,128).optional(),category:z.enum(['messages','groups','reminders','weekly']),path:z.enum(['/home','/hobbies','/community/feed','/community/groups','/community/activities','/community/chats','/settings/notifications']),scheduledAt:date.optional()})};
export const actionSchema=z.object({reason,expectedVersion:z.number().int().nonnegative().optional(),expectedUpdatedAt:date.optional(),fields:z.record(z.unknown()).optional(),adminRole:z.enum(roles).optional(),assignee:short(0,128).optional(),ownerId:id.optional(),message:short(1,2000).optional()}).strict();
export const configSchema=z.object({community_enabled:z.boolean(),feed_limit:z.number().int().min(1).max(100),maintenance:z.boolean(),min_version:z.string().regex(/^\d+\.\d+\.\d+$/),message:short(0,500),reason,expectedVersion:z.number().int().nonnegative()}).strict();
export function parse(schema,input){const r=schema.safeParse(input);if(!r.success)throw new ApiError(400,r.error.issues.map(i=>`${i.path.join('.')}: ${i.message}`).join('; '));return r.data}
export function createInput(module,input){const s=createSchemas[module];if(!s)throw new ApiError(405,'Chức năng này không cho tạo bản ghi.');const clean={...input};delete clean.id;return parse(s.strict?s.strict():s,clean)}
export function editInput(module,input){const s=editSchemas[module];if(!s)throw new ApiError(405,'Không hỗ trợ chỉnh sửa loại bản ghi này.');return parse(s.strict(),input)}
export function assertPermission(role,module,action='read'){if(!can(role,module,action))throw new ApiError(403,'Bạn không có quyền cho phạm vi này.')}
export function assertAction(role,module,action){if(!authorizeAction(role,module,action))throw new ApiError(403,'Hành động không được phép cho vai trò này.')}
export function assertVersion(current,payload){if(payload.expectedVersion!=null&&(current.version||1)!==payload.expectedVersion)throw new ApiError(409,'Bản ghi đã được người khác thay đổi. Tải lại trước khi tiếp tục.');if(payload.expectedUpdatedAt&&current.updatedAt){const v=current.updatedAt.toDate?current.updatedAt.toDate().toISOString():current.updatedAt;if(v!==payload.expectedUpdatedAt)throw new ApiError(409,'Dữ liệu đã thay đổi. Hãy tải lại bản ghi.')}}
export function assertEvent(v){if(v.endsAt&&new Date(v.endsAt)<=new Date(v.startsAt))throw new ApiError(400,'Thời gian kết thúc phải sau thời gian bắt đầu.');if(v.status==='published'&&new Date(v.startsAt)<=new Date())throw new ApiError(400,'Sự kiện xuất bản phải bắt đầu trong tương lai.')}
export function reportTarget(type,path){const patterns={post:/^posts\/[^/]+$/,comment:/^posts\/[^/]+\/comments\/[^/]+$/,group:/^groups\/[^/]+$/,event:/^events\/[^/]+$/,user:/^users\/[^/]+$/,message:/^(directChats|groupChats)\/[^/]+\/messages\/[^/]+$/};if(!patterns[type]?.test(path))throw new ApiError(400,'Đường dẫn không phù hợp loại đối tượng báo cáo.');return path}
export function publicRow(data){const row={...data};for(const key of ['notes','token','tokens','privateKey','passwordHash','passwordSalt','customClaims','evidenceSnapshot','rawToken'])delete row[key];return row}
export function auditValue(data){if(!data)return null;const out={};for(const[k,v]of Object.entries(data)){if(/text|body|description|notes|email|token|password|replies|participants|evidence/i.test(k)){out[k]='[đã che]'}else if(v===null||['string','number','boolean'].includes(typeof v)){out[k]=v}else if(v?.toDate){out[k]=v.toDate().toISOString()}}return out}
export function getDate(value){if(!value)return null;const d=value.toDate?value.toDate():new Date(value);return isNaN(d.getTime())?null:d}
export function serialize(value){if(value?.toDate)return value.toDate().toISOString();if(Array.isArray(value))return value.map(serialize);if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,serialize(v)]));return value}
export function guardLastSuperAdmin({actorUid,targetUid,targetRole,nextRole,activeSuperCount}){if(actorUid===targetUid&&nextRole!=='superadmin')throw new ApiError(409,'Không thể tự thu hồi hoặc hạ quyền trong thao tác này.');if(targetRole==='superadmin'&&nextRole!=='superadmin'&&activeSuperCount<=1)throw new ApiError(409,'Không thể vô hiệu hóa Super Admin cuối cùng.')}
export function notificationEligible(prefs,category){return prefs?.[category]===true}
