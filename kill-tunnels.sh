#!/usr/bin/env bash
set -euo pipefail
pkill -f "openssl s_server" || true
pkill -f "ngrok http" || true
pkill -f "ngrok tcp" || true
echo "all tunnels and servers killed"
