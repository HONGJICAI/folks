// 冒烟测试：App 能起来，且底部三个 Tab 都在。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:folks/l10n/l10n.dart';
import 'package:folks/main.dart';
import 'package:folks/models/person.dart';
import 'package:folks/widgets/family_tree_chart.dart';

/// 把测试固定到中文 locale，断言才稳定（否则默认英文）。
void _useChinese(WidgetTester tester) {
  tester.platformDispatcher.localesTestValue = const [Locale('zh')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

void main() {
  testWidgets('App boots with three tabs', (WidgetTester tester) async {
    _useChinese(tester);
    await tester.pumpWidget(const FolksApp());
    await tester.pumpAndSettle();

    expect(find.text('家族'), findsWidgets);
    expect(find.text('圈子'), findsWidgets);
    expect(find.text('回忆'), findsWidgets);
  });

  testWidgets('删除家族成员后，家族树里不再显示他', (WidgetTester tester) async {
    _useChinese(tester);
    await tester.pumpWidget(const FolksApp());
    await tester.pumpAndSettle();

    // 家族树里应能看到狗蛋
    expect(find.text('狗蛋'), findsOneWidget);

    // 点进狗蛋详情
    await tester.tap(find.text('狗蛋'));
    await tester.pumpAndSettle();

    // 删除 → 确认
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    // 回到家族树，狗蛋应已消失
    expect(find.text('狗蛋'), findsNothing);
  });

  testWidgets('未登记为配偶的共同父母不会重复整支', (WidgetTester tester) async {
    _useChinese(tester);
    // 本人←爸爸；爸爸←阿公(父)+阿婆(母)，但阿公阿婆未设为配偶。
    // 用多字名，避免与头像首字（单字）撞，影响 find.text 计数。
    final people = [
      const Person(id: 1, name: '本人', isSelf: true, fatherId: 2),
      const Person(id: 2, name: '爸爸', fatherId: 3, motherId: 4),
      const Person(id: 3, name: '阿公'),
      const Person(id: 4, name: '阿婆'),
    ];
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FamilyTreeChart(people: people, onOpen: (_) {}, onSwap: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    // 爸爸 / 本人 各只出现一次（修复前会各出现两次）。
    expect(find.text('爸爸'), findsOneWidget);
    expect(find.text('本人'), findsOneWidget);
    expect(find.text('阿公'), findsOneWidget);
    expect(find.text('阿婆'), findsOneWidget);
  });
}
