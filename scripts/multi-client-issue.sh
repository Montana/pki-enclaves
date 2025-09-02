#!/usr/bin/env bash
set -euo pipefail
dir="${1:-.}"
host="$(cat "$dir/hostname.txt")"
count="${2:-5}"
for i in $(seq 1 "$count"); do
  step certificate create "client${i}.$host" "$dir/client${i}.crt" "$dir/client${i}.key" --profile leaf --ca "$dir/root_ca.crt" --ca-key "$dir/root_ca.key" --no-password --insecure
  openssl pkcs12 -export -out "$dir/client${i}.p12" -inkey "$dir/client${i}.key" -in "$dir/client${i}.crt" -certfile "$dir/root_ca.crt" -passout pass:
done
ls -1 "$dir"/client*.p12
