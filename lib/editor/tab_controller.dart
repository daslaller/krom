import 'package:flutter/foundation.dart';
import 'tab_model.dart';

class KromTabController extends ChangeNotifier {
  final List<TabModel> _tabs = [];
  int _activeIndex = -1;

  List<TabModel> get tabs => _tabs;
  int get activeIndex => _activeIndex;
  TabModel? get activeTab =>
      _activeIndex >= 0 && _activeIndex < _tabs.length
          ? _tabs[_activeIndex]
          : null;

  void openFile(String path, String content, {bool useParser = true}) {
    final existing = _tabs.indexWhere((t) => t.filePath == path);
    if (existing != -1) {
      _activeIndex = existing;
      notifyListeners();
      return;
    }
    _tabs.add(TabModel(
      filePath: path,
      content: content,
      useParser: useParser,
    ));
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs[index].dispose();
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      _activeIndex = -1;
    } else if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
    notifyListeners();
  }

  void setActive(int index) {
    if (index < 0 || index >= _tabs.length || index == _activeIndex) return;
    _activeIndex = index;
    notifyListeners();
  }

  void nextTab() {
    if (_tabs.length < 2) return;
    _activeIndex = (_activeIndex + 1) % _tabs.length;
    notifyListeners();
  }

  void markDirty(int index) {
    if (index < 0 || index >= _tabs.length) return;
    if (!_tabs[index].isDirty) {
      _tabs[index].isDirty = true;
      notifyListeners();
    }
  }

  void markClean(int index) {
    if (index < 0 || index >= _tabs.length) return;
    if (_tabs[index].isDirty) {
      _tabs[index].isDirty = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }
}
