#!/usr/bin/env python3
"""Reproducible, read-only source audit + document coverage for Hobby Tracker phase00.

Running the script writes JSON evidence under docs/evidence/00 and a snapshot of
bytes currently packaged under reference. It NEVER rewrites source references
or the historical expected-hash manifest.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
REF=ROOT/'docs/requirements/reference'
EVID=ROOT/'docs/evidence'/'00'
EVID.mkdir(parents=True,exist_ok=True)


def load(path): return (ROOT/path).read_text(encoding='utf-8')
def digest(path):
    b=path.read_bytes()
    return {'sha256': hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def unique_ids(pattern,content):
    return sorted(set(re.findall(pattern,content,re.M)))
def check_row(name,okay,detail):
    return {'check':name,'result':'PASS' if okay else 'FAIL','detail':detail}

def main():
    expected=json.loads(load('docs/requirements/reference/source-manifest.json'))
    observed=[]
    archive=[]
    for f in sorted(REF.iterdir(),key=lambda p:p.name):
        if f.is_file() and f.suffix.lower() in {'.html','.pdf','.pptx'}:
            measured=digest(f)
            archive.append({'file':f.name,**measured, 'origin':'user-uploaded Final PDF' if f.name=='PRM393 - Final Assignment One Complete System on Firebase.pdf' else 'previously bundled Lab 2/Lab 3 reference'})
    archive_files={e['file']:e for e in archive}
    for record in expected:
        file=REF/record['file']
        actual=digest(file) if file.is_file() else None
        status='MATCH' if actual and actual['sha256']==record['sha256'] and actual['bytes']==record['bytes'] else 'MISMATCH'
        observed.append({'file':record['file'], 'expected_sha256':record['sha256'],'expected_bytes':record['bytes'], 'actual_sha256':actual['sha256'] if actual else None,'actual_bytes':actual['bytes'] if actual else None,'status':status,'provenance_verified_against_original_path':False})
    mismatched=[x['file'] for x in observed if x['status']!='MATCH']
    baseline=json.loads(load('docs/evidence/00/zip-baseline.json'))
    baseline_matches=all(((REF/e['file']).is_file() and digest(REF/e['file']) == {'sha256':e['sha256'], 'bytes':e['bytes']}) for e in baseline['files'])
    (REF/'archive-manifest.json').write_text(json.dumps(archive,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (EVID/'source-integrity.json').write_text(json.dumps({'check_date':'2026-11-03','method':'SHA-256 + byte length from currently packaged files against historical expected manifest; original Windows paths are unavailable','expected_count':len(expected),'matches':len(expected)-len(mismatched),'mismatches':len(mismatched),'status':'PASS' if not mismatched else 'FAIL','files':observed},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

    mapping=load('docs/design-traceability.md')
    handoff=load('docs/design/handoff/flutter-handoff.md')
    tests=load('docs/test-plan.md')
    rubric=load('docs/rubric-checklist.md')
    design=load('docs/design/DESIGN.md')
    screen_ids=unique_ids(r'^\| (S\d{2}) \|',mapping)
    handoff_ids=unique_ids(r'^### (S\d{2})\s',handoff)
    flow_ids=unique_ids(r'^\| (F0[1-3])\b',mapping)
    comps=unique_ids(r'^\| (C\d{2}) \|',mapping)
    test_ids=unique_ids(r'^\| (TC\d{2}) \|',tests)
    rubric_ids=unique_ids(r'^\| (R\d{2}) \|',rubric)
    not_run_count=len(re.findall(r'^\| TC\d{2} \|[^\n]*\| NOT RUN \|\s*$',tests,re.M))
    theme_names=['Light','Dark','Energetic','Cyber','Art','Sad','Rainy Day']
    themes=[v for v in theme_names if re.search(r'^\| '+re.escape(v)+r' \|',design,re.M)]
    missing_links=[]
    checked_links=[]
    for f in ROOT.rglob('*.md'):
        if any(part in {'node_modules', '.dart_tool', 'build', '.git'} for part in f.relative_to(ROOT).parts):
            continue
        for raw in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)',f.read_text('utf-8')):
            uri=raw.strip().strip('<>')
            uri=uri.split('#',1)[0].split('?',1)[0]
            if not uri or '://' in uri or uri.startswith(('mailto:','data:')): continue
            if uri.startswith(('http:','https:')):continue
            from urllib.parse import unquote
            rel=unquote(uri)
            if not (f.parent/rel).exists(): missing_links.append({'from':str(f.relative_to(ROOT)),'target':raw})
            checked_links.append(str(f.relative_to(ROOT))+':'+raw)
    figma_record=json.loads(load('docs/evidence/00/figma-structure.json'))
    pages=figma_record.get('pages',[])
    old_zero= len(pages)==6 and all((p.get('reactionNodeCount') == 0 and not p.get('flowStartingPoints')) for p in pages)
    final_name='PRM393 - Final Assignment One Complete System on Firebase.pdf'
    checks=[
      {'check':'Seven historic source files match their declared original hashes', 'result':'PASS' if not mismatched else 'FAIL', 'detail':{'matched':len(expected)-len(mismatched),'total':len(expected),'mismatch_files':mismatched,'note':'This checks historical expected values, NOT inaccessible original Windows paths'}},
      check_row('Seven source bytes match original uploaded ZIP baseline',baseline_matches,{'baseline_zip_sha256':baseline['input_zip_sha256'],'files_compared':len(baseline['files']),'scope':'Original user ZIP content only, not unavailable source locations'}),
      check_row('15 route mappings and 15 handoff entries',len(screen_ids)==15 and set(screen_ids)==set(handoff_ids),{'screen_ids':screen_ids,'handoff_ids':handoff_ids}),
      check_row('3 flow mappings, 10 component families, 7 theme plans',len(flow_ids)==3 and len(comps)==10 and len(themes)==7,{'flows':flow_ids,'components':comps,'themes':themes}),
      check_row('23 unique test cases, all explicitly NOT RUN',len(test_ids)==23 and not_run_count==23,{'test_count':len(test_ids),'not_run_rows':not_run_count}),
      check_row('20 rubric rows, planning only',len(rubric_ids)==20,{'rubric_count':len(rubric_ids),'points_claim':'Weights in document; no earned score claimed'}),
      check_row('Local Markdown link paths exist',not missing_links,{'checked':len(checked_links),'broken':missing_links}),
      check_row('Final assignment PDF present for future Final work',final_name in archive_files,{'file':final_name,'source':'direct conversation attachment','scope':'reference only; Final implementation not started'}),
      {'check':'Figma audit from 2026-11-02 retained (NOT independently rerun)', 'result':'NOT REVERIFIED', 'detail':{'historical_pages':len(pages),'historical_zero_reaction_on_all_pages':old_zero,'2026-11-03_access':'BLOCKED: Figma reports missing Editor access','status':'historical observation, not current Figma acceptance'}},
      {'check':'Flutter/Firebase/ARTEMIS runtime', 'result':'NOT RUN', 'detail':'No pubspec.yaml / lib or app for executing; no real device/project evidence'}
    ]
    (EVID/'document-validation.json').write_text(json.dumps({'check_date':'2026-11-03','scope':'Phase00 document/static only; no app built, no Figma live verification','checks':checks,'phase_status':'PARTIAL / REVIEW READY','manual_blockers':['D05/G12: verify three source HTML files or approved provenance change','D01: Figma access, 3 prototype flows/recovery, lecturer approval','Detailed handoff/design review'], 'note':'Former 2026-11-02 PASS snapshot retained separately; verified coverage does not certify runtime behavior or original source authenticity'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'phase':'PARTIAL','sources':f'{len(expected)-len(mismatched)}/{len(expected)} historic hashes match','mismatched':mismatched,'screen_handoff':f'{len(screen_ids)}/{len(handoff_ids)}','flows':len(flow_ids),'components':len(comps),'themes':len(themes),'tests':len(test_ids),'test_rows_not_run':not_run_count,'rubric_rows':len(rubric_ids),'local_links_checked':len(checked_links),'broken_links':missing_links,'final_reference_copied':final_name in archive_files,'f_legacy_pages':len(pages)},ensure_ascii=False,indent=2))
    non_hash_failures=[c['check'] for c in checks if c['result']=='FAIL' and not c['check'].startswith('Seven historic')]
    if non_hash_failures:
        print('Structural validation failures:',non_hash_failures,file=sys.stderr)
        return 2
    return 1 if mismatched else 0  # 1 means archive != historical source hashes; see JSON evidence.

if __name__=='__main__': raise SystemExit(main())
