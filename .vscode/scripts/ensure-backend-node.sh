#!/usr/bin/env bash
set -euo pipefail

backend_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../backend" && pwd)"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "nvm not found at $NVM_DIR; using node from PATH ($(node -v 2>/dev/null || echo unknown))" >&2
  (return 0 2>/dev/null) || exit 0
fi

. "$NVM_DIR/nvm.sh"

cd "$backend_dir"
nvm install
nvm use

node_bin="$(command -v node)"
pnpm_dir=""
if command -v pnpm >/dev/null 2>&1; then
  pnpm_dir="$(dirname "$(command -v pnpm)")"
fi
export PATH="$(dirname "$node_bin")${pnpm_dir:+:$pnpm_dir}:$PATH"

