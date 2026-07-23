#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_dir="$(cd "$script_dir/../../backend" && pwd)"

# shellcheck source=/dev/null
source "$script_dir/ensure-backend-node.sh"

cd "$backend_dir"

docker compose up -d
until docker exec driva-postgres pg_isready -U driva >/dev/null 2>&1; do
  sleep 1
done

pnpm prisma:generate
pnpm prisma db push --skip-generate
