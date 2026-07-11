import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class ExtensionManifest {
  const ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    this.commands = const [],
    this.directory,
  });

  final String id;
  final String name;
  final String version;
  final List<ExtensionCommand> commands;
  final String? directory;

  factory ExtensionManifest.fromJson(
    Map<String, dynamic> json, {
    String? directory,
  }) {
    return ExtensionManifest(
      id: json['id'] as String? ?? 'x',
      name: json['name'] as String? ?? 'Ext',
      version: json['version'] as String? ?? '0',
      commands: (json['commands'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ExtensionCommand.fromJson(e.cast<String, dynamic>()))
          .toList(),
      directory: directory,
    );
  }
}

class ExtensionCommand {
  const ExtensionCommand({
    required this.id,
    required this.label,
    this.hint,
    this.action,
  });

  final String id;
  final String label;
  final String? hint;
  final String? action;

  factory ExtensionCommand.fromJson(Map<String, dynamic> json) {
    return ExtensionCommand(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      hint: json['hint'] as String?,
      action: json['action'] as String?,
    );
  }

  String paletteId(String extensionId) => 'ext:$extensionId:$id';
}

class ExtensionLoader {
  static Directory extensionsDir() => Directory(
        p.join(Platform.environment['HOME'] ?? '', '.config', 'krom', 'extensions'),
      );

  static Future<List<ExtensionManifest>> loadAll() async {
    final dir = extensionsDir();
    if (!dir.existsSync()) return [];
    final out = <ExtensionManifest>[];
    for (final entry in dir.listSync()) {
      if (entry is! Directory) continue;
      final manifest = File(p.join(entry.path, 'manifest.json'));
      if (!manifest.existsSync()) continue;
      try {
        out.add(
          ExtensionManifest.fromJson(
            jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>,
            directory: entry.path,
          ),
        );
      } catch (_) {}
    }
    return out;
  }

  static Future<void> runCommandAction(
    ExtensionManifest manifest,
    ExtensionCommand command,
  ) async {
    final action = command.action;
    final dir = manifest.directory;
    if (action == null || dir == null) return;
    final parts = action.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;
    await Process.start(
      parts.first,
      parts.skip(1).toList(),
      workingDirectory: dir,
      mode: ProcessStartMode.detached,
    );
  }
}
