import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_database.dart';

import '../models/local_models.dart';
import 'account_balance_repair_service.dart';
import 'timestamp_repair_service.dart';
import 'user_identity.dart';

class SyncService {
  SyncService._(this._db, this._client);

  static SyncService? _instance;

  static SyncService? get instance => _instance;

  final AppDatabase _db;
  final SupabaseClient _client;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  List<ConnectivityResult>? _lastStatus;
  bool _isSyncing = false;
  final Set<String> _bootstrappedUsers = {};

  static Future<SyncService> initialize({
    required AppDatabase db,
    required SupabaseClient client,
  }) async {
    _instance ??= SyncService._(db, client);
    await _instance!._start();
    return _instance!;
  }

  Future<void> _start() async {
    _lastStatus = await _connectivity.checkConnectivity();
    if (_isOnline(_lastStatus)) {
      final authId = _client.auth.currentUser?.id;
      final userId =
          authId ?? (await UserIdentityService.instance.getProfile()).userId;
      await TimestampRepairService(db: _db).repairLocal(userId: userId);
      await TimestampRepairService(db: _db, client: _client)
          .repairRemote(userId: userId);
      await _trySync();
      await reconcileIfRemoteNewer(userId: userId);
      final repairedCount =
          await AccountBalanceRepairService(db: _db).repair(userId: userId);
      if (repairedCount > 0) {
        await _trySync();
      }
    }
    _subscription ??= _connectivity.onConnectivityChanged.listen((status) {
      _lastStatus = status;
      if (_isOnline(status)) {
        _trySync();
      }
    });
  }

  Future<SyncStatus> getStatus({required String userId}) async {
    final local = await _getLocalLastUpdated(userId);
    final remote = await _getRemoteLastUpdated(userId);
    final pendingCount = await _getPendingOutboxCount(userId);
    final lastError = await _getLastOutboxError(userId);
    return SyncStatus(
      localLastUpdated: local,
      remoteLastUpdated: remote,
      pendingOutboxCount: pendingCount,
      lastSyncError: lastError,
    );
  }

  Future<List<PendingSync>> getPendingSyncs({
    required String userId,
    int limit = 10,
  }) async {
    final entries = await _db.getSyncOutboxEntries(
      userId: userId, status: 'pending', orderBy: 'created_at ASC', limit: limit,
    );

    return entries
        .map(
          (entry) => PendingSync(
            entityType: entry.entityType,
            entityId: entry.entityId,
            action: entry.action,
            attempts: entry.attempts,
            lastAttemptAt: entry.lastAttemptAt,
            errorMessage: entry.lastError,
          ),
        )
        .toList();
  }

  Future<void> pushLocalChanges({required String userId}) async {
    await TimestampRepairService(db: _db).repairLocal(userId: userId);
    await TimestampRepairService(db: _db, client: _client)
        .repairRemote(userId: userId);
    await AccountBalanceRepairService(db: _db).repair(userId: userId);
    await _trySync();
  }

  Future<void> downloadRemoteSnapshot({required String userId}) async {
    if (await _hasPendingLocalChanges(userId)) {
      throw StateError(
        'Push pending local changes before downloading from Supabase.',
      );
    }
    final remoteLastUpdated = await _getRemoteLastUpdated(userId);
    if (remoteLastUpdated == null) {
      throw StateError('No Supabase data found to download.');
    }
    await _importRemoteSnapshot(userId);
    final repairedCount =
        await AccountBalanceRepairService(db: _db).repair(userId: userId);
    if (repairedCount > 0) {
      await _trySync();
    }
  }

  Future<void> reconcileIfRemoteNewer({required String userId}) async {
    if (await _hasPendingLocalChanges(userId)) {
      return;
    }

    final status = await getStatus(userId: userId);
    if (status.remoteLastUpdated == null) {
      return;
    }
    if (status.localLastUpdated == null ||
        status.remoteLastUpdated!.isAfter(status.localLastUpdated!)) {
      await _importRemoteSnapshot(userId);
    }
  }

