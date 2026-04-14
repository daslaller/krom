class FileTreeNode implements Comparable<FileTreeNode> {
  FileTreeNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });

  final String name;
  final String path;
  final bool isDirectory;
  final List<FileTreeNode> children;
  bool isExpanded = false;

  @override
  int compareTo(FileTreeNode other) {
    if (isDirectory != other.isDirectory) {
      return isDirectory ? -1 : 1;
    }
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }
}
