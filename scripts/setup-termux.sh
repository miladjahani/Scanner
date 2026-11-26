#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==> Installing Go & Git on Termux..."
pkg update -y && pkg install -y golang git

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/go_core"

echo "==> Building EdgePulse Go CLI for Termux..."
go build -o "$PREFIX/bin/edgepulse-cli" ./cmd/edgepulse-cli

echo "==> Installed! Example usage:"
echo "edgepulse-cli -in proxies.txt -out best_proxies.csv -c 64 -trace -speed"
