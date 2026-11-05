#!/usr/bin/env python3
"""Static contract audit only; NOT a Dart compilation or Firebase E2E test."""
from pathlib import Path
import re, json, sys
root=Path(__file__).resolve().parents[1]
checks={}
def file(p): return (root/p).exists()
def text(p): return (root/p).read_text(encoding='utf-8')
checks['Phase02 service boundary present']=all(file(p) for p in [
  'lib/models/auth_user.dart','lib/services/auth_service.dart',
  'lib/services/auth_service_provider.dart','lib/firebase/firebase_auth_service.dart',
  'lib/viewmodels/auth_view_model.dart'])
checks['Login/Register/Forgot screens']=all(x in text('lib/features/auth/screens/auth_screens.dart') for x in ['class LoginScreen','class RegisterScreen','class ForgotPasswordScreen'])
router=text('lib/app/router/app_router.dart')
checks['Router state protection']=all(x in router for x in ['redirect:', 'authSessionProvider','auth.isLoading', 'auth.hasError','RoutePaths.login','RoutePaths.home'])
checks['Four navigation branches preserved']=router.count('StatefulShellBranch(')==4
checks['Google, email, register, reset, explicit linking, logout']=all(x in text('lib/firebase/firebase_auth_service.dart') for x in ['signInWithGoogle','signInWithEmail','registerWithEmail','sendPasswordReset','linkGoogleToCurrentAccount','signOut'])
checks['Profile create atomic transaction']=all(x in text('lib/firebase/firebase_auth_service.dart') for x in ['runTransaction','transaction.get(doc)','transaction.set(doc'])
rules=text('firebase/firestore.rules')
checks['Firestore deny-by-default + owner restriction']=all(x in rules for x in ['isOwner(uid)',"request.resource.data.role == 'user'",'allow list: if false','allow delete: if false','allow read, write: if false'])
checks['No open Security Rule']=not re.search(r'allow\s+\w+(?:,\s*\w+)*\s*:\s*if\s+true',rules)
checks['Tests authored']=all(x in text('test/router_test.dart') for x in ['Unauthenticated deep link','Sign out requires confirmation','Google cancellation','Register rejects','Forgot password','Firestore profile failure'])
checks['Setup instructions']=file('scripts/setup_phase02_windows.ps1') and file('scripts/setup_phase02_windows.md')
checks['No Firebase SDK import in views/widgets']=True
for p in (root/'lib').rglob('*.dart'):
 if '/screens/' in str(p) or '/widgets/' in str(p):
  if re.search(r'^import\s+["\']package:(firebase_|cloud_firestore|google_sign_in)',p.read_text(encoding='utf-8'),re.M):checks['No Firebase SDK import in views/widgets']=False
checks['Every relative Dart import exists']=True
missing=[]
for p in (root/'lib').rglob('*.dart'):
 for target in re.findall(r'^import\s+[\'\"]([^\'\"]+)[\'\"]',p.read_text(encoding='utf-8'),re.M):
  if target.startswith(('package:','dart:')):continue
  if not (p.parent/target).resolve().is_file():missing.append(f'{p.relative_to(root)}: {target}')
checks['Every relative Dart import exists']=not missing
try:
 import yaml
 conf=yaml.safe_load(text('pubspec.yaml'))
 deps=conf['dependencies']
 checks['Pinned Firebase deps']=all(x in deps for x in ['firebase_core','firebase_auth','cloud_firestore','google_sign_in'])
except Exception:
 checks['Pinned Firebase deps']=False
out={'status':'PASS' if all(checks.values()) else 'FAIL','checks':checks,'broken_imports':missing,
 'not_evaluated_by_this_script':['flutter analyze','flutter test','flutter run','Google picker','Firebase Console','Firestore Emulator'],
 'limitations':'Static source checks do not validate Dart types, SDK resolution, Firebase rules semantics or runtime.'}
p=root/'docs/evidence/02/static-verification.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(out,indent=2,ensure_ascii=False)+'\n')
print(f'Phase02 STATIC: {out["status"]} {sum(checks.values())}/{len(checks)} checks')
for k,v in checks.items():print(('OK ' if v else 'FAIL ')+k)
print('STATIC ONLY: see docs/evidence/02/work-review-2026-11-03 for actual runtime check results')
sys.exit(0 if all(checks.values()) else 1)
