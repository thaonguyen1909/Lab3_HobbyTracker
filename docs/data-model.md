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

## Moments backend step 1 — 04/11/2026

User-authorized extension, separate from historical Lab 3 acceptance. `groups/{gid}/moments/{mid}` holds backend-owned author/name/hobby snapshots, caption, mediaPath/thumbnailPath, status and server-derived publishedAt/expiresAt. Clients only get live metadata as current members; listing/writing is backend-only. `users/{uid}/momentUploads/{mid}` is owner-readable upload state; `momentLimits/{uid}` is server-only quota state.

Storage staging is owner-create-only during a live session. JPEG/thumbnail at `groupMoments/{gid}/{mid}/{leaseId}/` deny all direct client reads/writes. Authenticated getGroupMomentImage returns bytes after membership/expiry checks before and after IO, avoiding reusable Firebase download-token URLs. No periodic physical cleanup, friendship or FCM fan-out is added here. See [backend contract](../functions/README.md) and [verification](moments-backend-step1-report.md).

## Moments alerts step 3 — 04/11/2026

Publish now atomically creates server-only `momentOutbox/{mid}` with groupId/authorId/publishedAt/expiresAt/done/cursor/nextAttemptAt and processing lease. Subcollections deliveries/{uid} and devices/{deviceId} record delivery state without storing public media URLs. Composite index: outbox done + nextAttemptAt. Firestore trigger + scheduled retry process bounded pages; emulator sender never calls real FCM.

Owner settings `users/{uid}/settings/momentNotifications` contain exactly enabled/previewOnLockScreen booleans (both default false). `momentGroupSettings/{gid}` contains muted; only the owner/current member can set it. `momentInbox/{eventId}` is backend-create-only and owner-readable reference metadata (event/group/moment IDs, publishedAt, expiresAt, read); owner may change read only or delete it. Reference reads can outlive group membership/expiry because no image/caption/name is stored there; media APIs still check current membership/expiry. See [step 3 report](moments-alerts-step3-report.md).

## Cleanup metadata — 04/11/2026

Moment/session/outbox documents now carry backend-only cleanupPending and cleanupAfter. Moment/session tombstones add cleanedAt/status=expired and drop private snapshots/content; their IDs persist to block replay of old upload requests. Retraction is due immediately; upload processing has a grace period; outbox has 24-hour retention after expiresAt. `momentMaintenance/cleanup` holds the global lease, backfill/list cursors and counts (deny by default to all clients). No client Rules permissions are broadened.

New indexes cover collection-group moments/momentUploads cleanupPending+cleanupAfter, collection-scoped outbox cleanup, and collection-group momentInbox expiresAt. Cleanup deletes expired inbox references, unlike step 3's retained references; it does not authorize reading media. Per-device marker/index TTL is local only. See [step 4 retention policy](moments-cleanup-step4-report.md).

## Cloudinary media manifest — 04/11/2026

Production Moments uses server-only momentCloudAssets/{SHA256(mediaPath)}: name, content hash, random Cloudinary publicId under hobbytracker-moments-v1/, immutable generation, createdAt, assetId/bytes after upload and deleted tombstone after cleanup. Unknown pending uploads are discoverable from the reservation. Cleanup lists bounded manifest pages rather than arbitrary Cloudinary paths; deletes by immutable provider asset ID. Public/signed URLs and API secrets are never written to Firestore. Existing deny-by-default Rules deny this collection to all client SDKs; Admin access is backend-only. Published moment/session/outbox schemas and authoritative expiry remain compatible. The ticket bucket field is the sentinel cloudinary, not a Firebase bucket. See moments-cloudinary-run.md; live provider checks are pending.

## Lịch tập trung và lặp hữu hạn — 04/11/2026

Không đổi schema plan hoặc completion/history. minutes mở từ enum sang int trong [1,1440]. Repeating schedules tạo ngay tối đa100 plan docs riêng trong users/{uid}/plans, mỗi occurrence ID ổn định dựa trên request ID của form. Không lưu repeat metadata/series document: các buổi độc lập, không có series edit/delete. Transaction retry không ghi đè completed plan. UI/date computation local, startsAt serialize UTC như trước. Xem quick-schedule-update.md.
