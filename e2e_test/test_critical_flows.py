
"""Real-device ARTEMIS acceptance. Missing host/device is SKIP, never PASS."""
import json
import os
import uuid
from pathlib import Path
import pytest

CASES = [
 ("TC01", "Start signed out. Open Hobby Tracker then attempt protected My Hobbies navigation. Verify Login is shown with Google and email controls and no private hobby cards.", {"screen": "Login", "private_cards": 0}),
 ("TC02", "Start signed out. Tap Google, cancel the native account picker. Verify a cancellation message and Login remains visible. Then use the dedicated preconfigured Google test account A to sign in. Verify Home and its four tabs.", {"screen": "Home", "tabs": 4, "cancel_message_seen": True}),
 ("TC03", "Start signed in as A with My Hobbies open. Create a hobby named {name}, choose music icon, blue color and Interested. Confirm it appears; close and relaunch app, return to My Hobbies. Report its name and priority exactly.", {"hobby_name": "{name}", "priority": "Interested"}),
 ("TC04", "Start signed in as A. Create a hobby {name}. Attempt to create the same name in uppercase. Verify duplicate validation and retained draft; cancel then verify exactly one hobby with that case-insensitive name. No existing hobby may be overwritten.", {"matching_hobbies": 1, "duplicate_error": True, "draft_retained": True}),
 ("TC05", "Start signed in as A. Create an Interested hobby {name}. In Home add a future schedule for it, title {name}, 30 minutes. Verify schedule visible on its selected day. Change hobby priority to Active and back to Interested. Verify schedule still present.", {"schedule_count": 1, "priority": "Interested"}),
 ("TC06", "Start signed in as A. Create hobby {name}, open Hyper Mode, start and wait at least 5 seconds. Pause, record displayed active seconds, wait another 5 seconds. Verify displayed active seconds did not increase while paused. Resume for at least 3 seconds, enter note {name}, Finish once. Return Home. Verify exactly one matching history record with that note.", {"pause_did_not_count": True, "history_matches": 1, "note": "{name}"}),
 ("TC07", "Start signed in as A. Create hobby {name}, enter Hyper Mode, pause after 3 seconds and enter note {name}. Close the app and relaunch. Open Hyper Mode and verify the paused draft and exact note survive. Do not finish or clear the draft before checking.", {"draft_paused": True, "note": "{name}"}),
 ("TC08", "Start signed in as A. In Community publish a new post containing {name}. Verify the post appears and remains after relaunch. Check one like and send one comment {name}; verify both visible. Report exact post and comment text.", {"post_text": "{name}", "comment_text": "{name}", "liked": True}),
 ("TC09", "Start signed in as A. Create group {name}, open its chat and send {name}. Relaunch and reopen Chats then that group. Verify exactly one matching message. Group membership must remain.", {"group_name": "{name}", "matching_messages": 1}),
 ("TC10", "Start signed in as A. Create a future Activity titled {name}, RSVP. Verify Home has no matching schedule yet. Return to Activity, explicitly Add to Home and choose an existing hobby. Verify exactly one matching Home schedule even after another Add to Home tap.", {"before_add_count": 0, "after_add_count": 1}),
 ("TC11", "Start signed in as A. Test account B must be preconfigured visible and allow DMs; account A must opt into DMs in Settings too. Open People, select B, send {name}. Switch to B using Settings Sign Out and the dedicated native Google account picker. Open Chats and verify the same message. Do not report credentials.", {"recipient_received": True, "message_text": "{name}"}),
 ("TC12", "Start signed in as A with at least one history record. In Settings > Profile create PDF, share it through native Android share sheet and cancel safely. Upload PDF to configured test Storage. Verify progress reaches completion and a non-empty download URL is visible. Report the history count reflected in the report and whether the URL appears. Do not paste the tokenized URL.", {"pdf_created": True, "upload_complete": True, "url_visible": True}),
 ("TC13", "Start signed in as A. In Settings > Appearance save Rainy Day. Navigate through all four tabs and relaunch; verify Rainy Day remains and existing hobbies still exist. Return theme to Light when done.", {"theme_survived_relaunch": True, "hobbies_preserved": True}),
 ("TC14", "Start signed in as A on a test Firebase project where owner has set community_enabled=false and feed_limit=5. Settings > Profile > reload config. Report both visible config values; open Community and verify feature-off state. This case requires owner-configured console values before the run; do not claim pass if absent.", {"community_enabled": False, "feed_limit": 5, "community_disabled_visible": True}),
 ("TC15", "Start signed in as A. Open Settings > Notifications, grant the native Android permission. Owner sends a dedicated test FCM with data ownerId matching A and path=/home, in foreground, background and terminated states as the agent requests. Reopen inbox and verify all three unique test messages; tap one and verify Home opens. Do not expose registration tokens.", {"foreground_received": True, "background_received": True, "terminated_received": True, "tap_screen": "Home"}),
 ("TC16", "Start signed in as A. Disable network using native Android settings. Attempt to save a new hobby {name}. Verify a visible error/retry or pending state with retained draft and no fabricated success. Re-enable network and retry, verify exactly one saved matching hobby.", {"draft_retained": True, "saved_matches": 1}),
 ("TC17", "Start signed in as A with private data. Settings Sign Out: cancel first and verify same session; then confirm. Verify Login, relaunch and attempt protected hobby route. Verify no private cards. Check the test run's Logcat/DebugView capture contains the logout analytics event; do not infer it only from UI.", {"cancel_kept_session": True, "screen": "Login", "private_cards": 0, "logout_event_observed": True}),
]

