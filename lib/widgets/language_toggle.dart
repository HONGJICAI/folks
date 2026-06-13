import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../locale_controller.dart';

/// 顶栏共用的「中/英」切换按钮（设置页之前的简易入口）。
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final active = Localizations.localeOf(context);
    return IconButton(
      icon: const Icon(Icons.translate),
      tooltip: active.languageCode == 'zh' ? 'English' : '中文',
      onPressed: () => context.read<LocaleController>().toggle(active),
    );
  }
}
