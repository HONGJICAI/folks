import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// 外观设置（内存态；mock 阶段重启重置，接 SQLite/偏好存储后再持久化）。
class SettingsController extends ChangeNotifier {
  AppStyle _style = AppStyle.play;
  ThemeMode _themeMode = ThemeMode.system;

  AppStyle get style => _style;
  ThemeMode get themeMode => _themeMode;

  void setStyle(AppStyle s) {
    _style = s;
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    _themeMode = m;
    notifyListeners();
  }
}
