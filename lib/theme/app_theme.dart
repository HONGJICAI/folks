/// 集中式设计系统入口。
///
/// 支持两套视觉风格，改 [appStyle] 一行即可整 App 切换、对比：
/// - [AppStyle.clean]：清爽现代（纯白底、细描边、利落极简）
/// - [AppStyle.play]：Material You / Google Play 原味（染色表面、大圆角、tonal 容器）
///
/// 规矩：页面里**不要硬编码** `Color(0xFF...)`，一律走 `Theme.of(context)`，
/// 换风格/换皮只改这个文件。
library;

import 'package:flutter/material.dart';

enum AppStyle { clean, play }

class AppTheme {
  AppTheme._();

  /// 品牌主色：利落的蓝。换主色改这里。
  static const Color seed = Color(0xFF2563EB);

  static ThemeData light(AppStyle style) => _forStyle(style, Brightness.light);
  static ThemeData dark(AppStyle style) => _forStyle(style, Brightness.dark);

  static ThemeData _forStyle(AppStyle style, Brightness brightness) {
    return switch (style) {
      AppStyle.clean => _clean(brightness),
      AppStyle.play => _play(brightness),
    };
  }

  // ---------------- 清爽现代 ----------------
  static ThemeData _clean(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    if (brightness == Brightness.light) {
      scheme = scheme.copyWith(surface: Colors.white); // 纯白卡面
    }
    final canvas = brightness == Brightness.light
        ? const Color(0xFFF6F7F9)
        : scheme.surfaceContainerLowest;

    return _assemble(
      scheme,
      canvas: canvas,
      cardColor: scheme.surface,
      cardBorder: BorderSide(color: scheme.outlineVariant),
      radius: 12,
      chipBg: scheme.surface,
      chipFg: scheme.primary,
      chipBorder: BorderSide(color: scheme.outlineVariant),
      navBg: scheme.surface,
      navIndicator: scheme.primaryContainer,
    );
  }

  // ---------------- Material You / Play 原味 ----------------
  static ThemeData _play(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return _assemble(
      scheme,
      // 背景与卡片都用带主色调的"染色"表面，靠色阶分层（Material You 标志性做法）。
      canvas: scheme.surface,
      cardColor: scheme.surfaceContainerHigh,
      cardBorder: BorderSide.none,
      radius: 24, // 大圆角、圆润
      chipBg: scheme.secondaryContainer, // tonal 填充标签
      chipFg: scheme.onSecondaryContainer,
      chipBorder: BorderSide.none,
      navBg: scheme.surfaceContainer,
      navIndicator: scheme.secondaryContainer,
    );
  }

  // ---------------- 两套风格共用的装配 ----------------
  static ThemeData _assemble(
    ColorScheme scheme, {
    required Color canvas,
    required Color cardColor,
    required BorderSide cardBorder,
    required double radius,
    required Color chipBg,
    required Color chipFg,
    required BorderSide chipBorder,
    required Color navBg,
    required Color navIndicator,
  }) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: canvas,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: cardBorder,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        labelStyle: TextStyle(color: chipFg, fontSize: 12),
        side: chipBorder,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        elevation: 0,
        height: 64,
        indicatorColor: navIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 1,
      ),
    );
  }
}

/// 设计尺度（间距 / 圆角）的统一常量，避免页面里写魔法数字。
/// 注意：卡片圆角由 ThemeData.cardTheme 控制（随风格变），这里的 radius 仅供局部小元件用。
class Dim {
  Dim._();
  static const double gap = 12;
  static const double pad = 16;
  static const double radius = 12;
}
