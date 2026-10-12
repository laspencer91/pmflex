import argparse
import json
import os
from pathlib import Path
import socket
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
    return path.read_text(errors='replace') if path.exists() else ''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--runtime', required=True, type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    runtime = args.runtime.resolve()
    expected = Path(__file__).resolve().parent.parent / 'build/ui-learning/game-economy-local-server'
    if runtime != expected.resolve():
        parser.error('Use the dedicated local economy test runtime.')
    mod = runtime / 'mods/pmflex'
    logs = [mod / 'console_mp.log', mod / 'games_mp.log']
    for path in logs:
        path.write_text('')
    port = 28963 if args.check else 28961
    command = [str(runtime / 'iw3mp.exe'), '+set', 'net_noudp', '0', '+set', 'net_noipx', '1',
               '+set', 'net_ip', '127.0.0.1', '+set', 'net_port', str(port), '+set', 'dedicated', '1',
               '+set', 'fs_basepath', str(runtime), '+set', 'fs_homepath', str(runtime),
               '+set', 'fs_game', 'mods/pmflex', '+exec', 'local-economy-test.cfg',
               '+set', 'economy_manual_smoke', '1' if args.check else '0', '+map', 'mp_crash']
    process = None
    passed = False
    udp_ready = False
    message = 'Local server did not become ready.'
    with (runtime / 'local-server-output.log').open('w') as output:
        process = subprocess.Popen(command, cwd=runtime, env=environment(), creationflags=subprocess.CREATE_NO_WINDOW,
                                   stdout=output, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 60
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as query:
                query.settimeout(0.3)
                while time.monotonic() < deadline:
                    console, game_log = map(read, logs)
                    if 'script compile error' in console or 'script runtime error' in console or 'LOCAL_ECONOMY_TEST;FAILED' in game_log:
                        message = 'Local test reported an error. See the runtime logs.'
                        break
                    if not udp_ready:
                        query.sendto(b'\xff\xff\xff\xffgetstatus\n', ('127.0.0.1', port))
                        try:
                            packet, _ = query.recvfrom(8192)
                            udp_ready = packet.startswith(b'\xff\xff\xff\xffstatusResponse')
                        except (socket.timeout, ConnectionResetError):
                            pass
                    marker = 'LOCAL_ECONOMY_TEST;PASSED' if args.check else 'LOCAL_ECONOMY_TEST;READY'
                    if udp_ready and marker in game_log:
                        passed = True
                        message = 'Local test checks passed.' if args.check else f'Local server ready on 127.0.0.1:{port} (PID {process.pid}).'
                        break
                    if process.poll() is not None:
                        message = 'Local server exited before becoming ready.'
                        break
                    time.sleep(0.2)
        finally:
            if (args.check or not passed) and process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
    if args.check:
        result = {'checkedAt': time.strftime('%Y-%m-%dT%H:%M:%S%z'), 'passed': passed,
                  'message': message, 'loopbackStatusResponse': udp_ready, 'port': port}
        (runtime / 'local-test-result.json').write_text(json.dumps(result, indent=2))
        evidence = '\n'.join(line for line in read(logs[1]).splitlines() if 'LOCAL_ECONOMY_TEST;' in line)
        (runtime / 'local-check-evidence.log').write_text(evidence + '\n')
    print(message)
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
