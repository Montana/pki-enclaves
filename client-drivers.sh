set -euo pipefail
[[ -f ./enclave.env ]] && source ./enclave.env

JQ_BIN="${JQ_BIN:-jq}"
OPENSSL_BIN="${OPENSSL_BIN:-openssl}"

discover() {
  local url="${NGROK_API}"
  local h p
  if command -v "$JQ_BIN" >/dev/null 2>&1; then
    h=$(curl -sS "$url" | jq -r '.tunnels[] | select(.proto=="tcp") | .public_url' | sed -e 's#^tcp://##' | tail -n1)
  else
    h=$(curl -sS "$url" | grep -Eo 'tcp://[0-9a-zA-Z\.\-]+:[0-9]+' | sed 's#^tcp://##' | tail -n1)
  fi
  [[ -n "$h" ]] || { echo "No ngrok TCP tunnel found on $url"; exit 2; }
  NGROK_HOST="${h%:*}"
  NGROK_PORT="${h##*:}"
}

HOST=""
PORT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

[[ -n "$HOST" && -n "$PORT" ]] || discover
HOST="${HOST:-$NGROK_HOST}"
PORT="${PORT:-$NGROK_PORT}"

client_crt=$(ls "${CERTS_DIR}/${CLIENT_CN_PREFIX}-"*.crt 2>/dev/null | head -n1 || true)
client_key="${client_crt%.crt}.key"

[[ -n "${client_crt}" && -f "${client_key}" ]] || {
  echo "No client cert found. Mint one first: ./pki_enclave.sh issue-client alice"
  exit 1
}

$OPENSSL_BIN s_client -connect "${HOST}:${PORT}" -servername "${SERVER_FQDN}" \
  -cert "${client_crt}" -key "${client_key}" -CAfile "${STEPPATH}/certs/root_ca.crt" </dev/null || true

curl -vk --cert "${client_crt}" --key "${client_key}" \
  --cacert "${STEPPATH}/certs/root_ca.crt" \
  --connect-to "${SERVER_FQDN}:${SERVICE_PORT}:${HOST}:${PORT}" \
  "https://${SERVER_FQDN}:${SERVICE_PORT}/"
