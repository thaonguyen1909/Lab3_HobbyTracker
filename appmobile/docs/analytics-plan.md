# Analytics plan — source implemented, Console verification NOT RUN

Only Firebase UID is used as the Analytics user ID. Parameters never contain names, e-mails, message text, hobby names, notes, access tokens or download URLs. Authenticated session entry currently logs login with method=firebase, including restored sessions; interpret this as app-session entry, not a provider conversion metric.

| Event | Trigger | Parameters and types | Product question |
|---|---|---|---|
| login | identity enters authenticated runtime | method:string=firebase | How many authenticated sessions start? |
| logout | identity leaves authenticated runtime | none | How many sessions end through sign-out? |
| create_hobby | successful custom save | priority:string enum | How many users start with Active vs Interested? |
| edit_hobby | successful edit | priority:string enum | How often do users revise a hobby? |
| change_priority | success | hobby_id:string, priority:string | Do users change their focus? |
| create_schedule | plan saved | none | How frequently does planning occur? |
| finish_session | history transaction succeeded | hobby_id:string, elapsed_seconds:int | How much practice is completed? |
| open_detail | hobby/chat/settings/Hyper opens | screen:string enum | Which detail destinations are opened? |
| create_post | published | none | How often do users share progress? |
| join_group | membership write succeeded | group_id:string | Which groups attract participation? |
| rsvp | RSVP write succeeded | event_id:string, going:int 0/1 | How often do people opt in/out? |
| add_event_to_home | explicit successful Add | event_id:string | How many RSVPs turn into planned sessions? |
| send_message | message persisted or retry-confirmed | none | How often do users converse? |
| export_report | PDF bytes generated | record_count:int | How much history appears in exports? |
| upload_report | cloud upload and URL succeeded | none | How often are exports uploaded? |
| share_report | native share action returned | none | How often do users share reports? |
| notification_permission | permission/token registration succeeded | none | Do users enable notifications? |
| open_shortcut | external launch succeeded | service:string enum | Which external tools are used? |

Instrumented events need DebugView evidence on the owner's project. A log call or fake-test capture is not cloud evidence. No screen tracking includes private route IDs or free-form text.
