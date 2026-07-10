# AGENTS.md

## Cursor Cloud specific instructions

Krom is a Flutter desktop code editor (tabbed editor, file tree, `Ctrl+P` command
palette, syntax highlighting, and optional Dart LSP integration). Client packages
are external:

- `parser_client` — [krom-parser/clients/dart](https://github.com/daslaller/krom-parser/tree/main/clients/dart)
- `lsp_client` — [dart_lsp_client](https://github.com/daslaller/dart_lsp_client)

Standard Flutter/Dart commands apply; only the non-obvious cloud caveats are captured here.

### Toolchain (already installed in the VM snapshot)

- Flutter `3.44.5` stable / Dart `3.12.2` at `~/flutter/bin` (on `PATH` via `~/.bashrc`).
  This is the minimum that satisfies `pubspec.yaml` (`flutter >=3.38`, `dart >=3.12.0-278.0.dev`).
- Linux desktop build deps (`clang`, `cmake`, `ninja-build`, `pkg-config`,
  `libgtk-3-dev`, plus `libstdc++-14-dev` so `clang++` links) are installed.

### Commands

- Dependencies: `flutter pub get` at the repo root (fetches git deps above).
- Lint: `flutter analyze` (root).
- Test: `flutter test` (root widget test). Run `dart test` inside each client repo separately.
- Run (dev, hot reload): `flutter run -d linux` — requires `DISPLAY=:1`.
- Build (dev): `flutter build linux --debug`.

### Non-obvious caveats

- Only the `windows/` platform is committed. To run on this Linux VM a Linux
  desktop target was generated with `flutter create --platforms=linux .` (the
  `linux/` folder lives in the VM snapshot but is **not committed**). If it is
  ever missing, regenerate it with that command, then `git checkout -- .metadata
  pubspec.lock` since `flutter create` rewrites those tracked files.
- The GUI runs on X display `:1` with software rendering; the `EGL ... DRI3`
  warning at startup is harmless.
- The editor opens the current working directory as its workspace
  (`Directory.current.path`), and indexes the file list / command palette **once
  at startup**. Create files before launching, or hot-restart (`R` in
  `flutter run`) to re-index.
- If `dart_lsp_client` is not on GitHub yet, see `docs/extracting-dart-lsp-client.md`.
