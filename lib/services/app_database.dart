import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/local_models.dart';

class AppDatabase {
  AppDatabase._(this._database);

  static const _dbName = 'financetracker.sqlite';
  static const _dbVersion = 1;

  final Database _database;

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, _dbName);
    final database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createSchema,
    );
    return AppDatabase._(database);
  }

  Future<void> close() => _database.close();

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) {
    return _database.transaction(action);
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        photo_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE accounts (
        account_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        logo_base64 TEXT,
        opening_balance REAL NOT NULL,
        current_balance REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_accounts_user_id ON accounts(user_id)');
    await db.execute('''
      CREATE TABLE categories (
        category_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color INTEGER,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_categories_user_id ON categories(user_id)');
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        is_recurring INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_transactions_user_id ON transactions(user_id)');
    await db.execute('CREATE INDEX idx_transactions_account_id ON transactions(account_id)');
    await db.execute('CREATE INDEX idx_transactions_category_id ON transactions(category_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('''
      CREATE TABLE transfers (
        transfer_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        from_account_id TEXT NOT NULL,
        to_account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_transfers_user_id ON transfers(user_id)');
    await db.execute('CREATE INDEX idx_transfers_date ON transfers(date)');
    await db.execute('''
      CREATE TABLE budgets (
        budget_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        period TEXT NOT NULL,
        amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_budgets_user_id ON budgets(user_id)');
    await db.execute('CREATE INDEX idx_budgets_category_id ON budgets(category_id)');
    await db.execute('''
      CREATE TABLE recurring_transactions (
        recurring_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        interval TEXT NOT NULL,
        next_run_at TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_recurring_user_id ON recurring_transactions(user_id)');
    await db.execute('CREATE INDEX idx_recurring_next_run_at ON recurring_transactions(next_run_at)');
    await db.execute('''
      CREATE TABLE payment_card_credentials (
        card_credential_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        bank_logo_base64 TEXT,
        card_type TEXT NOT NULL,
        network TEXT NOT NULL,
        cardholder_name TEXT NOT NULL,
        card_number TEXT NOT NULL,
        expiry TEXT NOT NULL,
        has_nfc INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_payment_card_user_id ON payment_card_credentials(user_id)');
    await db.execute('''
      CREATE TABLE bank_account_credentials (
        bank_credential_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        bank_logo_base64 TEXT,
        branch_name TEXT NOT NULL,
        account_name TEXT NOT NULL,
        account_number TEXT NOT NULL,
        routing_number TEXT NOT NULL,
        swift_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_bank_account_user_id ON bank_account_credentials(user_id)');
    await db.execute('''
      CREATE TABLE summary_cache (
        summary_key TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        period TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        total_income REAL NOT NULL,
        total_expense REAL NOT NULL,
        net REAL NOT NULL,
        by_category_json TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_summary_cache_user_id ON summary_cache(user_id)');
    await db.execute('''
      CREATE TABLE sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        status TEXT NOT NULL,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT,
        attempts INTEGER NOT NULL,
        last_error TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_sync_outbox_user_id ON sync_outbox(user_id)');
    await db.execute('CREATE INDEX idx_sync_outbox_status ON sync_outbox(status)');
    await db.execute('CREATE INDEX idx_sync_outbox_last_error ON sync_outbox(last_error)');
  }

  Future<void> putUser(UserEntity user, {Transaction? txn}) {
    return _insert('users', user.toMap(), txn: txn);
  }

  Future<void> putAccount(AccountEntity account, {Transaction? txn}) {
    return _insert('accounts', account.toMap(), txn: txn);
  }

  Future<void> putCategory(CategoryEntity category, {Transaction? txn}) {
    return _insert('categories', category.toMap(), txn: txn);
  }

  Future<void> putTransaction(TransactionEntity transaction, {Transaction? txn}) {
    return _insert('transactions', transaction.toMap(), txn: txn);
  }

  Future<void> putTransfer(TransferEntity transfer, {Transaction? txn}) {
    return _insert('transfers', transfer.toMap(), txn: txn);
  }

  Future<void> putBudget(BudgetEntity budget, {Transaction? txn}) {
    return _insert('budgets', budget.toMap(), txn: txn);
  }

  Future<void> putRecurring(RecurringTransactionEntity recurring, {Transaction? txn}) {
    return _insert('recurring_transactions', recurring.toMap(), txn: txn);
  }

  Future<void> putPaymentCardCredential(
    PaymentCardCredentialEntity credential, {
    Transaction? txn,
  }) {
    return _insert('payment_card_credentials', credential.toMap(), txn: txn);
  }

  Future<void> putBankAccountCredential(
    BankAccountCredentialEntity credential, {
    Transaction? txn,
  }) {
    return _insert('bank_account_credentials', credential.toMap(), txn: txn);
  }

  Future<void> putSummaryCache(SummaryCacheEntity summary, {Transaction? txn}) {
    return _insert('summary_cache', summary.toMap(), txn: txn);
  }

  Future<int> putSyncOutbox(SyncOutboxEntity entry, {Transaction? txn}) {
    return _insert('sync_outbox', entry.toMap(includeId: false), txn: txn);
  }

  Future<void> putUsers(List<UserEntity> users, {Transaction? txn}) async {
    for (final entry in users) {
      await putUser(entry, txn: txn);
    }
  }

  Future<void> putAccounts(List<AccountEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putAccount(entry, txn: txn);
    }
  }

  Future<void> putCategories(List<CategoryEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putCategory(entry, txn: txn);
    }
  }

  Future<void> putTransactions(List<TransactionEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putTransaction(entry, txn: txn);
    }
  }

  Future<void> putTransfers(List<TransferEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putTransfer(entry, txn: txn);
    }
  }

  Future<void> putBudgets(List<BudgetEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putBudget(entry, txn: txn);
    }
  }

  Future<void> putRecurringTransactions(List<RecurringTransactionEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putRecurring(entry, txn: txn);
    }
  }

  Future<void> putPaymentCardCredentials(List<PaymentCardCredentialEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putPaymentCardCredential(entry, txn: txn);
    }
  }

  Future<void> putBankAccountCredentials(List<BankAccountCredentialEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putBankAccountCredential(entry, txn: txn);
    }
  }

  Future<void> putSyncOutboxAll(List<SyncOutboxEntity> items, {Transaction? txn}) async {
    for (final entry in items) {
      await putSyncOutbox(entry, txn: txn);
    }
  }

  Future<UserEntity?> getUserByUserId(String userId) async {
    final rows = await _query('users', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    return rows.isEmpty ? null : UserEntity.fromMap(rows.first);
  }

  Future<AccountEntity?> getAccountByUserAndAccountId(String userId, String accountId) async {
    final rows = await _query('accounts', where: 'user_id = ? AND account_id = ?', whereArgs: [userId, accountId], limit: 1);
    return rows.isEmpty ? null : AccountEntity.fromMap(rows.first);
  }

  Future<CategoryEntity?> getCategoryByUserAndCategoryId(String userId, String categoryId) async {
    final rows = await _query('categories', where: 'user_id = ? AND category_id = ?', whereArgs: [userId, categoryId], limit: 1);
    return rows.isEmpty ? null : CategoryEntity.fromMap(rows.first);
  }

  Future<TransactionEntity?> getTransactionByUserAndTransactionId(String userId, String transactionId) async {
    final rows = await _query('transactions', where: 'user_id = ? AND transaction_id = ?', whereArgs: [userId, transactionId], limit: 1);
    return rows.isEmpty ? null : TransactionEntity.fromMap(rows.first);
  }

  Future<TransferEntity?> getTransferByUserAndTransferId(String userId, String transferId) async {
    final rows = await _query('transfers', where: 'user_id = ? AND transfer_id = ?', whereArgs: [userId, transferId], limit: 1);
    return rows.isEmpty ? null : TransferEntity.fromMap(rows.first);
  }

  Future<BudgetEntity?> getBudgetByUserAndBudgetId(String userId, String budgetId) async {
    final rows = await _query('budgets', where: 'user_id = ? AND budget_id = ?', whereArgs: [userId, budgetId], limit: 1);
    return rows.isEmpty ? null : BudgetEntity.fromMap(rows.first);
  }

  Future<RecurringTransactionEntity?> getRecurringByUserAndRecurringId(String userId, String recurringId) async {
    final rows = await _query('recurring_transactions', where: 'user_id = ? AND recurring_id = ?', whereArgs: [userId, recurringId], limit: 1);
    return rows.isEmpty ? null : RecurringTransactionEntity.fromMap(rows.first);
  }

  Future<PaymentCardCredentialEntity?> getPaymentCardCredentialByUserAndId(String userId, String cardCredentialId) async {
    final rows = await _query('payment_card_credentials', where: 'user_id = ? AND card_credential_id = ?', whereArgs: [userId, cardCredentialId], limit: 1);
    return rows.isEmpty ? null : PaymentCardCredentialEntity.fromMap(rows.first);
  }

  Future<BankAccountCredentialEntity?> getBankAccountCredentialByUserAndId(String userId, String bankCredentialId) async {
    final rows = await _query('bank_account_credentials', where: 'user_id = ? AND bank_credential_id = ?', whereArgs: [userId, bankCredentialId], limit: 1);
    return rows.isEmpty ? null : BankAccountCredentialEntity.fromMap(rows.first);
  }

  Future<SummaryCacheEntity?> getSummaryByKey(String summaryKey) async {
    final rows = await _query('summary_cache', where: 'summary_key = ?', whereArgs: [summaryKey], limit: 1);
    return rows.isEmpty ? null : SummaryCacheEntity.fromMap(rows.first);
  }

  Future<List<UserEntity>> getUsersByUserId(String userId) async {
    return (await _query('users', where: 'user_id = ?', whereArgs: [userId])).map(UserEntity.fromMap).toList();
  }

  Future<List<AccountEntity>> getAccounts({required String userId, bool deletedOnly = false}) async {
    final rows = await _query(
      'accounts',
      where: deletedOnly ? 'user_id = ? AND deleted_at IS NOT NULL' : 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(AccountEntity.fromMap).toList();
  }

  Future<List<CategoryEntity>> getCategories({required String userId, String? type, bool deletedOnly = false}) async {
    final clauses = <String>['user_id = ?'];
    final args = <Object?>[userId];
    clauses.add(deletedOnly ? 'deleted_at IS NOT NULL' : 'deleted_at IS NULL');
    if (type != null) {
      clauses.add('type = ?');
      args.add(type);
    }
    final rows = await _query('categories', where: clauses.join(' AND '), whereArgs: args, orderBy: 'sort_order ASC, name COLLATE NOCASE ASC');
    return rows.map(CategoryEntity.fromMap).toList();
  }

  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? accountId,
    String? categoryId,
    String? type,
    DateTime? start,
    DateTime? end,
    int limit = 200,
    bool deletedOnly = false,
  }) async {
    final clauses = <String>['user_id = ?'];
    final args = <Object?>[userId];
    clauses.add(deletedOnly ? 'deleted_at IS NOT NULL' : 'deleted_at IS NULL');
    if (accountId != null) {
      clauses.add('account_id = ?');
      args.add(accountId);
    }
    if (categoryId != null) {
      clauses.add('category_id = ?');
      args.add(categoryId);
    }
    if (type != null) {
      clauses.add('type = ?');
      args.add(type);
    }
    if (start != null) {
      clauses.add('date >= ?');
      args.add(start.toUtc().toIso8601String());
    }
    if (end != null) {
      clauses.add('date <= ?');
      args.add(end.toUtc().toIso8601String());
    }
    final rows = await _query(
      'transactions',
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(TransactionEntity.fromMap).toList();
  }

  Future<List<TransferEntity>> getTransfers({
    required String userId,
    DateTime? start,
    DateTime? end,
    bool deletedOnly = false,
  }) async {
    final clauses = <String>['user_id = ?'];
    final args = <Object?>[userId];
    clauses.add(deletedOnly ? 'deleted_at IS NOT NULL' : 'deleted_at IS NULL');
    if (start != null) {
      clauses.add('date >= ?');
      args.add(start.toUtc().toIso8601String());
    }
    if (end != null) {
      clauses.add('date <= ?');
      args.add(end.toUtc().toIso8601String());
    }
    final rows = await _query('transfers', where: clauses.join(' AND '), whereArgs: args, orderBy: 'date DESC');
    return rows.map(TransferEntity.fromMap).toList();
  }

  Future<List<BudgetEntity>> getBudgets({required String userId, bool deletedOnly = false}) async {
    final rows = await _query('budgets', where: deletedOnly ? 'user_id = ? AND deleted_at IS NOT NULL' : 'user_id = ? AND deleted_at IS NULL', whereArgs: [userId], orderBy: 'start_date DESC');
    return rows.map(BudgetEntity.fromMap).toList();
  }

  Future<List<RecurringTransactionEntity>> getRecurringTransactions({required String userId, bool deletedOnly = false}) async {
    final rows = await _query('recurring_transactions', where: deletedOnly ? 'user_id = ? AND deleted_at IS NOT NULL' : 'user_id = ? AND deleted_at IS NULL', whereArgs: [userId], orderBy: 'next_run_at ASC');
    return rows.map(RecurringTransactionEntity.fromMap).toList();
  }

  Future<List<PaymentCardCredentialEntity>> getPaymentCardCredentials({required String userId, bool deletedOnly = false}) async {
    final rows = await _query('payment_card_credentials', where: deletedOnly ? 'user_id = ? AND deleted_at IS NOT NULL' : 'user_id = ? AND deleted_at IS NULL', whereArgs: [userId], orderBy: 'bank_name COLLATE NOCASE ASC');
    return rows.map(PaymentCardCredentialEntity.fromMap).toList();
  }

  Future<List<BankAccountCredentialEntity>> getBankAccountCredentials({required String userId, bool deletedOnly = false}) async {
    final rows = await _query('bank_account_credentials', where: deletedOnly ? 'user_id = ? AND deleted_at IS NOT NULL' : 'user_id = ? AND deleted_at IS NULL', whereArgs: [userId], orderBy: 'bank_name COLLATE NOCASE ASC');
    return rows.map(BankAccountCredentialEntity.fromMap).toList();
  }

  Future<List<SyncOutboxEntity>> getSyncOutboxEntries({
    String? userId,
    String? status,
    bool withErrorsOnly = false,
    int? limit,
    String? orderBy,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (userId != null) {
      clauses.add('user_id = ?');
      args.add(userId);
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status);
    }
    if (withErrorsOnly) {
      clauses.add('last_error IS NOT NULL');
    }
    final rows = await _query(
      'sync_outbox',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy ?? 'created_at ASC',
      limit: limit,
    );
    return rows.map(SyncOutboxEntity.fromMap).toList();
  }

  Future<int> countSyncOutbox({required String userId, String? status}) async {
    final rows = await _query(
      'sync_outbox',
      columns: ['COUNT(*) AS count'],
      where: status == null ? 'user_id = ?' : 'user_id = ? AND status = ?',
      whereArgs: status == null ? [userId] : [userId, status],
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  Future<String?> getLastSyncError({required String userId}) async {
    final rows = await _query(
      'sync_outbox',
      columns: ['last_error'],
      where: 'user_id = ? AND last_error IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'last_attempt_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['last_error'] as String?;
  }

  Future<DateTime?> getLatestUpdatedAtForUser(String table, String userId, {String userColumn = 'user_id'}) async {
    final rows = await _query(
      table,
      columns: ['MAX(updated_at) AS updated_at'],
      where: '$userColumn = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) {
      return null;
    }
    final value = rows.first['updated_at'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  Future<void> deleteByUser(String table, String userId, {String userColumn = 'user_id'}) {
    return _execute('DELETE FROM $table WHERE $userColumn = ?', [userId]);
  }

  Future<void> deleteSummaryCacheForUser(String userId) {
    return _execute('DELETE FROM summary_cache WHERE user_id = ?', [userId]);
  }

  Future<void> deleteSyncOutboxByUser(String userId) {
    return _execute('DELETE FROM sync_outbox WHERE user_id = ?', [userId]);
  }

  Future<void> deleteSyncOutboxEntry(int id, {Transaction? txn}) {
    if (txn == null) {
      return _execute('DELETE FROM sync_outbox WHERE id = ?', [id]);
    }
    return txn.rawDelete('DELETE FROM sync_outbox WHERE id = ?', [id]).then((_) {});
  }

  Future<void> updateSyncOutboxStatus(SyncOutboxEntity entry, {required String status, required DateTime now, String? error, Transaction? txn}) {
    entry.status = status;
    entry.lastAttemptAt = now;
    entry.attempts += 1;
    entry.lastError = error;
    return _insert('sync_outbox', entry.toMap(includeId: true), txn: txn);
  }

  Future<int> _insert(String table, Map<String, Object?> values, {Transaction? txn}) async {
    if (txn == null) {
      return _database.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return txn.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> _query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    return _database.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> _execute(String sql, [List<Object?>? arguments]) {
    return _database.rawDelete(sql, arguments);
  }
}

