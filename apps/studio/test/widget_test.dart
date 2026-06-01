import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_hr_studio/main.dart';

void main() {
  testWidgets('Recruitment app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const RecruitmentApp());
    expect(find.text('招聘筛选网关'), findsOneWidget);
    expect(find.text('收件箱'), findsOneWidget);
  });
}
