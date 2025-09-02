#!/usr/bin/env bash
set -euo pipefail
dir="${1:-.}"
openssl verify -CAfile "$dir/root_ca.crt" "$dir/server.crt"
for c in "$dir"/client*.crt; do
  openssl verify -CAfile "$dir/root_ca.crt" "$c"
done
