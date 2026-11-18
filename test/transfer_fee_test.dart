import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:financetracker/cqrs/commands.dart';
import 'package:financetracker/cqrs/handlers_sqlite.dart';
import 'package:financetracker/models/local_models.dart';
import 'package:financetracker/services/app_database.dart';
import 'package:financetracker/services/sync_outbox.dart';

void main() {
  late _MemoryDb db;
  late SyncOutboxWriter outbox;
  final date = DateTime.utc(2026, 11, 18, 8, 15);

  Future<void> create({double fee = 5}) => CreateTransferHandler(db, outbox).handle(
    CreateTransferCommand(userId: 'u', transferId: 't', fromAccountId: 'a',
      toAccountId: 'b', amount: 100, date: date, fee: fee));

  test('receipt bytes belong to transactions and survive model round trips', () {
    final receipt = Uint8List.fromList([1, 2, 3, 4]);
    final transaction = TransactionEntity()..receiptBytes = receipt;
    final loaded = TransactionEntity.fromMap(transaction.toMap());
    expect(loaded.receiptBytes, receipt);
    expect(loaded.hasReceipt, isTrue);
    expect(CategoryEntity().toMap().containsKey('receipt_bytes'), isFalse);
    final metadata = transaction.toMap()..remove('receipt_bytes');
    metadata['has_receipt'] = 1;
    expect(TransactionEntity.fromMap(metadata).hasReceipt, isTrue);
    expect(TransactionEntity.fromMap(metadata).receiptBytes, isNull);
  });

  setUp(() {
    db = _MemoryDb();
    outbox = SyncOutboxWriter(db);
  });

  test('fee debits source, preserves timestamp, appears in expense summaries', () async {
    await create();
    expect(db.accounts['a']!['current_balance'], 895);
    expect(db.accounts['b']!['current_balance'], 100);
    final fee = TransactionEntity.fromMap(db.transactions['transfer-fee:t']!);
    expect(fee.amount, 5);
    expect(fee.accountId, 'a');
    expect(fee.categoryId, 'fees');
    expect(fee.type, 'expense');
    expect(fee.note, 'Transfer Fee');
    expect(fee.date, date);
    expect(db.summaries.values.every((s) => s.totalExpense == 5), isTrue);
    expect(db.outbox.map((e) => e.entityType), containsAll(['transfers', 'transactions']));
  });

  test('missing or deleted category rolls back transfer, balances and outbox', () async {
    for (final deleted in [false, true]) {
      db = _MemoryDb();
      outbox = SyncOutboxWriter(db);
      if (deleted) {
        db.category.deletedAt = date;
      } else {
        db.setting = null;
      }
      await expectLater(create(), throwsA(isA<TransferFeeCategoryRequired>()));
      expect(db.accounts['a']!['current_balance'], 1000);
      expect(db.accounts['b']!['current_balance'], 0);
      expect(db.transfers, isEmpty);
      expect(db.transactions, isEmpty);
      expect(db.outbox, isEmpty);
    }
  });

  test('fee-free transfers work without category; invalid fees roll back', () async {
    db.setting = null;
    await create(fee: 0);
    expect(db.transactions, isEmpty);
    db = _MemoryDb();
    outbox = SyncOutboxWriter(db);
    await expectLater(create(fee: -1), throwsArgumentError);
    expect(db.transfers, isEmpty);
  });

  test('editing source, amount and date replaces fee; deleting reverses both', () async {
    await create();
    await UpdateTransferHandler(db, outbox).handle(UpdateTransferCommand(
      userId: 'u', transferId: 't', fromAccountId: 'b', toAccountId: 'a',
      amount: 20, fee: 2, date: date.add(const Duration(days: 1))));
    expect(db.accounts['a']!['current_balance'], 1020);
    expect(db.accounts['b']!['current_balance'], -22);
    expect(db.transactions.length, 1);
    final fee = TransactionEntity.fromMap(db.transactions['transfer-fee:t']!);
    expect(fee.accountId, 'b');
    expect(fee.amount, 2);
    expect(fee.date, date.add(const Duration(days: 1)));
    await DeleteTransferHandler(db, outbox).handle(
      const DeleteTransferCommand(userId: 'u', transferId: 't'));
    expect(db.accounts['a']!['current_balance'], 1000);
    expect(db.accounts['b']!['current_balance'], 0);
    expect(db.transactions['transfer-fee:t']!['deleted_at'], isNotNull);
    expect(db.summaries.values.every((s) => s.totalExpense == 0), isTrue);
  });

  test('setting fee to zero soft-deletes it and restores its debit', () async {
    await create();
    db.setting = null;
    await UpdateTransferHandler(db, outbox).handle(UpdateTransferCommand(
      userId: 'u', transferId: 't', fromAccountId: 'a', toAccountId: 'b',
      amount: 100, date: date, fee: 0));
    expect(db.accounts['a']!['current_balance'], 900);
    expect(db.transactions['transfer-fee:t']!['deleted_at'], isNotNull);
  });
}

