# AGENTS.md — Hobby Tracker | Codex execution & validation contract

> Applies to this repository and all subdirectories unless a more specific `AGENTS.md` overrides part of it. **This is a working agreement, not proof that any requirement has already passed.**
>
> Main objective: implement the approved **Hobby Tracker Lab 2** design as a testable **PRM393 Lab 3 Flutter + Firebase Android app**, The current target ends at Lab 3 phase 08. Work in strictly reviewed phases.

## 1. Mandatory startup procedure

For EVERY new Codex task:

1. Identify the **explicitly assigned phase** (`00`, `01`, `02`, `03`, `04`, `05`, `06`, `07A`, `07B`, `08`) and read its `docs/requirements/prompts/<phase>-*.md`. If no phase is specified, do a **read-only audit** and ask which phase to execute. Do not assume permission for all phases.
2. Read `docs/implementation-roadmap.md`, `README.md` (if present), `docs/open-decisions.md`, `docs/design-traceability.md`, `docs/architecture.md`, and the **relevant original artifacts** in `docs/requirements/reference/` (see §2). Locate the actual source files first; do not invent their contents.
3. Inspect `git status --short`, current branch, relevant project structure, build scripts and existing tests. Never discard or overwrite uncommitted user changes.
4. Before edits, state a compact plan: **goal, in-scope/out-of-scope, file changes, dependencies/blockers, acceptance checks**. Flag unresolved instructor or billing decisions.
5. Implement **only the assigned phase**. Validate it, provide evidence, and **stop**. Do not auto-start the next phase, deploy, tag, merge, or push.

If `docs/requirements/reference/` or a required handoff source is missing: name the missing files; for **phase 00**, document the gaps using available files; for later phases, do not invent design decisions or mark source-dependent work as complete. Continue only with clearly independent, safe work.

## 2. Reference sources and precedence

### Lab 2 — what the app must look like and do

- `docs/requirements/reference/Specification.html` — screen matrix, IA, three flows, invariants, design tokens, known limitations and unapproved gaps.
- `docs/requirements/reference/Prototype.html` — runnable **offline browser** interaction reference; sample/local data is NOT a production backend.
- `docs/requirements/reference/DesignArchive.html` — visual reference and snapshots, not an application runtime.
- `docs/requirements/reference/HobbyTracker_Design_Journey_12_Slides.pptx`
- `docs/requirements/reference/HobbyTracker_Design_Journey_Rebuilt_V3.pptx` — design rationale and evolution. The nine interviews were **AI-simulated**, not a real user study.

### Lab 3 — implementation obligations

- `docs/requirements/reference/PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf` — main Lab 3 task, evidence requirements and grading rubric.
- `docs/requirements/reference/PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` — operational setup/checklist.

### Final — excluded from current execution

`docs/requirements/planning/final/` is reference material only. Do not execute its prompts, introduce Staff/Admin approval, web clients or an in-app Gemini feature during Lab 3. The Final PDF is not a required Lab 3 input.

`docs/implementation-roadmap.md` and `docs/requirements/prompts/` are **implementation proposals** derived from these sources; they do not supersede the original lecturer requirements. For conflicts: document the exact source/section, impact and proposed choices in `docs/open-decisions.md`; do **not** silently choose or weaken a requirement. Never claim Figma, `docs/design/DESIGN.md`, `docs/design/handoff/flutter-handoff.md` or instructor approval exist unless verified in this repository.

## 3. Phase boundaries and approval gates

| Phase | Authorized goal | Required outcome before phase can be accepted |
|---|---|---|
| 00 | Source audit, traceability, implementation handoff | `docs/gap-review.md`, missing artifacts and unresolved decisions stated; **no feature implementation** |
| 01 | Flutter project, routing, MVVM, theme/components | App starts; four-tab shell, design tokens, reusable widgets and basic widget tests |
| 02 | Firebase initialization and real authentication | Auth guards, Google Sign-In, cancellation/error/logout paths, Firestore connectivity and tests |
| 03 | Flow 1 — custom hobbies | Create/edit/priority/duplicate/validation/persistence and recovery tests |
| 04 | Flow 2 — schedules, Hyper Mode and history | Timer correctness, pause/resume, duration/notes, one record per finish, ordered plans and tests |
| 05 | Flow 3 — Community | Feed/groups/activities/people/chats and relevant permissions; RSVP-to-calendar rule verified |
| 06 | Settings, seven themes, UI/accessibility | 15 screens reviewed, responsive/empty/loading/error states, settings behavior and visual review |
| 07A | PDF export and mandatory Cloud Storage upload | Local export works; **cloud upload remains BLOCKED** until approved and actually tested |
| 07B | FCM, Analytics, Crashlytics, Remote Config | Each service works with failure handling and verifiable console/test evidence |
| 08 | Lab 3 ARTEMIS, AI code review, submission QA | Verified test runs, reviewed findings, docs/evidence/report; no fabricated PASS |

A phase is **not accepted** merely because code compiles or a UI screenshot exists. All applicable functional, error/recovery, data/security and evidence gates must be satisfied. A human must approve moving to the next phase.

