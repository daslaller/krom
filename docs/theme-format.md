# Krom theme JSON format

User themes: `~/.config/krom/themes/*.json` (Windows: `%APPDATA%/Krom/themes/`).

See `lib/frontends/ide_concepts/theme_json.dart` for the parser and full schema.

## Import / export

- Palette → **Export Theme JSON** — save active theme to a file.
- Palette → **Import Theme JSON** — copy into user themes dir and apply.

## Semantic highlighting

`lsp_client` does not yet expose `semanticTokens`. See `LspService.semanticTokensSupported`.
