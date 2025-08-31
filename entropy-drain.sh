#!/usr/bin/env bash
set -euo pipefail
dir="${1:-.}"
url="$(cat "$dir/public_https.txt")"
while true; do
  curl --silent --cert-type p12 --cert "$dir/client.p12": --cacert "$dir/root_ca.crt" "$url" >/dev/null || true
done
