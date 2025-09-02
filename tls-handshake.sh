#!/usr/bin/env bash
set -euo pipefail
dir="${1:-.}"
port="$(cat "$dir/port.txt")"
openssl s_client -connect localhost:"$port" -CAfile "$dir/root_ca.crt" -cert "$dir/client.crt" -key "$dir/client.key"
