#!/usr/bin/env bash
# Automated toolchain installation for Pirate Unified Wallet
# This script installs Rust, Flutter, and other required tools.

set -euo pipefail

# Pinned versions
RUST_VERSION="1.90.0"
FLUTTER_VERSION="3.41.1"
FRB_CODEGEN_VERSION="2.11.1"
PROTOC_VERSION="25.1"
NINJA_VERSION="1.12.1"
ANDROID_CMDLINE_TOOLS_VERSION="11076708"

echo "=== Installing toolchain for Pirate Unified Wallet ==="

# 1. Install Rust via rustup
if ! command -v rustup &> /dev/null; then
    echo "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_VERSION"
else
    echo "Rustup already installed. Ensuring toolchain $RUST_VERSION..."
    rustup toolchain install "$RUST_VERSION"
    rustup default "$RUST_VERSION"
fi

# Load cargo environment
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# 2. Install Flutter
mkdir -p "$HOME/apps"
if [ ! -d "$HOME/apps/flutter" ]; then
    echo "Installing Flutter $FLUTTER_VERSION..."
    cd "$HOME/apps"
    curl -O "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz"
    tar xf "flutter_linux_$FLUTTER_VERSION-stable.tar.xz"
    rm "flutter_linux_$FLUTTER_VERSION-stable.tar.xz"
    cd -
else
    echo "Flutter already exists at $HOME/apps/flutter"
fi

export PATH="$HOME/apps/flutter/bin:$PATH"

# 3. Install flutter_rust_bridge_codegen
if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    echo "Installing flutter_rust_bridge_codegen $FRB_CODEGEN_VERSION..."
    mkdir -p "$HOME/.cargo/bin"
    curl -LO "https://github.com/fzyzcjy/flutter_rust_bridge/releases/download/v$FRB_CODEGEN_VERSION/flutter_rust_bridge_codegen-x86_64-unknown-linux-gnu-v$FRB_CODEGEN_VERSION.tgz"
    tar xf "flutter_rust_bridge_codegen-x86_64-unknown-linux-gnu-v$FRB_CODEGEN_VERSION.tgz"
    mv flutter_rust_bridge_codegen "$HOME/.cargo/bin/"
    rm "flutter_rust_bridge_codegen-x86_64-unknown-linux-gnu-v$FRB_CODEGEN_VERSION.tgz"
else
    echo "flutter_rust_bridge_codegen already installed."
fi

# 4. Install protoc
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/include"
if ! command -v protoc &> /dev/null; then
    echo "Installing protoc $PROTOC_VERSION..."
    cd "$HOME/apps"
    curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip"
    unzip -o "protoc-$PROTOC_VERSION-linux-x86_64.zip" -d protoc_temp
    mv protoc_temp/bin/protoc "$HOME/.local/bin/"
    cp -r protoc_temp/include/* "$HOME/.local/include/"
    rm -rf protoc_temp "protoc-$PROTOC_VERSION-linux-x86_64.zip"
    cd -
else
    echo "protoc already installed."
fi

# 5. Install ninja
if ! command -v ninja &> /dev/null; then
    echo "Installing ninja $NINJA_VERSION..."
    cd "$HOME/apps"
    curl -LO "https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/ninja-linux.zip"
    unzip -o "ninja-linux.zip"
    mv ninja "$HOME/.local/bin/"
    rm "ninja-linux.zip"
    cd -
else
    echo "ninja already installed."
fi

# 6. Android Command Line Tools (minimal setup)
if [ ! -d "$HOME/Android/Sdk/cmdline-tools/latest" ]; then
    echo "Installing Android Command Line Tools..."
    mkdir -p "$HOME/Android/Sdk/cmdline-tools"
    cd "$HOME/apps"
    curl -LO "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip"
    unzip -o "commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" -d cmdline-tools-temp
    mkdir -p "$HOME/Android/Sdk/cmdline-tools/latest"
    cp -r cmdline-tools-temp/cmdline-tools/* "$HOME/Android/Sdk/cmdline-tools/latest/"
    rm -rf cmdline-tools-temp "commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip"
    cd -
else
    echo "Android Command Line Tools already installed."
fi

# 6. Check for Linux desktop dependencies
if [[ "$(uname -s)" == "Linux" ]]; then
    echo "Checking for Linux desktop dependencies..."
    MISSING_DEPS=()
    if ! command -v clang++ &> /dev/null; then MISSING_DEPS+=("clang"); fi
    if ! command -v cmake &> /dev/null; then MISSING_DEPS+=("cmake"); fi
    if ! command -v pkg-config &> /dev/null; then MISSING_DEPS+=("pkg-config"); fi
    if ! pkg-config --exists gtk+-3.0 &> /dev/null; then MISSING_DEPS+=("libgtk-3-dev"); fi
    if ! pkg-config --exists libsecret-1 &> /dev/null; then MISSING_DEPS+=("libsecret-1-dev"); fi
    if ! pkg-config --exists liblzma &> /dev/null; then MISSING_DEPS+=("liblzma-dev"); fi

    # Check if clang++ can actually compile (often fails if libstdc++-dev is missing)
    if command -v clang++ &> /dev/null; then
        if ! echo "int main(){}" | clang++ -x c++ - -o /dev/null &> /dev/null; then
            GCC_VER=$(clang++ -v 2>&1 | grep "Selected GCC installation" | rev | cut -d/ -f1 | rev || echo "")
            echo "⚠️  clang++ cannot compile a simple program."
            if [[ -n "$GCC_VER" ]]; then
                echo "   💡 Try installing the missing library: sudo apt-get install libstdc++-$GCC_VER-dev"
            fi
            if echo "int main(){}" | g++ -x c++ - -o /dev/null &> /dev/null; then
                echo "   💡 Fallback enabled: Your g++ works. The build system will automatically use it."
            else
                echo "   💡 Try: sudo apt-get install build-essential"
                echo "   💡 If you have apt dependency errors, try: sudo apt-get update && sudo apt-get install -f"
            fi
        fi
    fi

    if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
        echo "⚠️  Missing Linux desktop dependencies: ${MISSING_DEPS[*]}"
        echo "Please install them using your package manager, for example:"
        echo "  sudo apt-get install clang cmake pkg-config libgtk-3-dev libsecret-1-dev liblzma-dev ${MISSING_DEPS[*]}"
    else
        echo "✅ All Linux desktop dependencies found."
    fi
fi

echo "=== Toolchain installation complete! ==="
echo "Now run: source setup-env.sh"
echo "Then run: flutter doctor --android-licenses"