// Runs the real handlers and outbox writer against a transactional in-memory
// store, without requiring a device or SQLite platform channel.
class _MemoryDb implements AppDatabase {
  _MemoryDb() {
    for (final id in ['a', 'b']) {
      accounts[id] = (AccountEntity()
        ..userId = 'u' ..accountId = id ..currency = 'BDT'
        ..currentBalance = (id == 'a' ? 1000 : 0)).toMap();
    }
  }
  Map<String, Map<String, Object?>> accounts = {};
  Map<String, Map<String, Object?>> transfers = {};
  Map<String, Map<String, Object?>> transactions = {};
  List<SyncOutboxEntity> outbox = [];
  final summaries = <String, SummaryCacheEntity>{};
  String? setting = 'fees';
  final category = CategoryEntity()..userId = 'u'..categoryId = 'fees'..type = 'expense';

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final oldAccounts = Map.of(accounts);
    final oldTransfers = Map.of(transfers);
    final oldTransactions = Map.of(transactions);
    final oldOutbox = List.of(outbox);
    try {
      return await action(_MemoryTransaction());
    } catch (_) {
      accounts = oldAccounts; transfers = oldTransfers;
      transactions = oldTransactions; outbox = oldOutbox;
      rethrow;
    }
  }
  @override
  Future<String?> getTransferFeeCategory(String userId) async => setting;
  @override
  Future<CategoryEntity?> getCategoryByUserAndCategoryId(String userId, String categoryId) async =>
    categoryId == category.categoryId ? category : null;
  @override
  Future<AccountEntity?> getAccountByUserAndAccountId(String userId, String accountId) async =>
    accounts[accountId] == null ? null : AccountEntity.fromMap(accounts[accountId]!);
  @override
  Future<TransferEntity?> getTransferByUserAndTransferId(String userId, String transferId) async =>
    transfers[transferId] == null ? null : TransferEntity.fromMap(transfers[transferId]!);
  @override
  Future<TransactionEntity?> getTransactionByUserAndTransactionId(String userId, String transactionId) async =>
    transactions[transactionId] == null ? null : TransactionEntity.fromMap(transactions[transactionId]!);
  @override
  Future<void> putAccount(AccountEntity account, {Transaction? txn}) async { accounts[account.accountId] = account.toMap(); }
  @override
  Future<void> putTransfer(TransferEntity transfer, {Transaction? txn}) async { transfers[transfer.transferId] = transfer.toMap(); }
  @override
  Future<void> putTransaction(TransactionEntity transaction, {Transaction? txn}) async { transactions[transaction.transactionId] = transaction.toMap(); }
  @override
  Future<int> putSyncOutbox(SyncOutboxEntity entry, {Transaction? txn}) async { outbox.add(entry); return outbox.length; }
  @override
  Future<void> putSummaryCache(SummaryCacheEntity summary, {Transaction? txn}) async { summaries[summary.summaryKey] = summary; }
  @override
  Future<List<TransactionEntity>> getTransactions({required String userId,
    String? accountId, String? categoryId, String? type, DateTime? start,
    DateTime? end, int? limit = 200, bool includeReceipts = false, bool deletedOnly = false}) async =>
      transactions.values.map(TransactionEntity.fromMap).where((tx) =>
        tx.userId == userId && tx.deletedAt == null && tx.type == type &&
        (start == null || !tx.date.isBefore(start)) &&
        (end == null || !tx.date.isAfter(end))).toList();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryTransaction implements Transaction {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
