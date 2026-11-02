import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import 'transaction_type.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  /// Positive for income, negative for expense.
  double get signedAmount => isIncome ? amount : -amount;

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    TransactionType? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
    );
  }

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  @override
  String toString() =>
      'TransactionModel($id, $title, $amount, $date, $category, $type)';
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = HiveBoxes.transactionTypeId;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return TransactionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      category: fields[4] as String,
      type: fields[5] as TransactionType,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.type);
  }
}
