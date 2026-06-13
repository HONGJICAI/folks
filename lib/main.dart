import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/fake_repository.dart';
import 'data/repository.dart';
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
    // 用 Provider 把 Repository 注入全 App。当前是 FakeRepository（内存假数据）；
    // 后端阶段只需把这一行换成 SqliteRepository()，其余代码不动。
    return Provider<FolksRepository>(
      create: (_) => FakeRepository(),
      child: MaterialApp(
        title: 'Folks 身边人',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomeShell(),
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
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: '家族',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: '圈子',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: '回忆',
          ),
        ],
      ),
    );
  }
}
