
#!/bin/bash
set -e

FLUTTER_VERSION="3.47.9"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${ARCHIVE}"

echo "Downloading Flutter SDK..."
curl -fL "$URL" -o "/tmp/${ARCHIVE}"

echo "Extracting Flutter SDK..."
tar -xf "/tmp/${ARCHIVE}" -C "$HOME"

export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

flutter build web --release \
  --dart-define=API_BASE_URL=https://kabir-akib-vms-backend.onrender.com
