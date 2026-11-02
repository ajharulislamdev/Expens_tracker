import 'dart:typed_data';
import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';

class AccountModel {
  const AccountModel({
    required this.name,
    required this.phoneNumber,
    required this.passwordSalt,
    required this.passwordHash,
    required this.isLoggedIn,
    this.photoBytes,
    this.usesPin = false,
  });

  final String name;
  final String phoneNumber;
  final String passwordSalt;
  final String passwordHash;
  final Uint8List? photoBytes;
  final bool isLoggedIn;
  final bool usesPin;

  AccountModel copyWith({
    String? name,
    String? phoneNumber,
    String? passwordSalt,
    String? passwordHash,
    Uint8List? photoBytes,
    bool clearPhoto = false,
    bool? isLoggedIn,
    bool? usesPin,
  }) {
    return AccountModel(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
      photoBytes: clearPhoto ? null : photoBytes ?? this.photoBytes,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      usesPin: usesPin ?? this.usesPin,
    );
  }
}

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = HiveBoxes.accountModelId;

  @override
  AccountModel read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, count = reader.readByte(); i < count; i++)
        reader.readByte(): reader.read(),
    };

    return AccountModel(
      name: fields[0] as String,
      phoneNumber: fields[1] as String,
      passwordSalt: fields[2] as String,
      passwordHash: fields[3] as String,
      photoBytes: fields[4] as Uint8List?,
      isLoggedIn: fields[5] as bool,
      usesPin: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel account) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(account.name)
      ..writeByte(1)
      ..write(account.phoneNumber)
      ..writeByte(2)
      ..write(account.passwordSalt)
      ..writeByte(3)
      ..write(account.passwordHash)
      ..writeByte(4)
      ..write(account.photoBytes)
      ..writeByte(5)
      ..write(account.isLoggedIn)
      ..writeByte(6)
      ..write(account.usesPin);
  }
}
