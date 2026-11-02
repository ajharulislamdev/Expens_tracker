import 'dart:typed_data';
import 'package:get/get.dart';
import '../../../core/services/password_hasher.dart';
import '../../../core/utils/mobile_number.dart';
import '../../../core/utils/security_pin.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';

class AuthController extends GetxController {
  AuthController(this._repository);

  final AccountRepository _repository;
  final Rxn<AccountModel> account = Rxn<AccountModel>();

  bool get isAuthenticated => account.value?.isLoggedIn ?? false;
  bool get hasAccount => account.value != null;

  AccountModel get _signedInAccount {
    final current = account.value;
    if (current == null || !current.isLoggedIn) {
      throw StateError('No signed-in local account is available.');
    }
    return current;
  }

  @override
  void onInit() {
    super.onInit();
    account.value = _repository.account;
  }

  Future<void> createAccount({
    required String name,
    required String phoneNumber,
    required String pin,
  }) async {
    if (hasAccount) {
      throw StateError('A local account already exists.');
    }
    final pinError = SecurityPin.validate(pin);
    if (pinError != null) throw ArgumentError(pinError);

    final salt = PasswordHasher.generateSalt();
    final hash = await PasswordHasher.hash(pin, salt);
    final newAccount = AccountModel(
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      passwordSalt: salt,
      passwordHash: hash,
      isLoggedIn: true,
      usesPin: true,
    );
    await _repository.save(newAccount);
    account.value = newAccount;
  }

  Future<bool> login({
    required String phoneNumber,
    required String credential,
  }) async {
    final savedAccount = _repository.account;
    if (savedAccount == null) {
      return false;
    }
    final normalizedPhone = MobileNumber.digitsOnly(phoneNumber);
    final matchesPhone = normalizedPhone.isNotEmpty &&
        MobileNumber.digitsOnly(savedAccount.phoneNumber) == normalizedPhone;
    final matchesLegacyEmail = savedAccount.phoneNumber.contains('@') &&
        savedAccount.phoneNumber.toLowerCase() ==
            phoneNumber.trim().toLowerCase();
    if (!matchesPhone && !matchesLegacyEmail) return false;

    if (savedAccount.usesPin && SecurityPin.validate(credential) != null) {
      return false;
    }
    final hash = await PasswordHasher.hash(
      credential,
      savedAccount.passwordSalt,
    );
    if (!PasswordHasher.matches(savedAccount.passwordHash, hash)) return false;

    final signedInAccount = savedAccount.copyWith(isLoggedIn: true);
    await _repository.save(signedInAccount);
    account.value = signedInAccount;
    return true;
  }

  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
  }) async {
    final current = _signedInAccount;
    final updated = current.copyWith(
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
    );
    await _repository.save(updated);
    account.value = updated;
  }

  Future<void> updatePhoto(Uint8List? bytes) async {
    final current = _signedInAccount;
    final updated = bytes == null
        ? current.copyWith(clearPhoto: true)
        : current.copyWith(photoBytes: bytes);
    await _repository.save(updated);
    account.value = updated;
  }

  Future<bool> changePin({
    required String currentCredential,
    required String newPin,
  }) async {
    final current = _signedInAccount;

    final pinError = SecurityPin.validate(newPin);
    if (pinError != null) throw ArgumentError(pinError);
    final currentHash = await PasswordHasher.hash(
      currentCredential,
      current.passwordSalt,
    );
    if (!PasswordHasher.matches(current.passwordHash, currentHash)) {
      return false;
    }

    final salt = PasswordHasher.generateSalt();
    final hash = await PasswordHasher.hash(newPin, salt);
    final updated = current.copyWith(
      passwordSalt: salt,
      passwordHash: hash,
      usesPin: true,
    );
    await _repository.save(updated);
    account.value = updated;
    return true;
  }

  Future<bool> recoverPin({
    required String currentCredential,
    required String newPin,
  }) async {
    final current = _repository.account;
    if (current == null) return false;

    final pinError = SecurityPin.validate(newPin);
    if (pinError != null) throw ArgumentError(pinError);
    if (current.usesPin && SecurityPin.validate(currentCredential) != null) {
      return false;
    }

    final currentHash = await PasswordHasher.hash(
      currentCredential,
      current.passwordSalt,
    );
    if (!PasswordHasher.matches(current.passwordHash, currentHash)) {
      return false;
    }

    final salt = PasswordHasher.generateSalt();
    final hash = await PasswordHasher.hash(newPin, salt);
    final updated = current.copyWith(
      passwordSalt: salt,
      passwordHash: hash,
      usesPin: true,
    );
    await _repository.save(updated);
    account.value = updated;
    return true;
  }

  Future<void> logout() async {
    final current = _signedInAccount;
    final signedOutAccount = current.copyWith(isLoggedIn: false);
    await _repository.save(signedOutAccount);
    account.value = signedOutAccount;
  }

  Future<void> deleteAccount() async {
    await _repository.delete();
    account.value = null;
  }
}