  void requestSync() {
    _trySync();
  }

  Future<void> _trySync() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      await syncPending();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncPending() async {
    final pending = await _db.getSyncOutboxEntries(status: 'pending');

    for (final entry in pending) {
      final ready = await _ensureRemoteUser(entry.userId);
      if (!ready) {
        await _markFailed(entry, 'Missing remote user bootstrap');
        continue;
      }

      final table = _tableFor(entry.entityType);
      if (table == null) {
        await _markFailed(entry, 'Unknown entity type: ${entry.entityType}');
        continue;
      }

      try {
        final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
        await _client.from(table).upsert(payload, onConflict: 'id');
        await _markSynced(entry);
      } catch (error) {
        await _markFailed(entry, error.toString());
      }
    }
  }

  Future<bool> _hasPendingLocalChanges(String userId) async {
    final pendingCount = await _getPendingOutboxCount(userId);
    return pendingCount > 0;
  }

  Future<int> _getPendingOutboxCount(String userId) {
    return _db.countSyncOutbox(userId: userId, status: 'pending');
  }

  Future<String?> _getLastOutboxError(String userId) async {
    return _db.getLastSyncError(userId: userId);
  }

  Future<void> _markSynced(SyncOutboxEntity entry) async {
    await _db.updateSyncOutboxStatus(entry, status: 'synced', now: DateTime.now());
  }

  Future<void> _markFailed(SyncOutboxEntity entry, String message) async {
    await _db.updateSyncOutboxStatus(entry, status: 'pending', now: DateTime.now(), error: message);
  }

  bool _isOnline(List<ConnectivityResult>? status) {
    return status != null &&
        status.any((entry) => entry != ConnectivityResult.none);
  }

  String? _tableFor(String entityType) {
    switch (entityType) {
      case 'users':
        return 'users';
      case 'accounts':
        return 'accounts';
      case 'categories':
        return 'categories';
      case 'transactions':
        return 'transactions';
      case 'transfers':
        return 'transfers';
      case 'budgets':
        return 'budgets';
      case 'recurring':
        return 'recurring_transactions';
      case 'payment_card_credentials':
        return 'payment_card_credentials';
      case 'bank_account_credentials':
        return 'bank_account_credentials';
      default:
        return null;
    }
  }

