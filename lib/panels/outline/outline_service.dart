import 'package:path/path.dart' as p;

class OutlineSymbol {
  const OutlineSymbol({
    required this.name,
    required this.kind,
    required this.line,
  });

  final String name;
  final String kind; // 'class', 'function', 'method', 'field'
  final int line; // 0-indexed
}

/// Extracts top-level symbols from source code using regex patterns.
///
/// Upgrade path: replace each _extract* method body with a tree-sitter query
/// once flutter_tree_sitter language grammar packages are available.
/// The OutlineSymbol model and public API stay the same.
class OutlineService {
  List<OutlineSymbol> extract(String content, String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return switch (ext) {
      '.dart' => _extractDart(content),
      '.py' => _extractPython(content),
      '.js' || '.jsx' || '.ts' || '.tsx' => _extractJs(content),
      '.go' => _extractGo(content),
      '.rs' => _extractRust(content),
      _ => const [],
    };
  }

  List<OutlineSymbol> _extractDart(String content) {
    final symbols = <OutlineSymbol>[];
    final lines = content.split('\n');

    // Top-level type declarations
    final typeRe = RegExp(
      r'^\s*(?:abstract\s+)?(?:class|mixin|enum|extension)\s+(\w+)',
    );
    // Top-level and instance method/function declarations
    // Matches: optional modifiers + return type + name + (
    final methodRe = RegExp(
      r'^\s{0,2}(?:static\s+|async\s+|external\s+)*'
      r'(?:Future<[^>]+>|Stream<[^>]+>|\w[\w<>\[\]?, ]*\??)\s+'
      r'(\w+)\s*(?:<[^>]*>)?\s*\(',
    );
    // Exclude keywords that look like method calls
    const dartKeywords = {
      'if', 'else', 'for', 'while', 'switch', 'return', 'throw',
      'assert', 'await', 'yield', 'print', 'super', 'this',
    };

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      final typeMatch = typeRe.firstMatch(line);
      if (typeMatch != null) {
        final name = typeMatch.group(1)!;
        final kind = line.contains('enum')
            ? 'enum'
            : line.contains('extension')
                ? 'extension'
                : line.contains('mixin')
                    ? 'mixin'
                    : 'class';
        symbols.add(OutlineSymbol(name: name, kind: kind, line: i));
        continue;
      }

      final methodMatch = methodRe.firstMatch(line);
      if (methodMatch != null) {
        final name = methodMatch.group(1)!;
        if (!dartKeywords.contains(name) && !name.startsWith('_') || true) {
          // Include all names including private ones
          final isTopLevel = !line.startsWith('  ') || line.startsWith('  ') && !line.startsWith('   ');
          symbols.add(OutlineSymbol(
            name: name,
            kind: isTopLevel ? 'function' : 'method',
            line: i,
          ));
        }
      }
    }

    return symbols;
  }

  List<OutlineSymbol> _extractPython(String content) {
    final symbols = <OutlineSymbol>[];
    final lines = content.split('\n');
    final re = RegExp(r'^(class|def)\s+(\w+)');

    for (var i = 0; i < lines.length; i++) {
      final m = re.firstMatch(lines[i]);
      if (m != null) {
        symbols.add(OutlineSymbol(
          name: m.group(2)!,
          kind: m.group(1) == 'class' ? 'class' : 'function',
          line: i,
        ));
      }
    }
    return symbols;
  }

  List<OutlineSymbol> _extractJs(String content) {
    final symbols = <OutlineSymbol>[];
    final lines = content.split('\n');

    // function declarations and class declarations
    final funcRe = RegExp(
      r'^(?:export\s+)?(?:default\s+)?(?:async\s+)?function\s+(\w+)',
    );
    final classRe = RegExp(r'^(?:export\s+)?(?:default\s+)?class\s+(\w+)');
    // Arrow functions: const foo = () => or const foo = async () =>
    final arrowRe = RegExp(
      r'^(?:export\s+)?(?:const|let)\s+(\w+)\s*=\s*(?:async\s*)?\(',
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final classMatch = classRe.firstMatch(line);
      if (classMatch != null) {
        symbols.add(
          OutlineSymbol(name: classMatch.group(1)!, kind: 'class', line: i),
        );
        continue;
      }
      final funcMatch = funcRe.firstMatch(line);
      if (funcMatch != null) {
        symbols.add(
          OutlineSymbol(name: funcMatch.group(1)!, kind: 'function', line: i),
        );
        continue;
      }
      final arrowMatch = arrowRe.firstMatch(line);
      if (arrowMatch != null) {
        symbols.add(
          OutlineSymbol(name: arrowMatch.group(1)!, kind: 'function', line: i),
        );
      }
    }
    return symbols;
  }

  List<OutlineSymbol> _extractGo(String content) {
    final symbols = <OutlineSymbol>[];
    final lines = content.split('\n');
    final funcRe = RegExp(r'^func\s+(?:\(\w+\s+\*?\w+\)\s+)?(\w+)\s*\(');
    final typeRe = RegExp(r'^type\s+(\w+)\s+(?:struct|interface)');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final typeMatch = typeRe.firstMatch(line);
      if (typeMatch != null) {
        symbols.add(
          OutlineSymbol(name: typeMatch.group(1)!, kind: 'class', line: i),
        );
        continue;
      }
      final funcMatch = funcRe.firstMatch(line);
      if (funcMatch != null) {
        symbols.add(
          OutlineSymbol(name: funcMatch.group(1)!, kind: 'function', line: i),
        );
      }
    }
    return symbols;
  }

  List<OutlineSymbol> _extractRust(String content) {
    final symbols = <OutlineSymbol>[];
    final lines = content.split('\n');
    final funcRe = RegExp(r'^(?:pub\s+)?(?:async\s+)?fn\s+(\w+)');
    final typeRe = RegExp(r'^(?:pub\s+)?(?:struct|enum|trait|impl)\s+(\w+)');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final typeMatch = typeRe.firstMatch(line);
      if (typeMatch != null) {
        final kind = line.contains('fn') ? 'function'
            : line.contains('struct') || line.contains('enum') ? 'class'
            : 'interface';
        symbols.add(OutlineSymbol(name: typeMatch.group(1)!, kind: kind, line: i));
        continue;
      }
      final funcMatch = funcRe.firstMatch(line);
      if (funcMatch != null) {
        symbols.add(
          OutlineSymbol(name: funcMatch.group(1)!, kind: 'function', line: i),
        );
      }
    }
    return symbols;
  }
}
