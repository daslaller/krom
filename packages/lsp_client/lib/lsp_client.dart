/// Pure Dart LSP client — JSON-RPC 2.0 over stdio.
///
/// Zero Flutter dependency; publishable on pub.dev.
library lsp_client;

export 'src/lifecycle.dart' show LspClient;
export 'src/diagnostics.dart';
export 'src/completion.dart';
export 'src/hover.dart';
export 'src/definition.dart';
export 'src/formatting.dart';
export 'src/references.dart';
export 'src/rename.dart';
export 'src/symbols.dart';
export 'src/text_sync.dart';
