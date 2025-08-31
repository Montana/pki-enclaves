#!/usr/bin/env bash
set -euo pipefail
: "${NGROK_AUTHTOKEN?Set NGROK_AUTHTOKEN}"
HOST="${1:-svc.127.0.0.1.nip.io}"
PORT="${2:-8443}"
DAYS="${3:-365}"
REGION="${NGROK_REGION:-us}"
TMPDIR="$(mktemp -d)"
cd "$TMPDIR"
step certificate create "Local Root CA" root_ca.crt root_ca.key --profile root-ca --no-password --insecure
step certificate create "$HOST" server.crt server.key --profile leaf --ca root_ca.crt --ca-key root_ca.key --no-password --insecure --not-after "${DAYS}d"
step certificate create "client.$HOST" client.crt client.key --profile leaf --ca root_ca.crt --ca-key root_ca.key --no-password --insecure --not-after "${DAYS}d"
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt -certfile root_ca.crt -passout pass:
mkfifo srv.log
openssl s_server -accept "$PORT" -cert server.crt -key server.key -CAfile root_ca.crt -Verify 1 -verify_return_error -www > srv.log 2>&1 &
SRV_PID=$!
trap 'kill $SRV_PID $NGROK_HTTP_PID $NGROK_TCP_PID 2>/dev/null || true' EXIT
ngrok config add-authtoken "$NGROK_AUTHTOKEN" >/dev/null
ngrok http --region "$REGION" "https://localhost:${PORT}" >/dev/null 2>&1 &
NGROK_HTTP_PID=$!
sleep 1
ngrok tcp --region "$REGION" "$PORT" >/dev/null 2>&1 &
NGROK_TCP_PID=$!
until curl -sS http://127.0.0.1:4040/api/tunnels >/dev/null; do sleep 1; done
HTTP_URL="$(curl -sS http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url' | head -n1)"
TCP_URL="$(curl -sS http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="tcp") | .public_url' | head -n1)"
echo "$HTTP_URL" > public_https.txt
echo "$TCP_URL" > public_tcp.txt
echo "$HOST" > hostname.txt
echo "$PORT" > port.txt
echo "$TMPDIR" > working_dir.txt
printf '%s\n' "certs: $TMPDIR" "https: $HTTP_URL" "tcp: $TCP_URL"
