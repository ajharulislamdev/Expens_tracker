import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';

enum PlanType { goal, budget }

class PlanTypeAdapter extends TypeAdapter<PlanType> {
  @override
  final int typeId = HiveBoxes.planTypeEnumId;

  @override
  PlanType read(BinaryReader reader) =>
      reader.readByte() == 0 ? PlanType.goal : PlanType.budget;

  @override
  void write(BinaryWriter writer, PlanType obj) {
    writer.writeByte(obj == PlanType.goal ? 0 : 1);
  }
}

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.type,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final PlanType type;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  PlanModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    PlanType? type,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      type: type ?? this.type,
    );
  }

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

class PlanModelAdapter extends TypeAdapter<PlanModel> {
  @override
  final int typeId = HiveBoxes.planModelId;

  @override
  PlanModel read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, count = reader.readByte(); i < count; i++)
        reader.readByte(): reader.read(),
    };

    return PlanModel(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: (fields[2] as num).toDouble(),
      currentAmount: (fields[3] as num).toDouble(),
      type: fields[4] as PlanType,
    );
  }

  @override
  void write(BinaryWriter writer, PlanModel plan) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(plan.id)
      ..writeByte(1)
      ..write(plan.name)
      ..writeByte(2)
      ..write(plan.targetAmount)
      ..writeByte(3)
      ..write(plan.currentAmount)
      ..writeByte(4)
      ..write(plan.type);
  }
}
