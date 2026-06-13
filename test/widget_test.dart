// 冒烟测试：App 能起来，且底部三个 Tab 都在。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:folks/main.dart';

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
    expect(find.text('赵狗蛋(狗蛋)'), findsOneWidget);

    // 点进狗蛋详情
    await tester.tap(find.text('赵狗蛋(狗蛋)'));
    await tester.pumpAndSettle();

    // 删除 → 确认
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    // 回到家族树，狗蛋应已消失
    expect(find.text('赵狗蛋(狗蛋)'), findsNothing);
  });
}
