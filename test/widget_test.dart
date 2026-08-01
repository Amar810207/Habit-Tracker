import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/providers/habit_provider.dart';

void main() {
  testWidgets('Habit Tracker smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitProvider(),
        child: const HabitTrackerApp(),
      ),
    );

    expect(find.text('Habit Tracker'), findsOneWidget);
  });
}
