# AGENTS.md

## Cursor Cloud specific instructions

Krom is a Flutter desktop code editor (tabbed editor, file tree, `Ctrl+P` command
palette, syntax highlighting, Dart LSP integration, and a tree-sitter structure
client). It contains two pure-Dart support packages: `packages/lsp_client` (LSP
transport + semantics) and `packages/parser_client` (stdio `Content-Length`
transport for the krom-parser daemon). Standard Flutter/Dart commands apply; only
the non-obvious cloud caveats are captured here.

### Toolchain (already installed in the VM snapshot)

- Flutter `3.44.5` stable / Dart `3.12.2` at `~/flutter/bin` (on `PATH` via
  `~/.bashrc`, with the Linux desktop target enabled). This is the minimum that
  satisfies `pubspec.yaml` (`sdk: ^3.12.0-278.0.dev`).
- Linux desktop build deps (`clang`, `cmake`, `ninja-build`, `pkg-config`,
  `libgtk-3-dev`, plus `libstdc++-14-dev` so `clang++` links) are installed.

### Commands

- Dependencies: `flutter pub get` at the repo root. Each `packages/*` package is a
  **separate pub package** and needs its own `dart pub get` run from inside it
  before being analyzed/tested standalone (the startup update script does this).
- Lint: `flutter analyze` (root).
- Test: `flutter test` (root widget test); `dart test` inside each `packages/*`.
- Run (dev, hot reload): `flutter run -d linux` — requires `DISPLAY=:1`.
- Build (dev): `flutter build linux --debug`.

### Non-obvious caveats

- Only the `windows/` platform is committed. The Linux desktop target was
  generated with `flutter create --platforms=linux .`; the `linux/` folder lives
  in the VM snapshot but is **not committed** (and is not in `.gitignore`, so do
  not `git add` it). If it is ever missing, regenerate it with that command, then
  `git checkout -- .metadata pubspec.lock` since `flutter create` rewrites those
  tracked files.
- The GUI runs on X display `:1` with software rendering; the `libEGL ... DRI3`
  warning at startup is harmless.
- The editor opens the current working directory as its workspace
  (`Directory.current.path`) and indexes the file list / command palette **once at
  startup**. Create files before launching, or hot-restart (`R` in `flutter run`)
  to re-index.
- Pre-existing issues at HEAD, unrelated to the environment (do **not** "fix" these
  as setup work):
  - `lib/editor/hover_tooltip.dart` has two compile errors — `KromTypography.code()`
    is called with an undefined `fontSize:` argument, and `PointerHoverEvent` is
    used without importing `package:flutter/gestures.dart`. Until the app code is
    fixed these block `flutter build` / `flutter run` / `flutter test`.
  - After that, `flutter test` still hits a `RenderFlex` overflow in the empty-state
    UI at the 800x600 test surface, and `packages/lsp_client` `dart test` has one
    failing framing assertion (a `contains` matcher passed a `List<int>` instead of
    an element).
