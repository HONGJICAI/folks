import 'package:flutter/material.dart';

/// 应用语言控制器。null = 跟随系统；否则强制中/英。
class LocaleController extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  static const _zh = Locale('zh');
  static const _en = Locale('en');

  /// 在 中 / 英 之间切换。首次点按时，依据当前生效语言决定切到另一种。
  void toggle(Locale active) {
    final goingEnglish = active.languageCode == 'zh';
    _locale = goingEnglish ? _en : _zh;
    notifyListeners();
  }
}
