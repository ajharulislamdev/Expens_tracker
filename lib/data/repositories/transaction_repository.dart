import '../models/summary_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../providers/hive_provider.dart';

class TransactionRepository {
  TransactionRepository(this._provider);

  final HiveProvider _provider;

  List<TransactionModel> getAll() => _provider.transactionBox.values.toList();

  Future<void> add(TransactionModel t) =>
      _provider.transactionBox.put(t.id, t);

  Future<void> update(TransactionModel t) =>
      _provider.transactionBox.put(t.id, t);

  Future<void> delete(String id) => _provider.transactionBox.delete(id);

  Future<void> clearAll() async {
    await _provider.transactionBox.clear();
  }

  static SummaryModel summarize(Iterable<TransactionModel> items) {
    double income = 0;
    double expense = 0;
    int count = 0;
    for (final t in items) {
      count++;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return SummaryModel(income: income, expense: expense, count: count);
  }
}
