#!/usr/bin/env python3
"""Source consistency check only. NOT a Dart compiler or an Android test."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
errors = []
manifest = (root / 'pubspec.yaml').read_text(encoding='utf-8')
if not re.search(r'^name:\s*hobby_tracker\s*$', manifest, re.M):
    errors.append('pubspec.yaml: unexpected package name')
for dep in ('flutter_riverpod', 'go_router'):
    if not re.search(r'^  ' + dep + r':', manifest, re.M): errors.append('missing: ' + dep)
paths = [
    'lib/main.dart','lib/app.dart','lib/theme/tokens.dart','lib/theme/hobby_theme.dart',
    'lib/app/router/app_router.dart','lib/app/router/route_paths.dart',
    'lib/viewmodels/feature_shell_view_model.dart', 'lib/services/feature_catalog_service.dart',
    'docs/architecture.md', 'test/router_test.dart', 'test/theme_test.dart',
    'test/widget_components_test.dart'
]
for file in paths:
    if not (root / file).is_file(): errors.append(f'missing {file}')
router = (root/'lib/app/router/app_router.dart').read_text(encoding='utf-8')
routes = (root/'lib/app/router/route_paths.dart').read_text(encoding='utf-8')
expected = [
    '/auth/login','/auth/register','/auth/forgot-password','/home','/home/hyper',
    '/hobbies','/community/feed','/community/groups','/community/activities',
    '/community/people','/community/chats','/settings',
]
for route in expected:
    if route not in routes and route not in router: errors.append(f'route missing from source: {route}')
for route in ('/community/chat/:id', "path: ':id'", "path: ':section'"):
    if route not in router: errors.append(f'param pattern absent: {route}')
for name in ('HomeScreen','HyperScreen','HobbiesScreen','HobbyDetailScreen','FeedScreen',
    'GroupsScreen','ActivitiesScreen','PeopleScreen','ChatsScreen','ConversationScreen',
    'SettingsScreen','SettingsDetailScreen','LoginScreen','RegisterScreen','ForgotPasswordScreen'):
    if name not in router: errors.append(f'not mapped: {name}')
if router.count('StatefulShellBranch(') != 4: errors.append('Expected 4 StatefulShellBranch entries')
widgets = ['hobby_button.dart', 'hobby_text_field.dart', 'hobby_card.dart',
    'app_navigation_bar.dart', 'hobby_app_bar.dart', 'hobby_dialog.dart',
    'async_states.dart', 'hobby_checkbox.dart']
for file in widgets:
    if not (root/'lib/widgets'/file).is_file(): errors.append('missing widgets/'+file)
for source in (root/'lib').rglob('*.dart'):
    contents = source.read_text(encoding='utf-8')
    if source.parent.name in ('screens', 'widgets') and re.search(r'Firebase(Auth|Analytics|Crashlytics|Messaging|RemoteConfig)\.instance|firebase_\w+', contents):
        errors.append('UI imports SDK: ' + str(source.relative_to(root)))
print(f'Phase 01 STATIC: {"PASS" if not errors else "FAIL"}; {len(list((root/"lib").rglob("*.dart")))} Dart source files, {len(list((root/"test").rglob("*.dart")))} Dart test files')
for e in errors: print('ERROR:', e)
print('STATIC ONLY: see docs/evidence/02/work-review-2026-11-03 for actual runtime check results')
sys.exit(1 if errors else 0)