## 4. Lab 2 product invariants — do not break

### Navigation and 15 standalone screens

- Auth: **Login, Register, Forgot Password**.
- Home: **Home, Hyper Mode**.
- Hobbies: **My Hobbies, Hobby Detail**.
- Community: **Feed, Groups, Activities, People, Chats, Conversation**.
- Settings: **Settings, Settings Detail**.
- The ONLY four bottom destinations, in order: **Home / Community / My Hobbies / Settings**. Auth is outside bottom navigation. **Sign Out exists only within Settings and requires confirmation**. Dialogs are not counted as standalone screens.

### Flow 1 — Discover / Create Hobby

- Users **create their own hobbies**; do not replace the custom form with a fixed catalog.
- Save name, icon, color and priority; priorities **Active** and **Interested** both permit scheduling and Hyper Mode.
- Validate missing name/priority and duplicate names while preserving entered data and existing hobbies.
- Changing priority **must not** remove schedules or activity history.

### Flow 2 — Plan / Practice / Reflect

- Home → Add Schedule → Hyper Mode → start/pause/resume/reset, optional external tool shortcuts and notes → Finish → History.
- No hobby? Offer a route to create one. Same-day schedules sorted by start time.
- Timer counts actual active time, not paused time; a single Finish writes **one** activity record with duration and notes. Do not overwrite unrelated records or history.
- Spotify/YouTube are **external shortcuts**, not OAuth integrations or in-app music players.

### Flow 3 — Connect / Participate

- Community → Groups/People → Join/Message → Conversation → Send. In the app, chat must use real authorized backend data, not local-only echo.
- Activities → RSVP does **not** schedule a Home event automatically. Add to Home happens **only after the user explicitly requests it**.
- Any Final phase proposing Staff approval or `pending` RSVP is **an extension needing a documented owner/instructor decision**, not a preapproved Lab 2 behavior.

### UI fidelity and accessibility

- Default theme **Light**, plus **Dark, Energetic, Cyber, Art, Sad, Rainy Day** (7 themes).
- Baseline colors: primary `#087F72`, text `#213D36`, muted `#4F6F63`, bg `#F7FAF7`, soft `#E7F5ED`, border `#D8E9DF`.
- Spacing tokens: `4, 8, 12, 16, 20, 24, 32`; aim for touch targets at least **48dp**, body copy around **14sp+**, normal text contrast **4.5:1** where applicable. Verify at **360dp and 412dp**.
- Use clear loading/data/empty/error/retry UI on data screens and keyboard/semantic accessibility. Actual visual testing is required; never claim WCAG compliance solely from code or design notes.
- Record every justified difference between Lab 2 and implementation in `docs/design-traceability.md`, with the affected screen/flow, reason and human approval status. Do not silently redesign.

## 5. Technical architecture contract

- **Flutter (stable) + Dart**, Android target in Lab 3; Flutter Web only in Final phases.
- Separate **View (widgets) → ViewModel (state) → repository/service → Firebase SDK/API**. Use Provider or Riverpod consistently; follow the approved project choice, do not introduce a competing state manager.
- UI widgets **must not call Firebase SDK directly**. Inject external dependencies so test doubles can be used in unit/widget tests.
- Implement shared `ThemeData` / `ColorScheme` / `TextTheme` + spacing/radius tokens and reusable component states; avoid duplicating magic styles.
- Production/user data comes from real Firestore or an explicitly approved live data source. **No fake users, hardcoded posts or demo-only mocked success in the submission build.** Fixtures are allowed only under test/emulator development paths.
- Use explicit typed models, validation, async error handling, subscriptions lifecycle cleanup, safe cancellation and no unhandled Future errors.
- Firestore Security Rules are **deny by default**: no open `if true`, no client-trusted role escalation, no cross-user private-data reads or writes. Test positive AND negative permissions in Emulator Suite.
- No undeclared billing, paid API activation, production changes, deployment, secret sharing, test crashes on normal user paths, or destructive remote operations.

## 6. Special conflicts — stop and escalate rather than guessing

1. **Lab 3 mandatory file upload:** Generate and upload a file to Cloud Storage with per-user permissions, progress, URL and real evidence. Current Firebase Storage eligibility/billing must be verified for the project. Implement export separately from upload; if not authorized, report upload **BLOCKED**, never PASS.
2. **Missing formal Lab 2 deliverables:** HTML prototypes and slide decks alone do **not** prove Figma 6 pages or required handoff approval. Mark absent items as gaps and propose drafts, not fabricated artifacts.
3. **Authentication mismatch:** HTML prototype simulates email/password; Lab 3 requires Google Sign-In. Preserve visible routes and document any real-auth adaptations.

Document each decision/blocker in `docs/open-decisions.md` with **source, issue, impact, choice/approval needed, owner and status**. Implement independent tasks where safe; do not silently skip dependent requirements.

## 7. Mandatory verification on EVERY coding phase

Run checks appropriate to the files changed and the tools actually present. Determine the Flutter working directory from the repository rather than assuming the root.

**Repository / static checks**

