#!/usr/bin/env python3
"""Start/stop the real jar twice against an isolated file H2 database."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.request

root = Path(__file__).resolve().parents[1]
java = str(Path(os.environ['JAVA_HOME']) / 'bin/java') if os.environ.get('JAVA_HOME') else 'java'
jar = root / 'backend/target/foodmarks-api-0.1.0.jar'
port = os.environ.get('TEST_PORT', '18080')
base = f'http://127.0.0.1:{port}/api'

def request(path, data=None, method='GET'):
    payload = None if data is None else json.dumps(data).encode()
    req = urllib.request.Request(base + path, data=payload, method=method, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=2) as response:
        body = response.read()
        return json.loads(body) if body else None

with tempfile.TemporaryDirectory(prefix='foodmarks-persistence-') as directory:
    log = open(Path(directory) / 'server.log', 'w+')
    def start():
        process = subprocess.Popen([java, '-jar', str(jar), f'--server.port={port}',
            f'--spring.datasource.url=jdbc:h2:file:{directory}/db;DB_CLOSE_ON_EXIT=FALSE', '--app.google-key='], stdout=log, stderr=log)
        for _ in range(80):
            if process.poll() is not None: break
            try:
                request('/status')
                return process
            except Exception: time.sleep(.25)
        process.terminate(); process.wait(timeout=10)
        log.seek(0)
        raise RuntimeError(log.read())
    def stop(process):
        process.terminate()
        process.wait(timeout=15)
    p = start()
    try:
        bookmark = request('/bookmarks', {'title': '재시작 확인', 'snsUrl': 'https://instagram.com/',
            'description': 'file H2 persistence', 'tags': ['테스트'], 'address': '서울 중구 세종대로 110',
            'placeId': 'demo-seoul-cityhall'}, 'POST')
    finally: stop(p)
    p = start()
    try:
        restored = request('/bookmarks')
        assert len(restored) == 1 and restored[0]['id'] == bookmark['id'], restored
        assert restored[0]['tags'] == ['테스트'] and restored[0]['title'] == '재시작 확인', restored
        request('/bookmarks/' + bookmark['id'], method='DELETE')
        assert request('/bookmarks') == []
        print('PASS: create → stop JVM → restart JVM → same record/tags → delete')
    finally: stop(p)
