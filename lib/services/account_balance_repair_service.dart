import '../models/local_models.dart';
import 'app_database.dart';
import 'sync_mapper.dart';
import 'sync_outbox.dart';

class AccountBalanceRepairService {
  AccountBalanceRepairService({
    required AppDatabase db,
    SyncOutboxWriter? outboxWriter,
  })  : _db = db,
        _outboxWriter = outboxWriter ?? SyncOutboxWriter(db);

  static const _tolerance = 0.005;

  final AppDatabase _db;
  final SyncOutboxWriter _outboxWriter;

  Future<int> repair({required String userId}) async {
    final accounts = await _db.getAccounts(userId: userId);
    final movements = await _db.getAccountMovementTotals(userId);
    final balances = <String, double>{
      for (final account in accounts)
        account.accountId:
            account.openingBalance + (movements[account.accountId] ?? 0),
    };

    final accountsToRepair = <AccountEntity>[];
    for (final account in accounts) {
      final expected = balances[account.accountId];
      if (expected != null &&
          (account.currentBalance - expected).abs() > _tolerance) {
        accountsToRepair.add(account);
      }
    }

    if (accountsToRepair.isEmpty) {
      return 0;
    }

    var repairedCount = 0;
    final now = DateTime.now().toUtc();
    await _db.transaction((txn) async {
      for (final account in accountsToRepair) {
        final expected = balances[account.accountId];
        if (expected == null) continue;

        account
          ..currentBalance = expected
          ..updatedAt = now;
        await _db.putAccount(account, txn: txn);
        await _outboxWriter.enqueueInTxn(
          userId: userId,
          entityType: 'accounts',
          entityId: account.accountId,
          payload: SyncPayloadMapper.account(account),
          txn: txn,
        );
        repairedCount++;
      }
    });

    return repairedCount;
  }

}
