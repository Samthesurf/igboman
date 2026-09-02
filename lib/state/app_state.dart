import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  int _xp = 0;
  int _streakDays = 0;

  int get xp => _xp;
  set xp(int value) {
    if (_xp != value) {
      _xp = value;
      notifyListeners();
    }
  }

  int get streakDays => _streakDays;
  set streakDays(int value) {
    if (_streakDays != value) {
      _streakDays = value;
      notifyListeners();
    }
  }
}
