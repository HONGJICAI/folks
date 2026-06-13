// 冒烟测试：App 能起来，且底部三个 Tab 都在。
import 'package:flutter_test/flutter_test.dart';

import 'package:folks/main.dart';

void main() {
  testWidgets('App boots with three tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const FolksApp());
    await tester.pumpAndSettle();

    expect(find.text('家族'), findsWidgets);
    expect(find.text('圈子'), findsWidgets);
    expect(find.text('回忆'), findsWidgets);
  });
}
