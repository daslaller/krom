# dart_lsp_client

Pure Dart [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) client — JSON-RPC 2.0 over stdio with Content-Length framing.

Zero Flutter dependency. Usable from any Dart CLI, editor, or tool.

## Usage

```yaml
dependencies:
  lsp_client:
    git:
      url: https://github.com/daslaller/dart_lsp_client.git
```

```dart
import 'package:lsp_client/lsp_client.dart';

final client = await LspClient.start(
  serverCommand: ['dart', 'language-server', '--protocol=lsp'],
  rootUri: Uri.directory('/path/to/project').toString(),
);

client.diagnostics.listen((params) { /* ... */ });

await client.openDocument(
  uri: Uri.file('/path/to/project/lib/main.dart').toString(),
  languageId: 'dart',
  text: source,
);
```

## Features

- Lifecycle (`initialize` / `shutdown`)
- Text document sync (full and incremental)
- Diagnostics, completion, hover, definition, references, rename
- Document formatting

## Develop / test

```bash
dart pub get
dart analyze
dart test
```

## Related projects

- [krom](https://github.com/daslaller/krom) — Flutter desktop editor using this client
- [krom-parser](https://github.com/daslaller/krom-parser) — tree-sitter daemon with its own `parser_client`
