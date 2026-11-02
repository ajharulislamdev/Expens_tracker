import '../models/account_model.dart';
import '../providers/hive_provider.dart';

class AccountRepository {
  AccountRepository(this._provider);

  final HiveProvider _provider;

  static const _accountKey = 'local_account';

  AccountModel? get account => _provider.accountBox.get(_accountKey);

  Future<void> save(AccountModel account) =>
      _provider.accountBox.put(_accountKey, account);

  Future<void> delete() => _provider.accountBox.delete(_accountKey);
}
