#!/usr/bin/env python3
"""Opt-in native black-box acceptance; owns only its temporary server and fixture."""
import argparse
import http.server
import json
import os
import shutil
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import time
import urllib.request
import urllib.error


def port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--server-bin', required=True, type=Path)
    parser.add_argument('--simulator', required=True)
    parser.add_argument('--flutter', default='flutter', help='Flutter executable on PATH, or an absolute path')
    parser.add_argument('--consumer', type=Path, help='Example copy resolving the exact public package')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    flutter = shutil.which(args.flutter)
    if flutter is None: parser.error('Flutter executable not found; pass --flutter /path/to/flutter')
    repo = Path(__file__).resolve().parents[2]
    output = args.output or Path(tempfile.mkdtemp(prefix='wk-flutter-stream-'))
    output.mkdir(parents=True, exist_ok=True)
    simctl = ['xcrun', 'simctl']
    example = args.consumer or repo / 'example'
    native = output / 'stream-acceptance'
    native.mkdir(exist_ok=True)
    app_process = None
    api, raft, ws, model_port, proxy_port = port(), port(), port(), port(), port()
    metrics = {'calls': [], 'cancelled': 0, 'history_reads': 0, 'eventsync_reads': 0}

    class Fixture(http.server.BaseHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'

        def log_message(self, *_):
            pass

        def do_GET(self):
            data = json.dumps(metrics).encode()
            self.send_response(200); self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(data))); self.end_headers(); self.wfile.write(data)

        def do_POST(self):
            size = int(self.headers.get('Content-Length', '0'))
            if size > 131072:
                self.send_error(413)
                return
            request = json.loads(self.rfile.read(size))
            if self.path == '/acceptance':
                if 'phase' in request: (native / 'phase.txt').write_text(request['phase'])
                if 'report' in request: (native / 'report.json').write_text(json.dumps(request['report'], ensure_ascii=False))
                self.send_response(200); self.send_header('Content-Length', '2'); self.end_headers(); self.wfile.write(b'{}')
                return
            model = request.get('model', '')
            # Record structural evidence only, never headers, credentials or prompts.
            metrics['calls'].append({'model': model, 'roles': [m['role'] for m in request.get('messages', [])]})
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Connection', 'close')
            self.end_headers()
            self.close_connection = True

            def packet(delta):
                value = json.dumps({'choices': [{'index': 0, 'delta': {'content': delta}}]}, ensure_ascii=False)
                data = ('data: ' + value + '\r\n\r\n').encode()
                # Split UTF-8 and SSE delimiters across network writes.
                for i in range(0, len(data), 3):
                    self.wfile.write(data[i:i + 3])
                    self.wfile.flush()
                time.sleep(0.08)
            try:
                if model == 'fixture-error':
                    packet('保留部分内容🙂')
                    self.wfile.write(b'data: {"error":{"message":"private upstream body"}}\n\n')
                elif model == 'fixture-truncated':
                    packet('断流前内容')
                elif model == 'fixture-slow':
                    for _ in range(300):
                        packet('慢🙂')
                    self.wfile.write(b'data: [DONE]\n\n')
                else:
                    for chunk in ['模型回复', '🙂，', '分段到达。']:
                        packet(chunk)
                    # A valid multiline JSON SSE event and an explicit terminal marker.
                    self.wfile.write(b'data: {"choices":\ndata: [{"index":0,"delta":{},"finish_reason":"stop"}]}\n\ndata: [DONE]\n\n')
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                metrics['cancelled'] += 1

    class ProductProxy(http.server.BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def forward(self):
            if self.path.startswith('/channel/messagesync'):
                metrics['history_reads'] += 1
            if self.path.startswith('/message/eventsync'):
                metrics['eventsync_reads'] += 1
            body = None
            if self.command == 'POST':
                body = self.rfile.read(int(self.headers.get('Content-Length', '0')))
            request = urllib.request.Request(f'http://127.0.0.1:{api}' + self.path, data=body,
                                             headers={'Content-Type': 'application/json'}, method=self.command)
            try:
                response = urllib.request.urlopen(request, timeout=15)
            except urllib.error.HTTPError as error:
                response = error
            with response:
                data = response.read(2 * 1024 * 1024)
                self.send_response(response.status); self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(data))); self.end_headers(); self.wfile.write(data)

        do_GET = forward
        do_POST = forward

    proxy = http.server.ThreadingHTTPServer(('127.0.0.1', proxy_port), ProductProxy)
    threading.Thread(target=proxy.serve_forever, daemon=True).start()
    fixture = http.server.ThreadingHTTPServer(('127.0.0.1', model_port), Fixture)
    threading.Thread(target=fixture.serve_forever, daemon=True).start()
    config = output / 'wukongim.toml'
    config.write_text(f'''[node]
id = 1
data_dir = "{output}/data"
[cluster]
id = "flutter-stream-acceptance"
listen_addr = "127.0.0.1:{raft}"
nodes = [{{id = 1, addr = "127.0.0.1:{raft}"}}]
initial_slot_count = 8
hash_slot_count = 256
slot_replica_n = 1
[api]
listen_addr = "127.0.0.1:{api}"
external_ws_addr = "ws://127.0.0.1:{ws}"
[manager]
listen_addr = "127.0.0.1:0"
[gateway]
token_auth_on = true
listeners = [{{name = "ws", network = "websocket", address = "127.0.0.1:{ws}", transport = "gnet", protocol = "wsmux"}}]
[log]
level = "warn"
dir = "{output}/logs"
''')
    environment = {k: v for k, v in os.environ.items() if not k.startswith('WK_')}
    server_log = (output / 'server.log').open('w')
    server = subprocess.Popen([str(args.server_bin.resolve()), '-config', str(config)], cwd=output,
                              env=environment, stdout=server_log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 45
        while True:
            try:
                with urllib.request.urlopen(f'http://127.0.0.1:{api}/readyz', timeout=1) as response:
                    if response.status == 200:
                        break
            except Exception:
                if time.monotonic() > deadline or server.poll() is not None:
                    raise RuntimeError('Temporary cluster did not become ready; inspect server.log')
                time.sleep(0.1)
        app_log = (output / 'flutter-run.log').open('w')
        flutter_env = dict(os.environ)
        app_process = subprocess.Popen([flutter, 'run', '--debug', '-d', args.simulator,
            '--dart-define=STREAM_ACCEPTANCE_API=http://127.0.0.1:' + str(proxy_port),
            '--dart-define=STREAM_ACCEPTANCE_MODEL=http://127.0.0.1:' + str(model_port)],
            cwd=example, env=flutter_env, stdout=app_log, stderr=subprocess.STDOUT, stdin=subprocess.PIPE)
        deadline = time.monotonic() + 600
        captured = set()
        while time.monotonic() < deadline:
            phase_file = native / 'phase.txt'
            if phase_file.exists():
                phase = phase_file.read_text().strip()
                if phase not in captured and phase in {'partial', 'completed', 'recovered', 'model'}:
                    subprocess.run(simctl + ['io', args.simulator, 'screenshot', str(output / (phase + '.png'))], check=True, capture_output=True)
                    captured.add(phase)
            if (native / 'report.json').exists(): break
            time.sleep(0.1)
        if not (native / 'report.json').exists():
            raise RuntimeError('Native acceptance timed out')
        report_file = output / 'stream-acceptance/report.json'
        report = json.loads(report_file.read_text())
        report['environment']['sdk_revision'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
        report['environment']['sdk_worktree_dirty'] = bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo, text=True).strip())
        report['environment']['simulator'] = args.simulator
        report['environment']['dependency_origin'] = 'pub.dev exact consumer' if args.consumer else 'source path'
        version = subprocess.check_output([flutter, '--version', '--machine'], cwd=example, env=flutter_env, text=True)
        report['environment']['flutter_version'] = json.loads(version)['frameworkVersion']
        deadline = time.monotonic() + 3
        while metrics['cancelled'] < 1 and time.monotonic() < deadline:
            time.sleep(0.1)
        report['fixture'] = metrics
        context_verified = any('assistant' in c['roles'] and c['roles'][-1:] == ['user'] for c in metrics['calls'])
        if context_verified:
            report['checks'].append('fixture confirms multi-turn context')
        report['passed'] = report['passed'] and metrics['cancelled'] >= 1 and metrics['eventsync_reads'] == 0 and metrics['history_reads'] == 3 and context_verified
        if metrics['history_reads'] == 3: report['checks'].append('one history read per connection; no online polling')
        report_file.write_text(json.dumps(report, indent=2, ensure_ascii=False))
        print(json.dumps({'passed': report['passed'], 'artifacts': str(output)}, ensure_ascii=False))
        if not report['passed']:
            raise RuntimeError('Acceptance failed; inspect report.json')
    finally:
        proxy.shutdown(); proxy.server_close()
        fixture.shutdown(); fixture.server_close()
        if app_process is not None:
            app_process.terminate()
            try: app_process.wait(timeout=10)
            except subprocess.TimeoutExpired: app_process.kill(); app_process.wait()
            app_log.close()
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill(); server.wait()
        server_log.close()


if __name__ == '__main__':
    main()
