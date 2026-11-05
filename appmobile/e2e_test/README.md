# ARTEMIS real Android acceptance

Pinned daemon/client reference: google/artemis `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (inspected current SDK source). SDK uses ArtemisClient.run(profile, expected_output, enable_outputter, device_serial); results expose succeeded/output/task_id. Source: https://github.com/google/artemis/tree/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/packages/artemis-client .

On your Android host install Python 3.12+, uv, ADB/ARTEMIS daemon and the dedicated model key per ARTEMIS documentation. Keep daemon on localhost or an authenticated tunnel. Install this folder's requirements, set ARTEMIS_BASE_URL and optional ANDROID_SERIAL/ARTEMIS_TOKEN using environment variables, then run `pytest e2e_test -v`. Model API key belongs to the daemon host, not the app or repo.

17 independent critical cases ×3 runs plus one opt-in Pro exploration. Each case states preconditions and checks typed observed fields, not SUCCESS alone. The Firebase project/accounts, native picker, RC values, FCM sends and Logcat analytics capture must be prepared as described by each case. Missing host is SKIP/BLOCKED, not a passing E2E run. Use a separate test project; generated unique QA names isolate runs.

The project currently has no real-device ARTEMIS pass evidence. Do not relabel collected/skipped tests as successful. Capture screenshots/logcat/run traces locally, redact identities, and review the structured fields against observed UI. `docs/evidence/08/artemis/` contains results only after real runs. After an actual run calculate pass rate per case, investigate any result below 3/3, and document causes/fixes. Set RUN_ARTEMIS_EXPLORATORY=yes only when ready for a 15–30 minute Pro session.
