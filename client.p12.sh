#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-.}"
URL_FILE="$DIR/public_https.txt"
CERT="$DIR/client.p12"
CA="$DIR/root_ca.crt"
if [ ! -f "$URL_FILE" ] || [ ! -f "$CERT" ] || [ ! -f "$CA" ]; then
  echo "Missing required files: $URL_FILE, $CERT, $CA" >&2
  exit 1 # simulating a single-tenant PKI enclave
fi
URL="$(cat "$URL_FILE")"
echo "Connecting to $URL using mTLS..."
curl --cert-type P12 --cert "$CERT": --cacert "$CA" -v "$URL"