pytestmark = [pytest.mark.asyncio, pytest.mark.skipif(not os.getenv("ARTEMIS_BASE_URL"), reason="BLOCKED: configure ARTEMIS_BASE_URL, Android device and dedicated Firebase test accounts")]

@pytest.mark.parametrize("run_index", [1, 2, 3])
@pytest.mark.parametrize("case_id,instruction,expected", CASES, ids=[c[0] for c in CASES])
async def test_critical_flow(case_id, instruction, expected, run_index):
    from artemis_client import ArtemisClient
    unique = f"QA {case_id} {uuid.uuid4().hex[:8]}"
    expected = {key: value.format(name=unique) if isinstance(value, str) else value for key, value in expected.items()}
    output_schema = {"checkpoint": case_id, "passed": "boolean", "observed": expected}
    client = ArtemisClient(os.environ["ARTEMIS_BASE_URL"], token=os.getenv("ARTEMIS_TOKEN"))
    result = await client.run(
        instruction.format(name=unique) + " Return JSON with checkpoint, passed and observed. Report only values actually visible/measured. If a precondition is missing, set passed=false and explain in observed; never invent evidence.",
        profile="flash", device_serial=os.getenv("ANDROID_SERIAL"), locked_app_package="vn.prm393.hobbytracker",
        expected_output=json.dumps(output_schema), enable_outputter=True, timeout=1200,
    )
    # Sanitize the persisted result: never store raw daemon logs, account hints,
    # bearer-token download URLs or authentication environment variables.
    output = result.output
    if isinstance(output, str):
        output = json.loads(output.strip().removeprefix("```json").removesuffix("```").strip())
    assert isinstance(output, dict), "Agent did not return structured output"
    observed = output.get("observed")
    assert isinstance(observed, dict), "Missing observed fields"
    comparisons = {key: observed.get(key) == value for key, value in expected.items()}
    proof = {"case": case_id, "run": run_index, "task_id": result.task_id, "status": result.status,
             "checkpoint_matches": output.get("checkpoint") == case_id,
             "agent_passed": output.get("passed") is True, "field_matches": comparisons}
    directory = Path(__file__).resolve().parents[1] / "evidence" / "08" / "artemis"
    directory.mkdir(parents=True, exist_ok=True)
    (directory / f"{case_id}-{run_index}.json").write_text(json.dumps(proof, indent=2))
    assert result.succeeded, result.error or result.status
    assert proof["checkpoint_matches"] and proof["agent_passed"] and all(comparisons.values()), proof

@pytest.mark.exploratory
@pytest.mark.skipif(os.getenv("RUN_ARTEMIS_EXPLORATORY") != "yes", reason="Requires explicit Pro exploratory session setup")
async def test_exploratory():
    from artemis_client import ArtemisClient
    client = ArtemisClient(os.environ["ARTEMIS_BASE_URL"], token=os.getenv("ARTEMIS_TOKEN"))
    result = await client.run("Spend 15–30 minutes exploring Hobby Tracker on the dedicated test project. Cover keyboard, 360dp, process restart, timer drafts, offline retry, privacy, notification permission, and share-sheet cancellation. Return JSON with minutes_spent, issues (screen/steps/expected/actual), and checked_flows. Never alter production data or enable billing.", profile="pro", device_serial=os.getenv("ANDROID_SERIAL"), locked_app_package="vn.prm393.hobbytracker", expected_output='{"minutes_spent": number, "issues": [], "checked_flows": []}', enable_outputter=True, timeout=2100)
    output = result.output if isinstance(result.output, dict) else json.loads(result.output)
    assert result.succeeded and 15 <= output["minutes_spent"] <= 30 and isinstance(output["issues"], list)
