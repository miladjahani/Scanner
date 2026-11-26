#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> [1/4] Testing Go Core..."
cd "$ROOT_DIR/go_core"
go vet ./...
go test -v ./...

echo "==> [2/4] Building Go Native Android AAR (gomobile)..."
if ! command -v gomobile >/dev/null 2>&1; then
  go install golang.org/x/mobile/cmd/gomobile@latest
  go install golang.org/x/mobile/cmd/gobind@latest
  export PATH="$PATH:$(go env GOPATH)/bin"
  gomobile init
fi

mkdir -p "$ROOT_DIR/android/app/libs"
gomobile bind -v -target=android/arm64,android/arm -androidapi 24 \
  -o "$ROOT_DIR/android/app/libs/edgepulse_core.aar" .

echo "==> [3/4] Preparing Flutter Project..."
cd "$ROOT_DIR"
flutter create --platforms=android .
flutter pub get
flutter analyze --no-fatal-infos

echo "==> [4/4] Building Android Release APKs..."
flutter build apk --release --split-per-abi
flutter build apk --release

echo "Done! APKs are located in: $ROOT_DIR/build/app/outputs/flutter-apk/"
