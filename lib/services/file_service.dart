import 'dart:io';

class FileService {
  Future<String> readFile(String path) => File(path).readAsString();

  Future<void> writeFile(String path, String content) =>
      File(path).writeAsString(content);

  Future<List<FileSystemEntity>> listDirectory(String path) =>
      Directory(path).list().toList();
}
