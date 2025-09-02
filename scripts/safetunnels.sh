#!/usr/bin/env bash
set -euo pipefail
: "${ngrok_authtoken?set ngrok_authtoken}"
host="${1:-svc.127.0.0.1.nip.io}"
port="${2:-8443}"
days="${3:-365}"
region="${ngrok_region:-us}"
tmpdir="$(mktemp -d)"
cd "$tmpdir"
step certificate create "local root ca" root_ca.crt root_ca.key --profile root-ca --no-password --insecure
step certificate create "$host" server.crt server.key --profile leaf --ca root_ca.crt --ca-key root_ca.key --no-password --insecure --not-after "${days}d"
step certificate create "client.$host" client.crt client.key --profile leaf --ca root_ca.crt --ca-key root_ca.key --no-password --insecure --not-after "${days}d"
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt -certfile root_ca.crt -passout pass:
mkfifo srv.log
openssl s_server -accept "$port" -cert server.crt -key server.key -cafile root_ca.crt -verify 1 -verify_return_error -www > srv.log 2>&1 &
srv_pid=$!
trap 'kill $srv_pid $ngrok_http_pid $ngrok_tcp_pid 2>/dev/null || true' exit
ngrok config add-authtoken "$ngrok_authtoken" >/dev/null
ngrok http --region "$region" "https://localhost:${port}" >/dev/null 2>&1 &
ngrok_http_pid=$!
sleep 1
ngrok tcp --region "$region" "$port" >/dev/null 2>&1 &
ngrok_tcp_pid=$!
until curl -ss http://127.0.0.1:4040/api/tunnels >/dev/null; do sleep 1; done
http_url="$(curl -ss http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url' | head -n1)"
tcp_url="$(curl -ss http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="tcp") | .public_url' | head -n1)"
echo "$http_url" > public_https.txt
echo "$tcp_url" > public_tcp.txt
echo "$host" > hostname.txt
echo "$port" > port.txt
echo "$tmpdir" > working_dir.txt
printf '%s\n' "certs: $tmpdir" "https: $http_url" "tcp: $tcp_url"