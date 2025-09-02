set -euo pipefail
[[ -f ./enclave.env ]] && source ./enclave.env

jq_bin="${jq_bin:-jq}"
openssl_bin="${openssl_bin:-openssl}"

discover() {
  local url="${ngrok_api}"
  local h p
  if command -v "$jq_bin" >/dev/null 2>&1; then
    h=$(curl -ss "$url" | jq -r '.tunnels[] | select(.proto=="tcp") | .public_url' | sed -e 's#^tcp://##' | tail -n1)
  else
    h=$(curl -ss "$url" | grep -eo 'tcp://[0-9a-za-z\.\-]+:[0-9]+' | sed 's#^tcp://##' | tail -n1)
  fi
  [[ -n "$h" ]] || { echo "no ngrok tcp tunnel found on $url"; exit 2; }
  ngrok_host="${h%:*}"
  ngrok_port="${h##*:}"
}

host=""
port=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) host="$2"; shift 2;;
    --port) port="$2"; shift 2;;
    *) echo "unknown arg: $1"; exit 2;;
  esac
done

[[ -n "$host" && -n "$port" ]] || discover
host="${host:-$ngrok_host}"
port="${port:-$ngrok_port}"

client_crt=$(ls "${certs_dir}/${client_cn_prefix}-"*.crt 2>/dev/null | head -n1 || true)
client_key="${client_crt%.crt}.key"

[[ -n "${client_crt}" && -f "${client_key}" ]] || {
  echo "no client cert found. mint one first: ./pki_enclave.sh issue-client alice"
  exit 1
}

$openssl_bin s_client -connect "${host}:${port}" -servername "${server_fqdn}" \
  -cert "${client_crt}" -key "${client_key}" -cafile "${steppath}/certs/root_ca.crt" </dev/null || true

curl -vk --cert "${client_crt}" --key "${client_key}" \
  --cacert "${steppath}/certs/root_ca.crt" \
  --connect-to "${server_fqdn}:${service_port}:${host}:${port}" \
  "https://${server_fqdn}:${service_port}/"