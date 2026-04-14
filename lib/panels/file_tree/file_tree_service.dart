import 'dart:io';
import 'package:path/path.dart' as p;
import 'file_tree_node.dart';

class FileTreeService {
  static const _ignored = {
    '.dart_tool',
    '.idea',
    '.git',
    '.vs',
    '.vscode',
    'node_modules',
    'build',
    '__pycache__',
    '.gradle',
    'target',
    '.pub-cache',
    '.pub',
  };

  Future<FileTreeNode> buildTree(String rootPath) async {
    final dir = Directory(rootPath);
    final children = await _buildChildren(dir);
    return FileTreeNode(
      name: p.basename(rootPath),
      path: rootPath,
      isDirectory: true,
      children: children,
    )..isExpanded = true;
  }

  Future<List<FileTreeNode>> _buildChildren(Directory dir) async {
    final entities = await dir.list().toList();
    final nodes = <FileTreeNode>[];

    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') && _ignored.contains(name)) continue;
      if (_ignored.contains(name)) continue;

      if (entity is Directory) {
        final children = await _buildChildren(entity);
        nodes.add(FileTreeNode(
          name: name,
          path: entity.path,
          isDirectory: true,
          children: children,
        ));
      } else if (entity is File) {
        nodes.add(FileTreeNode(
          name: name,
          path: entity.path,
          isDirectory: false,
        ));
      }
    }

    nodes.sort();
    return nodes;
  }

  Future<List<String>> allFilePaths(String rootPath) async {
    final paths = <String>[];
    await _collectFiles(Directory(rootPath), paths);
    return paths;
  }

  Future<void> _collectFiles(Directory dir, List<String> paths) async {
    final entities = await dir.list().toList();
    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (_ignored.contains(name)) continue;

      if (entity is Directory) {
        await _collectFiles(entity, paths);
      } else if (entity is File) {
        paths.add(entity.path);
      }
    }
  }
}
