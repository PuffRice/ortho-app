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
    final transactions = await _db.getTransactions(userId: userId, limit: 1000000);
    final transfers = await _db.getTransfers(userId: userId);

    final balances = <String, double>{
      for (final account in accounts) account.accountId: account.openingBalance,
    };

    for (final transaction in transactions) {
      if (!balances.containsKey(transaction.accountId)) {
        continue;
      }
      balances[transaction.accountId] = balances[transaction.accountId]! +
          _transactionDelta(transaction.type, transaction.amount);
    }

    for (final transfer in transfers) {
      if (balances.containsKey(transfer.fromAccountId)) {
        balances[transfer.fromAccountId] =
            balances[transfer.fromAccountId]! - transfer.amount;
      }
      if (balances.containsKey(transfer.toAccountId)) {
        balances[transfer.toAccountId] =
            balances[transfer.toAccountId]! + transfer.amount;
      }
    }

    var repairedCount = 0;
    final now = DateTime.now();
    await _db.transaction((txn) async {
      for (final account in accounts) {
        final expected = balances[account.accountId];
        if (expected == null ||
            (account.currentBalance - expected).abs() <= _tolerance) {
          continue;
        }

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

  double _transactionDelta(String type, double amount) {
    if (type == 'income') {
      return amount;
    }
    if (type == 'expense') {
      return -amount;
    }
    return 0;
  }
}
