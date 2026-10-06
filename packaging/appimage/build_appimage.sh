#!/usr/bin/env bash
set -e

# ========================================================
# PANDA IPTV // AppImage Builder
# ========================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
APP_DIR="$PROJECT_ROOT/build/AppDir"
DIST_DIR="$PROJECT_ROOT/dist"
APPIMAGETOOL="/tmp/appimagetool-x86_64.AppImage"

VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | tr -d ' ' | cut -d'+' -f1)
OUTPUT_APPIMAGE="$DIST_DIR/Panda-IPTV-${VERSION}-x86_64.AppImage"

echo "==> [PANDA IPTV] Preparando AppImage versão $VERSION..."

# 1. Compila release do Linux se o bundle ainda não existir
if [ ! -f "$BUILD_DIR/panda_iptv" ]; then
    echo "==> Compilando bundle Linux em Release..."
    cd "$PROJECT_ROOT"
    flutter build linux --release
fi

# 2. Prepara a estrutura do AppDir
echo "==> Montando AppDir..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/data"
mkdir -p "$DIST_DIR"

# Copia arquivos do bundle do Flutter
cp -r "$BUILD_DIR/panda_iptv" "$APP_DIR/usr/bin/"
cp -r "$BUILD_DIR/lib/." "$APP_DIR/usr/lib/"
cp -r "$BUILD_DIR/data/." "$APP_DIR/usr/data/"

# Copia ícone e arquivo .desktop
cp "$PROJECT_ROOT/assets/images/logo.png" "$APP_DIR/panda_iptv.png"
cp "$PROJECT_ROOT/packaging/appimage/panda-iptv.desktop" "$APP_DIR/panda_iptv.desktop"
cp "$PROJECT_ROOT/packaging/appimage/panda-iptv.desktop" "$APP_DIR/.desktop"

# 3. Cria o AppRun
cat << 'EOF' > "$APP_DIR/AppRun"
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr"
exec "${HERE}/usr/bin/panda_iptv" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# 4. Obtém o appimagetool se não estiver instalado no sistema
TOOL="appimagetool"
if ! command -v appimagetool &> /dev/null; then
    if [ ! -f "$APPIMAGETOOL" ]; then
        echo "==> Baixando appimagetool..."
        curl -sSL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -o "$APPIMAGETOOL"
        chmod +x "$APPIMAGETOOL"
    fi
    TOOL="$APPIMAGETOOL"
fi

# 5. Gera o AppImage final
echo "==> Gerando AppImage em: $OUTPUT_APPIMAGE"
ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APP_DIR" "$OUTPUT_APPIMAGE" || ARCH=x86_64 "$TOOL" "$APP_DIR" "$OUTPUT_APPIMAGE"

echo "==> [SUCESSO] AppImage criado com sucesso:"
ls -lh "$OUTPUT_APPIMAGE"
