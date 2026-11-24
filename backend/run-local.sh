#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [[ -f .env ]]; then
  # .env is trusted Bash configuration; export assignments to the Java process.
  set -a
  source ./.env
  set +a
else
  printf '%s\n' '.env 파일이 없어 현재 환경변수로 실행합니다. 필요한 설정은 .env.example을 참고하세요.' >&2
fi

exec ./mvnw spring-boot:run "$@"
