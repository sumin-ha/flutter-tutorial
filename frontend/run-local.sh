#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:8081 -sTCP:LISTEN >/dev/null 2>&1; then
  printf '%s\n' '8081 포트가 이미 사용 중입니다. 기존 앱을 확인하고 해당 실행 터미널에서 종료한 뒤 다시 실행하세요.' >&2
  exit 1
fi

exec flutter run -d chrome --web-hostname=127.0.0.1 --web-port=8081 --dart-define=MAPS_ENABLED=true "$@"
