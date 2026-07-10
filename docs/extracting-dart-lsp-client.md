# Extracting dart_lsp_client

The `lsp_client` package was removed from this repo. It lives in the public
[`Dart_LSP_Client`](https://github.com/daslaller/Dart_LSP_Client) repository.

## One-time setup (repo owner)

If `dart_lsp_client` does not exist yet on GitHub:

```bash
# From a machine with repo-create access
gh repo create daslaller/Dart_LSP_Client --public \
  --description "Pure Dart LSP client — JSON-RPC over stdio, zero Flutter dependency"

# Copy bootstrap bundle (includes full package source)
cp -r docs/dart_lsp_client-bootstrap/* /tmp/dart_lsp_client/

cd /tmp/dart_lsp_client
git init && git branch -M main
git add -A
git commit -m "Initial commit: pure Dart LSP client"
git remote add origin https://github.com/daslaller/Dart_LSP_Client.git
git push -u origin main
```

After the repo exists, `flutter pub get` in krom will resolve `lsp_client` from git.

## parser_client

`parser_client` is in [krom-parser/clients/dart](https://github.com/daslaller/krom-parser/tree/main/clients/dart) on `main`.
