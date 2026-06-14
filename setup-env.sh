#!/bin/bash
# Source this script to set up the development environment for Pirate Unified Wallet
# Usage: source setup-env.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "❌ Error: This script must be SOURCED, not executed."
    echo "Run this instead: source setup-env.sh"
    echo ""
    echo "To make these changes permanent, you can add this line to your ~/.bashrc or ~/.zshrc:"
    echo "source $(pwd)/setup-env.sh"
    exit 1
fi

# Load Cargo environment
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Add Flutter and other tools to PATH
export PATH="$HOME/apps/flutter/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/Android/Sdk/cmdline-tools/latest/bin:$PATH"

# Advanced Compiler Fix (Linux only)
# If clang++ is broken due to a mismatch in GCC installations (common on multiarch systems),
# we set up wrappers to point it to a functional GCC installation.
if [[ "$(uname -s)" == "Linux" ]]; then
    if command -v clang++ &> /dev/null && ! echo "int main(){}" | clang++ -x c++ - -o /dev/null &> /dev/null; then
        PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        WRAPPER_DIR="$PROJECT_ROOT/scripts/compiler-wrappers"

        # Try to find a functional GCC installation (prefer 11, then 10, then 9)
        GCC_PATH=""
        for ver in 11 12 10 9; do
            if [ -d "/usr/lib/gcc/x86_64-linux-gnu/$ver" ] && [ -f "/usr/lib/gcc/x86_64-linux-gnu/$ver/crtbegin.o" ]; then
                # Check if this version actually works with clang++
                if echo "int main(){}" | clang++ -L"/usr/lib/gcc/x86_64-linux-gnu/$ver" -B"/usr/lib/gcc/x86_64-linux-gnu/$ver" -x c++ - -o /dev/null &> /dev/null; then
                    GCC_PATH="/usr/lib/gcc/x86_64-linux-gnu/$ver"
                    break
                fi
            fi
        done

        if [ -n "$GCC_PATH" ]; then
            GCC_VER_NUM=$(basename "$GCC_PATH")
            mkdir -p "$WRAPPER_DIR"
            cat > "$WRAPPER_DIR/clang++" <<EOF
#!/bin/bash
/usr/bin/clang++ -Qunused-arguments \\
  -L"$GCC_PATH" -B"$GCC_PATH" \\
  -isystem "/usr/include/c++/$GCC_VER_NUM" \\
  -isystem "/usr/include/x86_64-linux-gnu/c++/$GCC_VER_NUM" \\
  "\$@"
EOF
            chmod +x "$WRAPPER_DIR/clang++"
            cat > "$WRAPPER_DIR/clang" <<EOF
#!/bin/bash
/usr/bin/clang -Qunused-arguments \\
  -L"$GCC_PATH" -B"$GCC_PATH" \\
  "\$@"
EOF
            chmod +x "$WRAPPER_DIR/clang"
            # Symlink other essential tools to avoid "Failed to find any of [ld.lld, ld]"
            for tool in ld ld.lld as ar nm objcopy objdump ranlib strip; do
                [ -f "/usr/bin/$tool" ] && [ ! -f "$WRAPPER_DIR/$tool" ] && ln -s "/usr/bin/$tool" "$WRAPPER_DIR/$tool"
            done
            export PATH="$WRAPPER_DIR:$PATH"
            # Also export them for CMake-based tools that respect these
            export CXX="$WRAPPER_DIR/clang++"
            export CC="$WRAPPER_DIR/clang"
            echo "💡 Automatically applied clang fix using GCC paths from $GCC_PATH"
        fi
    fi
fi

echo "✅ Environment set up!"
echo "Rust: $(rustc --version 2>/dev/null || echo 'not found')"
echo "Flutter: $(flutter --version | head -n 1 2>/dev/null || echo 'not found')"
echo "FRB Codegen: $(flutter_rust_bridge_codegen --version 2>/dev/null || echo 'not found')"
echo "Protoc: $(protoc --version 2>/dev/null || echo 'not found')"
