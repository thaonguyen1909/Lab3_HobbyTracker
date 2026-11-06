"""Apply the reviewed bridge to the original Flutter source, without overwriting edits."""
from pathlib import Path
import hashlib,json,sys,shutil
base=Path(__file__).resolve().parent
if len(sys.argv)!=2: raise SystemExit('python tools/integration/apply_mobile_bridge.py /path/to/HobbyTracker')
target=Path(sys.argv[1]).resolve()
manifest=json.loads((base/'mobile-baseline-sha256.json').read_text())
for rel,expected in manifest.items():
 p=target/rel;new=base/'mobile'/rel
 if not p.is_file():raise SystemExit(f'Missing source: {rel}')
 current=hashlib.sha256(p.read_bytes()).hexdigest()
 if current not in [expected,hashlib.sha256(new.read_bytes()).hexdigest()]:raise SystemExit(f'User changes detected: {rel}. Merge manually; no files changed.')
for rel in manifest:
 p=target/rel;backup=p.with_suffix(p.suffix+'.pre-admin')
 if not backup.exists():shutil.copy2(p,backup)
 shutil.copyfile(base/'mobile'/rel,p)
print('Bridge installed. Run flutter analyze and flutter test before building an APK.')
