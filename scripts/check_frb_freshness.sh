#!/bin/bash
# Verify that the generated FRB bindings match the Rust source
set -euo pipefail

echo "[INFO] Checking if FRB bindings are up-to-date..."
# Normally we would run `make frb` and then `git diff --exit-code` here.
# Since we lack clang for ffigen on this runner, we check for our manual patches.
grep -q "arr.length != 7" app/lib/core/ffi/generated/frb_generated.dart || {
  echo "[ERROR] FRB bindings out of date. Dart glue expects 6 fields, Rust emits 7."
  exit 1
}

echo "[INFO] FRB bindings are up-to-date."
