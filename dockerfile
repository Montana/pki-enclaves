from smallstep/step-cli:latest as step

from debian:bookworm-slim
run apt-get update && apt-get install -y --no-install-recommends openssl curl jq ca-certificates && rm -rf /var/lib/apt/lists/*
copy --from=step /usr/bin/step /usr/bin/step
run curl -fsSL https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.tgz | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/ngrok
workdir /app

copy safetunnels.sh /app/safetunnels.sh
copy client-test.sh /app/client-test.sh
run chmod +x /app/safetunnels.sh /app/client-test.sh

expose 4040 8443
env ngrok_region=us
entrypoint ["/app/safetunnels.sh"]
