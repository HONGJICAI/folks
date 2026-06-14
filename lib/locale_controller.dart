import 'package:flutter/material.dart';

/// 应用语言控制器。null = 跟随系统；否则强制中/英。
class LocaleController extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  void setLocale(Locale? l) {
    _locale = l;
    notifyListeners();
  }
}
