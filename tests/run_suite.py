"""Run current Godot smoke tests with independent, disposable user-data directories."""
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN'))
    parser.add_argument('--timeout', type=float, default=60)
    parser.add_argument('--jobs', type=int, default=2)
    parser.add_argument('--filter', default='')
    args = parser.parse_args()
    portable = ROOT.parent / '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
    executable = args.godot or (str(portable) if portable.exists() else shutil.which('godot') or shutil.which('godot4'))
    if not executable:
        parser.error('Godot not found; provide --godot or GODOT_BIN')
    storage = ROOT.parent / '.tools/test_runs'
    storage.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix='smoke_', dir=storage))
    scripts = sorted(p for p in (ROOT / 'tests').glob('*smoke.gd') if args.filter in p.name)
    if not scripts:
        parser.error('No matching smoke tests')

    def run(script):
        isolated = run_dir / script.stem
        isolated.mkdir()
        env = os.environ.copy()
        for key, subdir in [('APPDATA', 'appdata'), ('LOCALAPPDATA', 'localappdata'), ('XDG_DATA_HOME', 'xdg')]:
            folder = isolated / subdir
            folder.mkdir()
            env[key] = str(folder)
        start = time.monotonic()
        timed_out = False
        code = None
        try:
            process = subprocess.run([executable, '--headless', '--path', str(ROOT), '--script', f'res://tests/{script.name}'],
                                     cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=args.timeout)
            output = process.stdout + process.stderr
            code = process.returncode
        except subprocess.TimeoutExpired as exc:
            timed_out = True
            output = ''.join(v.decode('utf-8', 'replace') if isinstance(v, bytes) else (v or '') for v in [exc.stdout, exc.stderr])
        error = bool(re.search(r'SCRIPT ERROR|Parse Error|Assertion failed|Failed to load script|Shader compilation failed', output, re.I))
        passed = code == 0 and not timed_out and not error and bool(re.search(r'\bPASS\b', output))
        (isolated / 'output.log').write_text(output, encoding='utf-8')
        return {'test': script.name, 'passed': passed, 'exit_code': code, 'timeout': timed_out,
                'seconds': round(time.monotonic()-start, 2), 'log': str(isolated / 'output.log')}

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, min(args.jobs, 2))) as pool:
        for result in pool.map(run, scripts):
            results.append(result)
            print(('PASS' if result['passed'] else 'FAIL') + ' ' + result['test'] + ' ' + str(result['seconds']) + 's', flush=True)
    (run_dir / 'summary.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print(f'{sum(r["passed"] for r in results)}/{len(results)} passed; logs: {run_dir}', flush=True)
    return 0 if all(r['passed'] for r in results) else 1

if __name__ == '__main__':
    sys.exit(main())
