import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';

enum TransactionType { expense, income }

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = HiveBoxes.transactionTypeEnumId;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 1:
        return TransactionType.income;
      case 0:
      default:
        return TransactionType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeByte(obj == TransactionType.income ? 1 : 0);
  }
}
