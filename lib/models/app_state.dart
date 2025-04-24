// lib/models/app_state.dart

import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;

  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;

  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
