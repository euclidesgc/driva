#!/usr/bin/env bash
set -euo pipefail

pid_file="${1:?usage: backend-down.sh <pid-file>}"

if [[ -f "$pid_file" ]]; then
  backend_pid="$(tr -cd '0-9' < "$pid_file")"

  if [[ -n "$backend_pid" ]] && kill -0 "$backend_pid" 2>/dev/null; then
    kill -TERM "-$backend_pid" 2>/dev/null || kill -TERM "$backend_pid" 2>/dev/null || true

    for _ in {1..20}; do
      kill -0 "$backend_pid" 2>/dev/null || break
      sleep 0.1
    done

    if kill -0 "$backend_pid" 2>/dev/null; then
      kill -KILL "-$backend_pid" 2>/dev/null || kill -KILL "$backend_pid" 2>/dev/null || true
    fi
  fi

  rm -f "$pid_file"
fi

docker compose down
