#!/bin/sh
set -eu

build_dir="${1:-build/web}"
index_file="$build_dir/index.html"
bootstrap_file="$build_dir/flutter_bootstrap.js"
main_file="$build_dir/main.dart.js"

for file in "$index_file" "$bootstrap_file" "$main_file"; do
  if [ ! -f "$file" ]; then
    echo "Missing Flutter web build artifact: $file" >&2
    exit 1
  fi
done

hash_file() {
  sha256sum "$1" | awk '{ print substr($1, 1, 16) }'
}

main_hash="$(hash_file "$main_file")"
sed -i -E "s#main\\.dart\\.js(\\?v=[A-Za-z0-9._-]+)?#main.dart.js?v=${main_hash}#g" "$bootstrap_file"

bootstrap_hash="$(hash_file "$bootstrap_file")"
sed -i -E "s#flutter_bootstrap\\.js(\\?v=[A-Za-z0-9._-]+)?#flutter_bootstrap.js?v=${bootstrap_hash}#g" "$index_file"

printf 'Versioned Flutter web assets: flutter_bootstrap.js?v=%s main.dart.js?v=%s\n' \
  "$bootstrap_hash" \
  "$main_hash"
