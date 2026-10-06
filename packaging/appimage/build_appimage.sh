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

# O Flutter C++ embedder requer que as pastas 'lib' e 'data' existam no mesmo diretório do executável.
ln -sf ../lib "$APP_DIR/usr/bin/lib"
ln -sf ../data "$APP_DIR/usr/bin/data"
ln -sf usr/bin/panda_iptv "$APP_DIR/panda_iptv"

# Copia bibliotecas libmpv do sistema de build caso existam
for mpv_lib in /usr/lib/x86_64-linux-gnu/libmpv.so* /usr/lib64/libmpv.so* /usr/lib/libmpv.so*; do
    if [ -e "$mpv_lib" ]; then
        cp -d "$mpv_lib" "$APP_DIR/usr/lib/" 2>/dev/null || true
    fi
done

# Copia ícone e arquivo .desktop
cp "$PROJECT_ROOT/assets/images/logo.png" "$APP_DIR/panda_iptv.png"
cp "$PROJECT_ROOT/packaging/appimage/panda-iptv.desktop" "$APP_DIR/panda_iptv.desktop"
cp "$PROJECT_ROOT/packaging/appimage/panda-iptv.desktop" "$APP_DIR/.desktop"

# 3. Cria o AppRun
cat << 'EOF' > "$APP_DIR/AppRun"
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"

# Garantir symlinks para lib e data adjacentes ao binário do Flutter caso não existam
[ ! -e "${HERE}/usr/bin/lib" ] && ln -sf ../lib "${HERE}/usr/bin/lib" 2>/dev/null || true
[ ! -e "${HERE}/usr/bin/data" ] && ln -sf ../data "${HERE}/usr/bin/data" 2>/dev/null || true

# Suporte universal para libmpv:
# Se o host possuir libmpv (ex: libmpv.so.2 no Arch/Fedora ou libmpv.so) e precisar de compatibilidade com libmpv.so.1
MPV_DIR="/tmp/panda_iptv_lib_${USER:-user}"
HOST_MPV=$(ldconfig -p 2>/dev/null | grep -E 'libmpv\.so(\.[0-9]+)?' | awk '{print $NF}' | head -n 1)
if [ -n "$HOST_MPV" ] && [ -f "$HOST_MPV" ]; then
    mkdir -p "$MPV_DIR"
    ln -sf "$HOST_MPV" "$MPV_DIR/libmpv.so.1"
    ln -sf "$HOST_MPV" "$MPV_DIR/libmpv.so.2"
    ln -sf "$HOST_MPV" "$MPV_DIR/libmpv.so"
    export LD_LIBRARY_PATH="${MPV_DIR}:${HERE}/usr/lib:${LD_LIBRARY_PATH}"
else
    export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
fi

cd "${HERE}/usr/bin"
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