  Future<bool> _ensureRemoteUser(String userId) async {
    final now = DateTime.now();
    if (_bootstrappedUsers.contains(userId)) {
      return true;
    }

    final existing =
        await _client.from('users').select('id').eq('id', userId).limit(1);

    if (existing.isNotEmpty) {
      _bootstrappedUsers.add(userId);
      return true;
    }

    final local = await _db.getUserByUserId(userId);

    final authUser = _client.auth.currentUser;
    if (local == null && (authUser == null || authUser.id != userId)) {
      final profile = await UserIdentityService.instance.getProfile();
      if (profile.userId != userId) {
        return false;
      }

      await _client.from('users').upsert({
        'id': userId,
        'email': profile.email,
        'display_name': profile.displayName,
        'photo_url': null,
        'created_at': _isoUtc(now),
        'updated_at': _isoUtc(now),
        'deleted_at': null,
      }, onConflict: 'id');

      _bootstrappedUsers.add(userId);
      return true;
    }

    final email = local?.email ?? authUser?.email;
    final displayName = local?.displayName ?? _displayNameFromEmail(email);

    if (email == null || displayName == null) {
      return false;
    }

    await _client.from('users').upsert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'photo_url': local?.photoUrl,
      'created_at': _isoUtc(local?.createdAt ?? now),
      'updated_at': _isoUtc(local?.updatedAt ?? now),
      'deleted_at': _isoUtc(local?.deletedAt),
    }, onConflict: 'id');

    _bootstrappedUsers.add(userId);
    return true;
  }

  Future<DateTime?> _getLocalLastUpdated(String userId) async {
    final values = await Future.wait([
      _db.getLatestUpdatedAtForUser('users', userId),
      _db.getLatestUpdatedAtForUser('accounts', userId),
      _db.getLatestUpdatedAtForUser('categories', userId),
      _db.getLatestUpdatedAtForUser('transactions', userId),
      _db.getLatestUpdatedAtForUser('transfers', userId),
      _db.getLatestUpdatedAtForUser('budgets', userId),
      _db.getLatestUpdatedAtForUser('recurring_transactions', userId),
      _db.getLatestUpdatedAtForUser('payment_card_credentials', userId),
      _db.getLatestUpdatedAtForUser('bank_account_credentials', userId),
    ]);
    return _maxDate(values);
  }

  Future<DateTime?> _getRemoteLastUpdated(String userId) async {
    final values = await Future.wait([
      _fetchRemoteLatest('users', userId, idColumn: 'id'),
      _fetchRemoteLatest('accounts', userId),
      _fetchRemoteLatest('categories', userId),
      _fetchRemoteLatest('transactions', userId),
      _fetchRemoteLatest('transfers', userId),
      _fetchRemoteLatest('budgets', userId),
      _fetchRemoteLatest('recurring_transactions', userId),
      _fetchRemoteLatest('payment_card_credentials', userId),
      _fetchRemoteLatest('bank_account_credentials', userId),
    ]);
    return _maxDate(values);
  }

  Future<DateTime?> _fetchRemoteLatest(
    String table,
    String userId, {
    String idColumn = 'user_id',
  }) async {
    final response = await _client
        .from(table)
        .select('updated_at')
        .eq(idColumn, userId)
        .order('updated_at', ascending: false)
        .limit(1);

    if (response.isNotEmpty) {
      final row = response.first;
      return _parseDate(row['updated_at']);
    }
    return null;
  }

  Future<void> _importRemoteSnapshot(String userId) async {
    final snapshot = await _fetchRemoteSnapshot(userId);
    await _db.transaction((txn) async {
      for (final table in ['summary_cache', 'users', 'accounts', 'categories', 'transactions', 'transfers', 'budgets', 'recurring_transactions', 'payment_card_credentials', 'bank_account_credentials']) {
        await txn.rawDelete('DELETE FROM $table WHERE user_id = ?', [userId]);
      }
      if (snapshot.user != null) await _db.putUser(snapshot.user!, txn: txn);
      await _db.putAccounts(snapshot.accounts, txn: txn);
      await _db.putCategories(snapshot.categories, txn: txn);
      await _db.putTransactions(snapshot.transactions, txn: txn);
      await _db.putTransfers(snapshot.transfers, txn: txn);
      await _db.putBudgets(snapshot.budgets, txn: txn);
      await _db.putRecurringTransactions(snapshot.recurring, txn: txn);
      await _db.putPaymentCardCredentials(snapshot.paymentCards, txn: txn);
      await _db.putBankAccountCredentials(snapshot.bankCredentials, txn: txn);
    });
  }

  Future<_RemoteSnapshot> _fetchRemoteSnapshot(String userId) async {
    final userRows =
        await _client.from('users').select().eq('id', userId).limit(1);
    final accountRows =
        await _client.from('accounts').select().eq('user_id', userId);
    final categoryRows =
        await _client.from('categories').select().eq('user_id', userId);
    final transactionRows =
        await _client.from('transactions').select().eq('user_id', userId);
    final transferRows =
        await _client.from('transfers').select().eq('user_id', userId);
    final budgetRows =
        await _client.from('budgets').select().eq('user_id', userId);
    final recurringRows = await _client
        .from('recurring_transactions')
        .select()
        .eq('user_id', userId);
    final paymentCardRows = await _client
        .from('payment_card_credentials')
        .select()
        .eq('user_id', userId);
    final bankCredentialRows = await _client
        .from('bank_account_credentials')
        .select()
        .eq('user_id', userId);

    final user = userRows.isNotEmpty ? _userFromRemote(userRows.first) : null;

    return _RemoteSnapshot(
      user: user,
      accounts: _mapAll(accountRows, _accountFromRemote),
      categories: _mapAll(categoryRows, _categoryFromRemote),
      transactions: _mapAll(transactionRows, _transactionFromRemote),
      transfers: _mapAll(transferRows, _transferFromRemote),
      budgets: _mapAll(budgetRows, _budgetFromRemote),
      recurring: _mapAll(recurringRows, _recurringFromRemote),
      paymentCards: _mapAll(paymentCardRows, _paymentCardFromRemote),
      bankCredentials: _mapAll(bankCredentialRows, _bankCredentialFromRemote),
    );
  }

  List<T> _mapAll<T>(dynamic rows, T Function(Map<String, dynamic>) mapper) {
    if (rows is! List) {
      return <T>[];
    }
    return rows
        .cast<Map<String, dynamic>>()
        .map<T>((row) => mapper(row))
        .toList();
  }

  UserEntity _userFromRemote(Map<String, dynamic> row) {
    return UserEntity()
      ..userId = row['id'] as String
      ..email = row['email'] as String
      ..displayName = row['display_name'] as String
      ..photoUrl = row['photo_url'] as String?
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  AccountEntity _accountFromRemote(Map<String, dynamic> row) {
    return AccountEntity()
      ..userId = row['user_id'] as String
      ..accountId = row['id'] as String
      ..name = row['name'] as String
      ..type = row['type'] as String
      ..currency = row['currency'] as String
      ..openingBalance = _toDouble(row['opening_balance'])
      ..currentBalance = _toDouble(row['current_balance'])
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  CategoryEntity _categoryFromRemote(Map<String, dynamic> row) {
    return CategoryEntity()
      ..userId = row['user_id'] as String
      ..categoryId = row['id'] as String
      ..name = row['name'] as String
      ..type = row['type'] as String
      ..icon = row['icon'] as String?
      ..color = row['color'] as int?
      ..sortOrder = (row['sort_order'] as num?)?.toInt() ?? 0
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  TransactionEntity _transactionFromRemote(Map<String, dynamic> row) {
    return TransactionEntity()
      ..userId = row['user_id'] as String
      ..accountId = row['account_id'] as String
      ..categoryId = row['category_id'] as String
      ..transactionId = row['id'] as String
      ..type = row['type'] as String
      ..amount = _toDouble(row['amount'])
      ..currency = row['currency'] as String
      ..date = _requireDate(row['date'])
      ..note = row['note'] as String?
      ..isRecurring = row['is_recurring'] as bool? ?? false
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  TransferEntity _transferFromRemote(Map<String, dynamic> row) {
    return TransferEntity()
      ..userId = row['user_id'] as String
      ..fromAccountId = row['from_account_id'] as String
      ..toAccountId = row['to_account_id'] as String
      ..transferId = row['id'] as String
      ..amount = _toDouble(row['amount'])
      ..date = _requireDate(row['date'])
      ..note = row['note'] as String?
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  BudgetEntity _budgetFromRemote(Map<String, dynamic> row) {
    return BudgetEntity()
      ..userId = row['user_id'] as String
      ..categoryId = row['category_id'] as String?
      ..budgetId = row['id'] as String
      ..period = row['period'] as String
      ..amount = _toDouble(row['amount'])
      ..startDate = _requireDate(row['start_date'])
      ..endDate = _parseDate(row['end_date'])
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  RecurringTransactionEntity _recurringFromRemote(Map<String, dynamic> row) {
    return RecurringTransactionEntity()
      ..userId = row['user_id'] as String
      ..accountId = row['account_id'] as String
      ..categoryId = row['category_id'] as String
      ..recurringId = row['id'] as String
      ..type = row['type'] as String
      ..amount = _toDouble(row['amount'])
      ..interval = row['interval'] as String
      ..nextRunAt = _requireDate(row['next_run_at'])
      ..isActive = row['is_active'] as bool? ?? true
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  PaymentCardCredentialEntity _paymentCardFromRemote(
    Map<String, dynamic> row,
  ) {
    return PaymentCardCredentialEntity()
      ..userId = row['user_id'] as String
      ..cardCredentialId = row['id'] as String
      ..bankName = row['bank_name'] as String
      ..bankLogoBase64 = row['bank_logo_base64'] as String?
      ..cardType = row['card_type'] as String
      ..network = row['network'] as String
      ..cardholderName = row['cardholder_name'] as String
      ..cardNumber = row['card_number'] as String
      ..expiry = row['expiry'] as String
      ..hasNfc = row['has_nfc'] as bool? ?? false
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  BankAccountCredentialEntity _bankCredentialFromRemote(
    Map<String, dynamic> row,
  ) {
    return BankAccountCredentialEntity()
      ..userId = row['user_id'] as String
      ..bankCredentialId = row['id'] as String
      ..bankName = row['bank_name'] as String
      ..bankLogoBase64 = row['bank_logo_base64'] as String?
      ..branchName = row['branch_name'] as String
      ..accountName = row['account_name'] as String
      ..accountNumber = row['account_number'] as String
      ..routingNumber = row['routing_number'] as String
      ..swiftCode = row['swift_code'] as String
      ..createdAt = _requireDate(row['created_at'])
      ..updatedAt = _requireDate(row['updated_at'])
      ..deletedAt = _parseDate(row['deleted_at']);
  }

  DateTime _requireDate(dynamic value) {
    final parsed = _parseDate(value);
    if (parsed == null) {
      throw StateError('Missing timestamp for sync import');
    }
    return parsed;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return null;
  }

  String? _isoUtc(DateTime? value) => value?.toUtc().toIso8601String();

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }

  String? _displayNameFromEmail(String? email) {
    if (email == null || !email.contains('@')) {
      return null;
    }
    return email.split('@').first;
  }

  DateTime? _maxDate(Iterable<DateTime?> values) {
    DateTime? latest;
    for (final entry in values) {
      if (entry == null) {
        continue;
      }
      if (latest == null || entry.isAfter(latest)) {
        latest = entry;
      }
    }
    return latest;
  }
}

class SyncStatus {
  const SyncStatus({
    this.localLastUpdated,
    this.remoteLastUpdated,
    this.pendingOutboxCount = 0,
    this.lastSyncError,
  });

  final DateTime? localLastUpdated;
  final DateTime? remoteLastUpdated;
  final int pendingOutboxCount;
  final String? lastSyncError;

  bool get isRemoteNewer =>
      remoteLastUpdated != null &&
      (localLastUpdated == null ||
          remoteLastUpdated!.isAfter(localLastUpdated!));

  bool get isLocalNewer =>
      localLastUpdated != null &&
      (remoteLastUpdated == null ||
          localLastUpdated!.isAfter(remoteLastUpdated!));
}

class PendingSync {
  const PendingSync({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.attempts,
    required this.lastAttemptAt,
    this.errorMessage,
  });

  final String entityType;
  final String entityId;
  final String action;
  final int attempts;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
}

class _RemoteSnapshot {
  const _RemoteSnapshot({
    required this.user,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.transfers,
    required this.budgets,
    required this.recurring,
    required this.paymentCards,
    required this.bankCredentials,
  });

  final UserEntity? user;
  final List<AccountEntity> accounts;
  final List<CategoryEntity> categories;
  final List<TransactionEntity> transactions;
  final List<TransferEntity> transfers;
  final List<BudgetEntity> budgets;
  final List<RecurringTransactionEntity> recurring;
  final List<PaymentCardCredentialEntity> paymentCards;
  final List<BankAccountCredentialEntity> bankCredentials;
}
