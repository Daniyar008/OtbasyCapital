#!/usr/bin/env bash
set -euo pipefail

# Render Static Sites provide Node/Python but do not include Flutter.
# Install the official stable SDK for this build, outside the checkout.
# FLUTTER_REF can pin a compatible official Flutter tag when required.
FLUTTER_REF="${FLUTTER_REF:-stable}"
SDK_DIR="$(mktemp -d /tmp/otbasy-flutter.XXXXXX)"
git clone --depth 1 --branch "$FLUTTER_REF" \
  https://github.com/flutter/flutter.git "$SDK_DIR"
export PATH="$SDK_DIR/bin:$PATH"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true

flutter config --no-analytics
flutter --version
flutter pub get
flutter build web --release --base-href / --no-web-resources-cdn

test -s build/web/index.html
test -s build/web/main.dart.js
test -s build/web/flutter_bootstrap.js
