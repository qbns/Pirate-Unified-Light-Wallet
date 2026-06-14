# Developer and Agent Guide (AGENTS.md)

This document provides essential information for developers and AI agents to set up, build, test, and contribute to the Pirate Unified Wallet project.

## 🚀 Quick Start (Linux/WSL)

To initialize a proper development environment on a fresh clone:

```bash
# 1. Install the toolchain (Rust, Flutter, protoc, etc.)
bash scripts/install-toolchain.sh

# 2. Load the environment variables (Run this in every new session)
source setup-env.sh

# 3. Bootstrap the project (Install dependencies and check tools)
make bootstrap

# 4. Generate FFI bindings
make frb

# 5. Run the app (ensure a device/emulator is connected)
make run
```

---

## 🛠 Technology Stack

- **UI Layer**: Flutter (Dart) - located in `app/`
- **Core Logic**: Rust - located in `crates/`
- **Bridge**: `flutter_rust_bridge` (FRB) for communication between Dart and Rust.
- **Build System**: `make` (Makefile) as the primary task runner.
- **Environment**: Nix (optional) for reproducible shells.

---

## 📦 Core Toolchain (Pinned Versions)

Consistency is maintained via pinned versions in CI and setup scripts:

| Tool | Version | Managed By |
| :--- | :--- | :--- |
| **Rust** | `1.90.0` | `rust-toolchain.toml` / `rustup` |
| **Flutter** | `3.41.1` | `scripts/install-toolchain.sh` |
| **FRB Codegen** | `2.11.1` | `cargo install` |
| **Ninja** | `1.12.1` | `scripts/install-toolchain.sh` |
| **Protoc** | `25.1` | `scripts/install-toolchain.sh` |
| **CocoaPods** | `1.16.2` | `gem` (macOS only) |
| **Java** | `25` | For Android builds |

### Linux Desktop Dependencies
Building for Linux requires: `clang`, `cmake`, `ninja`, `pkg-config`, `libgtk-3-dev`, `libsecret-1-dev`, `liblzma-dev`, `build-essential`.
Install via: `sudo apt-get install clang cmake pkg-config libgtk-3-dev libsecret-1-dev liblzma-dev build-essential`
*Note: Run `make bootstrap-check` if `clang++` fails to identify missing `libstdc++-X-dev` packages. If `clang++` is broken on your system, the build system will automatically fallback to `g++` if available.*

---

## 🏗 Key Commands (Makefile)

The `Makefile` is the single source of truth for common tasks.

### Setup & Maintenance
- `make bootstrap`: Full environment check and dependency installation.
- `make clean`: Remove build artifacts.
- `make frb`: Re-generate Flutter-Rust bridge bindings (essential after Rust FFI changes).

### Building
- `make build:rust`: Build all Rust crates in the workspace.
- `make build:android`: Build Android APK and AppBundle.
- `make build:ios`: Build iOS app (macOS only).
- `make build:desktop`: Build for the current desktop platform (Linux/macOS/Windows).

### Testing & Quality
- `make test:rust`: Run unit and integration tests for all Rust crates.
- `make test:flutter`: Run Flutter unit tests with coverage.
- `make test:integration`: Run end-to-end integration tests.
- `make lint`: Run `clippy` for Rust and `analyze` for Flutter.
- `make format`: Auto-format both Rust and Dart code.
- `make audit`: Check for security vulnerabilities in dependencies.

### Running
- `make run`: Run the app on the default connected device.
- `make run:android` / `make run:ios` / `make run:desktop`: Target specific platforms.

---

## 📂 Project Structure

- `app/`: Flutter application source code.
- `crates/`: Rust workspace containing the core logic.
- `bindings/`: Language-specific SDK wrappers (Android, iOS, React Native).
- `scripts/`: Platform-specific build, packaging, and CI scripts.
- `docs/`: Security, localization, and architectural documentation.

---

## 🎯 Code Style, Architecture & Best Practices

This wallet is used by millions of people. Code must be clean, predictable, and
reviewable. Treat the rules below as mandatory unless a maintainer explicitly
approves an exception. **Quality bar: zero new lints, zero new warnings, and no
new code smells.**

### Guiding Principles

- **SOLID by default.**
  - *Single Responsibility*: a class/widget/module does one thing. Split UI,
    state, and I/O instead of mixing them.
  - *Open/Closed*: extend behavior through new types or parameters, not by
    editing stable call sites with ad-hoc conditionals.
  - *Liskov*: subtypes/implementations must honor the contract of their
    interface (no surprising overrides).
  - *Interface Segregation*: prefer small, focused abstractions over wide
    "god" interfaces.
  - *Dependency Inversion*: depend on abstractions (providers, traits,
    repositories), not concrete implementations. Inject dependencies; avoid
    hidden globals/singletons.
- **DRY / Single Source of Truth**: encode each rule once. Domain constants and
  business rules belong in one place (e.g. `core/network/network_address_rules.dart`),
  not copy-pasted across screens.
- **KISS / YAGNI**: prefer the simplest solution that satisfies the requirement;
  do not add speculative abstractions.
