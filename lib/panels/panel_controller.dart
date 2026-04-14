import 'package:flutter/foundation.dart';

enum PanelType { fileTree }

class PanelController extends ChangeNotifier {
  PanelType? _activePanel;

  PanelType? get activePanel => _activePanel;
  bool get isOpen => _activePanel != null;

  void toggle(PanelType panel) {
    _activePanel = _activePanel == panel ? null : panel;
    notifyListeners();
  }

  void close() {
    if (_activePanel != null) {
      _activePanel = null;
      notifyListeners();
    }
  }
}
