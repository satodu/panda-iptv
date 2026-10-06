#!/usr/bin/env bash
set -e

# ========================================================
# PANDA IPTV // Android APK Builder
# ========================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

VERSION=$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | tr -d ' ' | cut -d'+' -f1)

echo "=========================================================="
echo " PANDA IPTV // ANDROID APK BUILDER v${VERSION}"
echo "=========================================================="

# Exporta variáveis do Android SDK se existirem em /opt/android-sdk
if [ -d "/opt/android-sdk" ]; then
    export ANDROID_HOME="/opt/android-sdk"
    export ANDROID_SDK_ROOT="/opt/android-sdk"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
fi

# Verifica se o Flutter tem o Android SDK configurado
flutter config --android-sdk "${ANDROID_HOME:-/opt/android-sdk}" > /dev/null 2>&1 || true

# Diagnóstico de Plataforma e SDK
SDK_CHECK=$(flutter doctor | grep -E "Unable to locate Android SDK|No valid Android SDK platforms" || true)

if [ -n "$SDK_CHECK" ]; then
    echo "[-] AVISO: O Android SDK precisa de componentes essenciais."
    echo ""
    echo "Siga estes 3 passos rápidos para habilitar a compilação:"
    echo "  1. Permissão de escrita na pasta do SDK:"
    echo "     sudo chown -R \$USER:\$USER /opt/android-sdk"
    echo ""
    echo "  2. Baixar a plataforma e aceitar licenças:"
    echo "     /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager \"platforms;android-34\" \"build-tools;34.0.0\""
    echo "     yes | flutter doctor --android-licenses"
    echo ""
    echo "  3. Instalar o JDK 17 (compatível com Gradle/Kotlin):"
    echo "     sudo pacman -S jdk17-openjdk"
    echo "     sudo archlinux-java set java-17-openjdk"
    echo ""
    exit 1
fi

echo "==> Compilando APK (Release Universal)..."
cd "$PROJECT_ROOT"
flutter build apk --release

SOURCE_APK="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
TARGET_APK="$DIST_DIR/Panda-IPTV-${VERSION}.apk"

if [ -f "$SOURCE_APK" ]; then
    cp "$SOURCE_APK" "$TARGET_APK"
    echo ""
    echo "==> APK gerado com sucesso em:"
    echo "    $TARGET_APK"
    ls -lh "$TARGET_APK"
else
    echo "[-] Erro: APK gerado não encontrado em $SOURCE_APK"
    exit 1
fi
