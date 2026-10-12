import argparse
import json
import os
import shutil
from pathlib import Path
import subprocess
import time


def environment():
    result = {}
    seen = set()
    for key, value in os.environ.items():
        if key.casefold() not in seen:
            result[key] = value
            seen.add(key.casefold())
    return result


def read(path):
    return path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=('link', 'test'))
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--runtime', type=Path)
    parser.add_argument('--mod', default='pmflex')
    parser.add_argument('--combined', action='store_true')
    parser.add_argument('--standard', action='store_true')
    parser.add_argument('--repeat', action='store_true')
    parser.add_argument('--offline', action='store_true')
    args = parser.parse_args()
    root = args.root.resolve()
    flags = subprocess.CREATE_NO_WINDOW
    if args.mode == 'link':
        with (root / 'linker.log').open('w') as output, (root / 'linker-errors.log').open('w') as errors:
            result = subprocess.run([str(root / 'tools/bin/linker_pc.exe'), '-language', 'english',
                                     '-compress', '-cleanup', 'mod', '-verbose'],
                                    cwd=root / 'tools/bin', env=environment(), creationflags=flags,
                                    stdout=output, stderr=errors, timeout=45)
        return result.returncode
    runtime = args.runtime.resolve() if args.runtime else root / 'game'
    mod = runtime / 'mods' / args.mod
    logs = [mod / 'console_mp.log', mod / 'games_mp.log']
    for log in logs:
        log.write_text('')
    command = [str(runtime / 'iw3mp.exe'), '+set', 'dedicated', '1', '+set', 'net_ip', '127.0.0.1',
               '+set', 'net_port', '28979', '+set', 'fs_basepath', str(runtime), '+set', 'fs_homepath', str(runtime),
               '+set', 'fs_game', 'mods/' + args.mod, '+set', 'sv_punkbuster', '0',
               '+set', 'promod_mode', 'custom_public_lan', '+set', 'g_gametype', 'sd', '+set', 'promod_economy', '1', '+set', 'repeat_smoke', '0', '+set', 'profile_smoke', '0', '+set', 'economy_smoke', '1',
               '+set', 'logfile', '2', '+set', 'g_log', 'games_mp.log', '+set', 'g_logSync', '1', '+map', 'mp_crash']
    if args.offline:
        command[1:1] = ['+set', 'net_noudp', '1', '+set', 'net_noipx', '1', '+set', 'cl_punkbuster', '0']
    if args.combined:
        command[1:1] = ['+set', 'ui_flat_loadout', '1', '+set', 'ui_flat_rules', '1', '+set', 'combined_smoke', '1']
    if args.standard:
        command[1:1] = ['+exec', 'standard.cfg']
        for setting, value in [('economy_smoke', '0'), ('promod_economy', '0'), ('profile_smoke', '1')]:
            command[command.index(setting) + 1] = value
    if args.repeat:
        command[1:1] = ['+set', 'ui_flat_loadout', '1', '+set', 'ui_flat_rules', '1']
        for setting, value in [('economy_smoke', '0'), ('repeat_smoke', '1')]:
            command[command.index(setting) + 1] = value
    marker = 'REPEAT_TEST' if args.repeat else 'PROFILE_TEST' if args.standard else 'ECONOMY_TEST'
    passed = False
    udp_endpoints = None
    message = 'Timed out waiting for economy validation.'
    with (root / 'server-output.log').open('w') as output:
        process = subprocess.Popen(command, cwd=runtime, env=environment(), creationflags=flags,
                                   stdout=output, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 55
            while time.monotonic() < deadline:
                console, game_log = map(read, logs)
                if 'script compile error' in console or 'script runtime error' in console:
                    message = 'CoD4 reported a script error.'
                    break
                if marker + ';FAILED' in game_log:
                    failure = next(line.strip() for line in game_log.splitlines() if marker + ';FAILED' in line)
                    message = 'An economy assertion failed: ' + failure
                    break
                if marker + ';PASSED' in game_log:
                    passed = True
                    message = 'Repeat-buy runtime checks passed.' if args.repeat else 'Standard/profile-switch runtime checks passed.' if args.standard else 'Economy runtime checks passed.'
                    if args.offline:
                        rows = subprocess.check_output(['netstat', '-ano', '-p', 'UDP'], creationflags=flags).decode(errors='replace').splitlines()
                        udp_endpoints = sum(row.strip().startswith('UDP') and row.split()[-1] == str(process.pid) for row in rows)
                        if udp_endpoints:
                            passed = False
                            message = 'Offline runtime opened a UDP endpoint.'
                    break
                if process.poll() is not None:
                    message = 'CoD4 exited before validation completed.'
                    break
                time.sleep(0.5)
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
            for log in logs:
                shutil.copyfile(log, root / log.name)
    result = {'checkedAt': time.strftime('%Y-%m-%dT%H:%M:%S%z'), 'passed': passed, 'message': message,
              'offline': args.offline, 'udpEndpointCount': udp_endpoints,
              'scope': 'Native purchases, automatic next-round replay, priority/funds, opt-out and tactical persistence.' if args.repeat else 'Native stock menus, free optics, disabled purchases and profile switches across map restart.' if args.standard else 'Dedicated CoD4 server, test clients, economy transactions, round persistence and class ownership.'}
    (root / 'test-result.json').write_text(json.dumps(result, indent=2))
    print(message)
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
