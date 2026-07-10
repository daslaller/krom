# AGENTS.md

## Cursor Cloud specific instructions

Krom is a Flutter desktop code editor (tabbed editor, file tree, `Ctrl+P` command
palette, syntax highlighting, and optional Dart LSP integration). It contains two
supporting pure-Dart packages: `packages/lsp_client` (LSP transport/semantics)
and `packages/parser_client` (stdio client for the `krom-parser` daemon).
Standard Flutter/Dart commands apply; only the non-obvious cloud caveats are
captured here.

### Toolchain (already installed in the VM snapshot)

- Flutter `3.44.5` stable / Dart `3.12.2` at `~/flutter/bin` (on `PATH` via `~/.bashrc`).
  This is the minimum that satisfies `pubspec.yaml` (`flutter >=3.38`, `dart >=3.12.0-278.0.dev`).
- Linux desktop build deps (`clang`, `cmake`, `ninja-build`, `pkg-config`,
  `libgtk-3-dev`, plus `libstdc++-14-dev` so `clang++` links) are installed.

### Commands

- Dependencies: `flutter pub get` at the repo root. `packages/lsp_client` and
  `packages/parser_client` are **separate pub packages** and each needs its own
  `dart pub get` run from inside the package before it can be analyzed/tested
  standalone.
- Lint: `flutter analyze` (root). Note it reports `undefined_function` errors for
  `packages/lsp_client/test/*` because that package's `test` dev-dependency isn't
  resolved in the root context — analyze that package on its own with
  `dart analyze` inside `packages/lsp_client`.
- Test: `flutter test` (root widget test) and `dart test` inside each package
  (`packages/lsp_client`, `packages/parser_client`).
- Run (dev, hot reload): `flutter run -d linux` — requires `DISPLAY=:1`.
- Build (dev): `flutter build linux --debug`.

### Non-obvious caveats

- Only the `windows/` platform is committed. To run on this Linux VM a Linux
  desktop target was generated with `flutter create --platforms=linux .` (the
  `linux/` folder lives in the VM snapshot but is **not committed**). If it is
  ever missing, regenerate it with that command, then `git checkout -- .metadata
  pubspec.lock` since `flutter create` rewrites those tracked files.
- The GUI runs on X display `:1` with software rendering; the `libEGL ... DRI3`
  warning at startup is harmless.
- The editor opens the current working directory as its workspace
  (`Directory.current.path`), and indexes the file list / command palette **once
  at startup**. Create files before launching, or hot-restart (`R` in
  `flutter run`) to re-index.
- Pre-existing code/test failures unrelated to the environment (do NOT "fix" as
  setup work — the toolchain itself is verified working):
  - **The app currently does not compile as committed.** `lib/editor/hover_tooltip.dart`
    references `PointerHoverEvent` without importing `package:flutter/gestures.dart`
    (line 72) and passes a `fontSize:` argument to `KromTypography.code()` (line 61),
    which only accepts `color`. This breaks `flutter build linux`, `flutter run`, and
    `flutter test` (the widget test imports the app). A future task fixing these two
    lines is what makes the GUI buildable; environment setup does not touch app code.
  - `packages/lsp_client` `dart test` has one failing assertion in "LspTransport
    framing" (a `contains` matcher passed a `List<int>` instead of an element).
  - `packages/parser_client` `dart test` and `dart analyze` are clean.
