#!/usr/bin/env bash
set -euo pipefail
dir="${1:-.}"
url_file="$dir/public_https.txt"
cert="$dir/client.p12"
ca="$dir/root_ca.crt"
if [ ! -f "$url_file" ] || [ ! -f "$cert" ] || [ ! -f "$ca" ]; then
  echo "missing required files: $url_file, $cert, $ca" >&2
  exit 1
fi
url="$(cat "$url_file")"
echo "connecting to $url using mtls..."
curl --cert-type p12 --cert "$cert": --cacert "$ca" -v "$url"