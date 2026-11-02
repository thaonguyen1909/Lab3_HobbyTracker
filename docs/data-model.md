# Data model and permissions — integrated Lab3

| Path | Main fields | Permissions |
|---|---|---|
| users/{uid} | role=user,displayName,createdAt | self get/create; name-only update; no list/delete/role change |
| users/{uid}/hobbies/{id} | name,nameKey,description,icon,color,priority,archived,createdAt | owner; canonical claim required; logical removal |
| users/{uid}/hobbyNames/{normalizedName} | hobbyId | owner; atomic reservation must point to matching active hobby |
| users/{uid}/plans/{id} | hobbyId,title,startsAt,minutes,done,eventId,completionId | owner; active hobby; true done links immutable history |
| users/{uid}/history/{sessionId} | hobbyId/name/icon/color snapshot,elapsedMs,notes,finishedAt,planId | owner create/read; no update/delete; optional plan completion link |
| users/{uid}/settings/preferences | theme/profile/apps/notification/hyper/privacy values | owner; exact validated schema |
| users/{uid}/rsvps/{eventId} | going | owner, event exists |
| users/{uid}/groupLinks/{groupId} | name | owner; membership must existAfter |
| users/{uid}/devices/{encodedToken} | token,updatedAt | owner, private |
| profiles/{uid} | displayName,handle,bio,color,visible,allowMessages | self write; others only visible profiles; list query filters visible=true |
| posts/{id} | authorId,authorName,text,topic,createdAt | signed-in read; real owner create; no spoof author/unknown fields |
| posts/{id}/likes/{uid} | uid,createdAt | signed-in read, self write/delete |
| posts/{id}/comments/{id} | authorId,authorName,text,createdAt | signed-in read, self create; immutable |
| groups/{id} | ownerId,name,topic,description,createdAt | signed-in read, creator atomic create + membership |
| groups/{id}/members/{uid} | uid,joinedAt | self join; member-scoped reads |
| groupChats/{groupId}/messages/{id} | senderId,text,createdAt | members only; sender self; immutable |
| events/{id} | ownerId,title,topic,startsAt,createdAt | signed-in read, self create future event |
| directChats/{id} | participants[2],createdAt | participants only; opt-in DM creation; participants immutable |
| directChats/{id}/messages/{id} | senderId,text,createdAt | participants, current DM policy on create; immutable |
| Storage reports/{uid}/{uuid}.pdf | application/pdf, 1–10MB | owner only, closed other paths |

All unknown paths deny by default. No Staff/Admin role workflow in Lab3. Private owner queries need no composite indexes; feed/events/messages use single-field order, chats arrayContains, profiles equality. Actual emulator allowed/denied tests are in firebase/tests. Rules prove authorization/schema, not whether a client-reported practice duration corresponds to physical behavior.

Removal is logical archive plus name-claim release and known-plan cleanup. History stays as a snapshot; all plan views/reminders exclude inactive/missing hobbies. Transaction retry and stable session/message IDs prevent app-level duplicate submissions. Device local preferences/drafts/inbox keys are owner-scoped and cleared on owner change/sign-out.
