import 'package:flutter/foundation.dart';
import '../frontends/ide_concepts/krom_motion.dart';

class NavigationPulse extends ChangeNotifier {
  int? _line;
  int? get line => _line;
  void pulse(int l) {
    _line = l;
    notifyListeners();
    Future<void>.delayed(KromMotion.goToDefPulseDuration, () {
      if (_line == l) { _line = null; notifyListeners(); }
    });
  }
}
