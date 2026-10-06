#!/usr/bin/env bash
set -e

# ========================================================
# PANDA IPTV // Release & Distribution Builder
# ========================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | tr -d ' ' | cut -d'+' -f1)

echo "=========================================================="
echo " PANDA IPTV // GERANDO RELEASE v${VERSION}"
echo "=========================================================="

# 1. Compilação Linux Desktop
echo ""
echo "==> [1/3] Compilando Linux Desktop (Release)..."
cd "$PROJECT_ROOT"
flutter build linux --release

# 2. Compactação Tar.gz Portátil do Linux
echo ""
echo "==> [2/3] Gerando pacote portátil Linux .tar.gz..."
cd "$PROJECT_ROOT/build/linux/x64/release"
tar -czf "$DIST_DIR/panda-iptv-${VERSION}-linux-x64.tar.gz" bundle/
echo "Tarball criado em: $DIST_DIR/panda-iptv-${VERSION}-linux-x64.tar.gz"

# 3. Geração do AppImage
echo ""
echo "==> [3/4] Gerando AppImage portátil..."
cd "$PROJECT_ROOT"
./packaging/appimage/build_appimage.sh

# 4. Geração do Android APK (se Android SDK configurado)
echo ""
echo "==> [4/4] Verificando ambiente Android para APK..."
if flutter doctor | grep -q "Unable to locate Android SDK"; then
    echo "[-] Android SDK não detectado. Pulando compilação do APK."
    echo "    (Para gerar o APK posteriormente, use: ./scripts/build_apk.sh)"
else
    echo "==> Compilando APK Android (Release)..."
    flutter build apk --release
    if [ -f "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" "$DIST_DIR/Panda-IPTV-${VERSION}.apk"
        echo "APK criado em: $DIST_DIR/Panda-IPTV-${VERSION}.apk"
    fi
fi

echo ""
echo "=========================================================="
echo " BUILD CONCLUÍDA COM SUCESSO!"
echo " Arquivos gerados em dist/:"
ls -lh "$DIST_DIR"
echo "=========================================================="
