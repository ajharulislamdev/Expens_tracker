import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/models/transaction_type.dart';
import 'package:expense_tracker/modules/transactions/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders transaction rows without a reactive balance', (
    tester,
  ) async {
    final transaction = TransactionModel(
      id: 'test-transaction',
      title: 'Lunch',
      amount: 12.5,
      date: DateTime(2026, 11, 3, 12),
      category: 'Food',
      type: TransactionType.expense,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTile(tx: transaction),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Lunch'), findsOneWidget);
  });
}
