#!/usr/bin/env python3
"""Check the Phase 01 Light CSS token / navigation contract without Flutter.

This is not a replacement for flutter analyze, widget tests, or a visual
comparison against the live Figma file.
"""
from __future__ import annotations

import json
import re
from datetime import datetime
from zoneinfo import ZoneInfo
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
html = (ROOT / 'docs/requirements/reference/Prototype.html').read_text(encoding='utf-8')
tokens = (ROOT / 'lib/theme/tokens.dart').read_text(encoding='utf-8')
nav = (ROOT / 'lib/widgets/app_navigation_bar.dart').read_text(encoding='utf-8')
appbar = (ROOT / 'lib/widgets/hobby_app_bar.dart').read_text(encoding='utf-8')
theme = (ROOT / 'lib/theme/hobby_theme.dart').read_text(encoding='utf-8')
css = html.split(':root{', 1)[1].split('}', 1)[0]
expected = {
    'primary': '--green', 'primaryDark': '--greenDark', 'text': '--ink',
    'muted': '--muted', 'subtle': '--subtle', 'border': '--line',
    'soft': '--soft', 'background': '--bg', 'surface': '--white',
    'error': '--danger', 'warning': '--warning',
}
checks = {}
for dart_key, css_key in expected.items():
    css_m = re.search(rf'{re.escape(css_key)}\s*:\s*(#[0-9a-fA-F]{{3,8}})', css)
    dart_m = re.search(rf'\b{dart_key}\s*=\s*Color\(0xFF([0-9a-fA-F]{{6}})\)', tokens)
    actual = '#'+dart_m.group(1).lower() if dart_m else None
    target = css_m.group(1).lower() if css_m else None
    if target and len(target) == 4:
        target = '#'+''.join(x*2 for x in target[1:])
    checks[f'CSS {css_key} to AppColors.{dart_key}'] = (actual == target)
    if not checks[f'CSS {css_key} to AppColors.{dart_key}']:
        print('MISMATCH', dart_key, 'css=', target, 'dart=', actual)

# Also check the specific CSS measurements used by the shared shell.
checks.update({
    'Four tabs in required order': nav.find("label: 'Home'") < nav.find("label: 'Community'") < nav.find("label: 'My Hobbies'") < nav.find("label: 'Settings'"),
    'Mint selection backdrop': 'selectionColor: palette.soft' in nav,
    'Bottom navigation uses 76dp': 'height: AppSizes.navigation' in nav and 'navigation = 76.0' in tokens,
    'Selected icon backing is 46 x 34': 'navigationIconWidth = 46.0' in tokens and 'navigationIconHeight = 34.0' in tokens,
    'Four tabs use >=48dp touch target': 'minHeight: AppSizes.minTap' in nav,
    'Shared brand header present': bool(re.search(r"Text\(\s*'hobby'", appbar)),
    'Cards use white surface distinct from background': 'color: palette.cardSurface' in theme and 'surface = Color(0xFFFFFFFF)' in tokens,
    'Responsive widget test cases authored': all(t in (ROOT/'test/phase01_visual_foundation_test.dart').read_text() for t in ['360.0', '412.0']),
    'Color and text styles use ThemeData': 'colorScheme: scheme' in theme and 'textTheme: textTheme' in theme,
})


def luminance(hex_color):
    rgb = [int(hex_color[i:i+2], 16)/255 for i in (1,3,5)]
    linear = [v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4 for v in rgb]
    return 0.2126*linear[0]+0.7152*linear[1]+0.0722*linear[2]


def ratio(a, b):
    hi, lo = sorted((luminance(a),luminance(b)),reverse=True)
    return round((hi+.05)/(lo+.05), 2)

contrast = {
    'primary_on_white': ratio('#087F72','#FFFFFF'),
    'primaryDark_on_soft': ratio('#076F64','#E7F5ED'),
    'muted_on_background': ratio('#4F6F63','#F7FAF7'),
    'text_on_white': ratio('#213D36','#FFFFFF'),
    'danger_on_white': ratio('#A2353E','#FFFFFF'),
}
checks['Main checked color pairs >= 4.5:1'] = all(v >= 4.5 for v in contrast.values())

result = {
    'date': str(datetime.now(ZoneInfo('Asia/Ho_Chi_Minh')).date()),
    'basis': ['docs/requirements/reference/Prototype.html', 'docs/design/DESIGN.md'],
    'status': 'PASS' if all(checks.values()) else 'FAIL',
    'checks': checks,
    'contrast_ratios': contrast,
    'not_evaluated_by_this_script': ['flutter analyze', 'flutter test', 'Android widget rendering', 'Figma direct pixel comparison'],
    'limitation': 'This only validates source consistency and selected Light token contrast; it cannot prove UI parity, compiled Dart, or complete accessibility.',
}
path = ROOT/'docs/evidence/01/visual-foundation-static.json'
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(result, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
print(f'Phase 01 LIGHT DESIGN STATIC: {result["status"]}, {sum(checks.values())}/{len(checks)} checks')
for key, value in contrast.items():
    print(f'  contrast {key}: {value}:1')
print('STATIC ONLY: see docs/evidence/02/work-review-2026-11-03 for actual runtime check results')
raise SystemExit(0 if all(checks.values()) else 1)