- **Composition over inheritance**: especially in Flutter, build UIs by
  composing small widgets rather than deep class hierarchies.
- **Fail loudly, recover gracefully**: validate inputs at boundaries and map
  errors to clear, user-facing messages.

### Design Patterns Used in This Repo

- **Provider / Dependency Injection (Riverpod)**: state and services are exposed
  as providers under `app/lib/core/providers/`. Use `Provider.family` for
  parameterized lookups instead of duplicating `firstWhere(...orElse:...)`
  boilerplate across widgets.
- **Repository / Service layer**: feature logic talks to repositories/services,
  which own data access and the FFI boundary — widgets never call the FFI bridge
  directly for business logic.
- **Atomic Design (UI)**: reusable widgets live under `app/lib/ui/` as
  `atoms/` → `molecules/` → `organisms/`. Feature screens compose these; do not
  re-implement shared primitives inside features.
- **Feature-first modularity**: each feature under `app/lib/features/<feature>/`
  owns its screens, providers, and models. Cross-feature code is promoted to
  `core/` or `ui/`.
- **Strategy / Value objects**: encapsulate variant behavior (e.g. per-network
  rules) in dedicated immutable types instead of scattered `if (net == ...)`
  branches.

### Dart / Flutter Conventions

Linting is enforced via `app/analysis_options.yaml` (extends `flutter_lints`
with `strict-casts`, `strict-inference`, and `strict-raw-types`). Key rules to
follow proactively:

- **Imports**: use relative imports within `app/lib/` (`prefer_relative_imports`).
- **Strings & formatting**: single quotes (`prefer_single_quotes`), trailing
  commas on multi-line argument lists (`require_trailing_commas`) — let
  `dart format` / `make format` handle layout.
- **Typing**: always declare return types and annotate public APIs
  (`always_declare_return_types`, `type_annotate_public_apis`); never use
  `dynamic` calls (`avoid_dynamic_calls`).
- **Immutability**: prefer `final`/`const`; use `const` constructors for widgets
  where possible.
- **Naming**: `UpperCamelCase` for types, `lowerCamelCase` for members,
  `lowerCamelCase` files (`file_names`), `SCREAMING_CAPS` only for true
  constants.
- **No raw `print`**: use the logging facilities under `core/logging/`
  (`avoid_print`).
- **State management**: keep widgets declarative; put logic in providers/
  notifiers, not in `build()`. No logic in `createState` (`no_logic_in_create_state`).
- **Context safety**: guard `BuildContext` across async gaps
  (`use_build_context_synchronously`).
- **Generated code is off-limits**: do not hand-edit `app/lib/core/ffi/generated/`
  or `app/lib/l10n/app_localizations*.dart`; regenerate via tooling.

### Rust Conventions

- **Edition 2021**, formatted with `cargo fmt --all`; clippy must pass with
  `-D warnings` (`cargo clippy --all-targets --all-features --locked -D warnings`).
- **Error handling**: return `Result<T, E>` with typed errors (see each crate's
  `error.rs`); avoid `unwrap()`/`expect()`/`panic!` outside tests and truly
  unreachable invariants.
- **Modularity**: keep crates focused (crypto, storage, sync, net, FFI are
  separated under `crates/`). Shared logic belongs in `pirate-core`, not
  duplicated in FFI/CLI layers.
- **No `unsafe`** unless strictly required at FFI boundaries, and always
  documented with a `// SAFETY:` comment.
- **Documentation**: public items carry `///` doc comments describing intent and
  invariants.

### FFI Boundary Rules

- Keep the Dart↔Rust contract thin and explicit. Business rules live in Rust
  (`crates/`) or in shared Dart domain types — not split inconsistently across
  the bridge.
- After changing Rust code under `crates/pirate-ffi-frb`, **always** run
  `make frb` and commit the regenerated bindings in the same patch.

### Testing & Documentation Expectations

- Every behavioral change ships with tests: Rust unit/integration tests
  (`make test:rust`) and Flutter tests (`make test:flutter`). Bug fixes start
  with a failing reproduction test.
- Do not weaken, skip, or disable tests to make a build pass.
- Update relevant docs under `docs/` when changing security, transport, signing,
  storage, or updater behavior.

### Definition of Done (before opening a PR)

1. `make format` applied (Dart + Rust).
2. `make lint` is clean — no new warnings or analyzer issues.
3. `make test:rust test:flutter` passes; new/changed behavior is covered.
4. FFI changes regenerated via `make frb` and committed together.
5. Changes are small, focused, and free of duplicated logic / dead code.

---

## ❄️ Nix Flake

If you use Nix, you can enter a shell with all dependencies pre-installed:

```bash
nix develop
```

---

## 📝 Development Workflow for Agents

1.  **Context**: Always check `crates/` for core logic and `app/` for UI.
2.  **FFI Changes**: If you modify Rust code that is exposed to Flutter (under `crates/pirate-ffi-frb`), you **must** run `make frb` to update the Dart bindings.
3.  **Validation**: Before submitting changes, run `make lint` and `make test:rust test:flutter` to ensure no regressions.
