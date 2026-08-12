import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fakes/fake_database_helper.dart';
import 'package:cookpilot/ingredients_list_screen.dart';
import 'package:cookpilot/auth_service.dart';

void main() {
  setUp(() async {
    // initialize shared prefs with device id
    final deviceId = const Uuid().v4();
    SharedPreferences.setMockInitialValues({
      'cookpilot_device_user_id': deviceId,
    });
    await AuthService.instance.init();

    // init ffi DB factory for any DB operations in tests
    sqfliteFfiInit();
  });

  testWidgets('shows loading then empty state', (WidgetTester tester) async {
    final repo = FakeDatabaseHelper(
      initial: [],
      delay: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(
      MaterialApp(home: IngredientsListScreen(repository: repo)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('No items found'), findsOneWidget);
  });

  testWidgets('shows error state when repo throws', (
    WidgetTester tester,
  ) async {
    final repo = FakeDatabaseHelper(initial: [], throwOnGet: true);

    await tester.pumpWidget(
      MaterialApp(home: IngredientsListScreen(repository: repo)),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to load'), findsOneWidget);
  });

  testWidgets('selection and delete flow', (WidgetTester tester) async {
    final deviceId = AuthService.instance.getCurrentUserIdSync();
    final repo = FakeDatabaseHelper(
      initial: [
        {
          'id': 1,
          'name': 'Apple',
          'quantity': '2',
          'expiryDate': null,
          'note': '',
          'userId': deviceId,
        },
        {
          'id': 2,
          'name': 'Banana',
          'quantity': '5',
          'expiryDate': null,
          'note': '',
          'userId': deviceId,
        },
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: IngredientsListScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    // tap first checkbox
    final firstCheckbox = find.byType(Checkbox).first;
    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();

    // press delete icon
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // confirm dialog
    expect(find.text('Delete ingredients?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Apple should be deleted
    expect(find.text('Apple'), findsNothing);
    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('expiry shows warning under 3 days', (WidgetTester tester) async {
    final deviceId = AuthService.instance.getCurrentUserIdSync();
    final today = DateTime.now();
    final twoDays = today.add(const Duration(days: 2));
    final iso =
        '${twoDays.year.toString().padLeft(4, '0')}-${twoDays.month.toString().padLeft(2, '0')}-${twoDays.day.toString().padLeft(2, '0')}';

    final repo = FakeDatabaseHelper(
      initial: [
        {
          'id': 1,
          'name': 'Milk',
          'quantity': '1L',
          'expiryDate': iso,
          'note': '',
          'userId': deviceId,
        },
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: IngredientsListScreen(repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('days left'), findsWidgets);
  });
}
