#!/usr/bin/env bash
set -euo pipefail

pid_file="${1:?usage: backend-up.sh pid-file}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_dir="$(cd "$script_dir/../../backend" && pwd)"

rm -f "$pid_file"

# shellcheck source=/dev/null
source "$script_dir/ensure-backend-node.sh"

cd "$backend_dir"

docker compose up -d
until docker exec driva-postgres pg_isready -U driva >/dev/null 2>&1; do
  sleep 1
done

pnpm prisma:generate
pnpm prisma db push --skip-generate

rm -f tsconfig.tsbuildinfo

stop_backend() {
  if [[ -n "${backend_pid:-}" ]] && kill -0 "$backend_pid" 2>/dev/null; then
    kill -TERM "-$backend_pid" 2>/dev/null || kill -TERM "$backend_pid" 2>/dev/null || true
    wait "$backend_pid" 2>/dev/null || true
  fi
  rm -f "$pid_file"
}

stop_backend_and_exit() {
  trap - EXIT INT TERM
  stop_backend

  exit 0
}

trap stop_backend EXIT
trap stop_backend_and_exit INT TERM

if command -v setsid >/dev/null 2>&1; then
  setsid pnpm start:dev &
else
  pnpm start:dev &
fi

backend_pid="$!"
echo "$backend_pid" > "$pid_file"
wait "$backend_pid" || exit_code="$?"
rm -f "$pid_file"

if [[ "${exit_code:-0}" == "130" || "${exit_code:-0}" == "143" ]]; then
  exit 0
fi

exit "${exit_code:-0}"