```bash
git status --short
git diff --check
# Run in each changed Flutter/Dart package as appropriate:
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

**When applicable:**

- Flutter widget/unit/integration tests for the changed feature, including success, validation and failure/retry.
- Firebase Emulator Suite Firestore Rules tests for auth/roles/collection changes, both allowed and denied operations.
- `flutter build apk --debug` (Android phases) where toolchains are configured.
- Real Android emulator/device checks for Google picker, FCM foreground/background, Hyper Mode timing and responsive layouts; ARTEMIS runs as required for Lab 3 QA.
- Inspect console evidence for Analytics DebugView, Crashlytics, Remote Config and FCM. A log line in code is not proof the cloud service works.
- Verify data isolation with two distinct user accounts.
- Test offline, missing permission, empty query, network failure and duplicate submit for each relevant workflow.

**No fake results**. `PASS` only if the check truly executed with passing output. Use **FAIL** if executed and failed; **BLOCKED** for an external dependency/permission decision; **NOT RUN** if not executed. Do not treat `NOT RUN` as `PASS`. If unable to execute, write the exact reason and manual steps. Keep raw logs/screenshots/traces under `docs/evidence/<phase>/` only when actually generated. Never create placeholder screenshots or misleading test reports.

## 8. Security, repository hygiene and change control

- Preserve user edits; avoid `git reset --hard`, `git clean -fd`, destructive migrations, rewriting history or force-push. Never auto-merge/push/tag/commit unless explicitly directed.
- Do not read, log, paste or commit secrets unnecessarily. Do not put private keys, service-account JSON, Android signing keystores, `.env` contents or API tokens into Git or output. Use placeholders in docs; ensure `.gitignore` covers secrets and generated artifacts where appropriate.
- Do not modify the original `docs/requirements/reference/` inputs. Keep screenshots and artifacts traceable to the original source.
- Avoid new dependencies without a short justification and relevant version pinning. Add tests for business logic and security invariants, not only golden screenshots.
- No unrelated refactors, features, navigation changes or UI rewrites. Prefer minimal reversible diffs and readable named functions.
- AI code review findings must be independently evaluated: file/line, severity/category, accepted/rejected reason, remediation and test evidence. Do not auto-apply every AI suggestion without review.
- If user asks for **review/validate only**, remain read-only: report findings with severity, impacted path/line, reproduction and proposed fix. Edit only when explicitly tasked.

## 9. Completion report — REQUIRED format after each phase

Use this exact reporting structure in your final Codex reply:

```text
PHASE: <00..08> | <short name>
STATUS: PASS / PARTIAL / FAIL / BLOCKED  (phase as a whole)
SCOPE: <implemented and deliberately not implemented>
CHANGED FILES: <paths; state if none>
DESIGN TRACEABILITY: <screens/flows affected + document path>
ACCEPTANCE GATES:
  [PASS|FAIL|BLOCKED|NOT RUN] <criterion> — <evidence / command / output path>
COMMANDS ACTUALLY RUN:
  - <command> -> <exit code/result or exact blocker>
SECURITY & DATA CHECK: <findings and emulator evidence>
OPEN DECISIONS / RISKS: <issue, owner, next action>
COMMIT/PR/DEPLOY: <real id/url if applicable; otherwise NOT CREATED>
READY FOR HUMAN REVIEW: YES / NO
NEXT PHASE: NOT STARTED
```

Never say "100% complete", "verified", "deployed", "Firebase connected", "ARTEMIS passed" or "teacher approved" unless there is actual corroborating evidence. A phase marked `PASS` must also have all applicable gates verified. If unfinished, stop with an honest `PARTIAL` or `BLOCKED` report; do not begin the next phase to conceal the gap.

## 10. One-line operating principle

**Read the source → identify the phase → make the smallest correct change → run actual checks → report evidence → wait for human approval.**

## Current scope takes precedence

Only phases 00–08 are active. Read the five Lab 2 sources and two Lab 3 PDFs; locate missing sources externally if available and document their actual location. Final planning is archived under docs/requirements/planning/final/ and must not add Lab 3 acceptance gates. Cloud Storage upload is mandatory in Lab 3; unresolved service/billing conditions mean BLOCKED, not optional or complete. Security Rules and owner/member isolation remain required for Lab 3; multi-role Staff/Admin workflows are excluded. Do not restructure into mobile/web/packages/core for Lab 3.

## User scope override — 03/11/2026

The user explicitly requests all Lab3 phases 00–08 in one implementation pass, without per-phase approval pauses. Continue independent work across phase boundaries. Keep evidence-based acceptance and BLOCKED statuses for unavailable Firebase/Figma/Android/ARTEMIS/lecturer inputs. This does not authorize billing, cloud deployment, public publishing, merging or inventing evidence. `docs/full-implementation-report.md` is authoritative over historical phase notes.


## User scope override — live Figma UI, 03/11/2026

Update the entire existing Flutter app UI using live file 5JiJtLyXN6DEpC1LycQPBb as visual target. Preserve MVVM/Riverpod and Firebase behavior. Do not convert simulated prototype behavior into production. Record remaining functional/visual differences honestly in docs/figma-ui-report.md.
