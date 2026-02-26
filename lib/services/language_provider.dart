import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isHindi = false;

  bool get isHindi => _isHindi;

  void toggleLanguage() {
    _isHindi = !_isHindi;
    notifyListeners(); // This tells the whole app to rebuild
  }

  // Helper function to return correct text
  String translate(String en, String hi) {
    return _isHindi ? hi : en;
  }
}