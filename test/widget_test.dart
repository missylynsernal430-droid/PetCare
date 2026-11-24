import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/main.dart';
import 'package:petcare/providers/pet_care_provider.dart';
import 'package:petcare/services/local_database.dart';
import 'package:petcare/services/notification_service.dart';
import 'package:provider/provider.dart';

class _EmptyDatabase extends LocalDatabase {
  @override
  Future<List<Map<String, Object?>>> readAll(String table) async => [];

  @override
  Future<void> insert(String table, Map<String, Object?> values) async {}
}

void main() {
  testWidgets('shows the pet empty state and five navigation tabs', (
    tester,
  ) async {
    final provider = PetCareProvider(_EmptyDatabase(), NotificationService());
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const PetCareApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pets yet'), findsOneWidget);
    expect(find.text('My pets'), findsNWidgets(2));
    expect(find.text('Feeding'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
  });

  testWidgets('adding a pet closes the editor and updates the home screen', (
    tester,
  ) async {
    final provider = PetCareProvider(_EmptyDatabase(), NotificationService());
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const PetCareApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add pet').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Milo');
    await tester.enterText(find.byType(TextFormField).at(1), '4');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Milo'), findsOneWidget);
    expect(find.text('Dog · 4 years old'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
