# Extracting dart_lsp_client

The `lsp_client` package was removed from this repo. It lives in the public
[`dart_lsp_client`](https://github.com/daslaller/dart_lsp_client) repository.

## One-time setup (repo owner)

If `dart_lsp_client` does not exist yet on GitHub:

```bash
# From a machine with repo-create access
gh repo create daslaller/dart_lsp_client --public \
  --description "Pure Dart LSP client — JSON-RPC over stdio, zero Flutter dependency"

# Copy bootstrap bundle (includes full package source)
cp -r docs/dart_lsp_client-bootstrap/* /tmp/dart_lsp_client/

cd /tmp/dart_lsp_client
git init && git branch -M main
git add -A
git commit -m "Initial commit: pure Dart LSP client"
git remote add origin https://github.com/daslaller/dart_lsp_client.git
git push -u origin main
```

After the repo exists, `flutter pub get` in krom will resolve `lsp_client` from git.

## parser_client

`parser_client` is now in [krom-parser/clients/dart](https://github.com/daslaller/krom-parser/tree/cursor/move-parser-client-969a/clients/dart).
Merge [krom-parser PR #4](https://github.com/daslaller/krom-parser/pull/4), then change `ref:` in `pubspec.yaml` to `main` (or remove `ref`).
