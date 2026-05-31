import 'package:isar/isar.dart';

import '../models/isar_models.dart';
import 'sync_mapper.dart';
import 'sync_outbox.dart';

class AccountBalanceRepairService {
  AccountBalanceRepairService({
    required Isar isar,
    SyncOutboxWriter? outboxWriter,
  })  : _isar = isar,
        _outboxWriter = outboxWriter ?? SyncOutboxWriter(isar);

  static const _tolerance = 0.005;

  final Isar _isar;
  final SyncOutboxWriter _outboxWriter;

  Future<int> repair({required String userId}) async {
    final accounts = await _isar.accountEntitys
        .filter()
        .userIdEqualTo(userId)
        .deletedAtIsNull()
        .findAll();
    final transactions = await _isar.transactionEntitys
        .filter()
        .userIdEqualTo(userId)
        .deletedAtIsNull()
        .findAll();
    final transfers = await _isar.transferEntitys
        .filter()
        .userIdEqualTo(userId)
        .deletedAtIsNull()
        .findAll();

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
    await _isar.writeTxn(() async {
      for (final account in accounts) {
        final expected = balances[account.accountId];
        if (expected == null ||
            (account.currentBalance - expected).abs() <= _tolerance) {
          continue;
        }

        account
          ..currentBalance = expected
          ..updatedAt = now;
        await _isar.accountEntitys.put(account);
        await _outboxWriter.enqueueInTxn(
          userId: userId,
          entityType: 'accounts',
          entityId: account.accountId,
          payload: SyncPayloadMapper.account(account),
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
