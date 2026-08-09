import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_hr_studio/main.dart';

void main() {
  testWidgets('Workbench renders with navigation rail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WorkbenchApp());

    // 侧边导航栏：绩效为主页（导航 label + 页面标题各一处）
    expect(find.text('绩效'), findsNWidgets(2));
    expect(find.text('招聘'), findsOneWidget);
  });
}
