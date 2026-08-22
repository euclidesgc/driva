#!/usr/bin/env bash
# Lê API_BASE_URL/DEFAULT_SLUG de um config/<env>.json do driva_demo_app
# (versionado, com PUBLISHABLE_KEY de placeholder) e escreve um
# config/<env>.local.json com a chave real, descoberta em GET /v1/projects —
# mesma lógica do tool/run_demo.sh, para o launch do VS Code não cair na
# armadilha do placeholder (README do driva_demo_app § "Gerar o APK release").
set -euo pipefail

in_config="${1:?usage: resolve-demo-key.sh <config-de-entrada.json> <config-de-saida.json> [titulo-do-projeto]}"
out_config="${2:?usage: resolve-demo-key.sh <config-de-entrada.json> <config-de-saida.json> [titulo-do-projeto]}"
project_title="${3:-}"

python3 - "$in_config" "$out_config" "$project_title" <<'PY'
import json
import sys
import urllib.error
import urllib.request

in_path, out_path, project_title = sys.argv[1], sys.argv[2], sys.argv[3]

with open(in_path, encoding="utf-8") as f:
    config = json.load(f)

api_base_url = config["API_BASE_URL"]

try:
    with urllib.request.urlopen(f"{api_base_url}/v1/projects", timeout=20) as resp:
        rows = json.load(resp)
except (urllib.error.URLError, TimeoutError) as error:
    raise SystemExit(f"não foi possível alcançar {api_base_url}/v1/projects: {error}")

if project_title:
    rows = [r for r in rows if r["title"] == project_title]
if not rows:
    suffix = f" com título {project_title!r}" if project_title else ""
    raise SystemExit(f"nenhum projeto encontrado em {api_base_url}{suffix}")

key = rows[0]["publishableKey"]
if not key.startswith("pk_"):
    raise SystemExit(f"chave publicável inválida em {api_base_url}: {key[:14]!r}…")

config["PUBLISHABLE_KEY"] = key

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"{out_path}: chave={key[:14]}… (projeto: {rows[0]['title']!r})")
PY
