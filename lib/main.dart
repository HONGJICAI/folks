import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/fake_repository.dart';
import 'data/repository.dart';
import 'l10n/l10n.dart';
import 'locale_controller.dart';
import 'screens/circle_tab.dart';
import 'screens/family_tab.dart';
import 'screens/memory_tab.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FolksApp());
}

class FolksApp extends StatelessWidget {
  const FolksApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repository（数据层）+ LocaleController（语言）一起注入全 App。
    return MultiProvider(
      providers: [
        Provider<FolksRepository>(create: (_) => FakeRepository()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, localeCtrl, _) => MaterialApp(
          onGenerateTitle: (ctx) => ctx.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: localeCtrl.locale, // null = 跟随系统
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const HomeShell(),
        ),
      ),
    );
  }
}

/// 底部三 Tab 导航外壳。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    FamilyTab(),
    CircleTab(),
    MemoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.account_tree_outlined),
            selectedIcon: const Icon(Icons.account_tree),
            label: t.tabFamily,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: t.tabCircle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: const Icon(Icons.favorite),
            label: t.tabMemory,
          ),
        ],
      ),
    );
  }
}
