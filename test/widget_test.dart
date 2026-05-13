import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo/main.dart';

void main() {
  testWidgets('shows the todo screen in light mode by default', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_tips': true,
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('A focused space for what matters today'), findsOneWidget);
  });
}
