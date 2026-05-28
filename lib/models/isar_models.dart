import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class UserEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId;

  @Index(unique: true)
  late String email;

  late String displayName;
  String? photoUrl;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class AccountEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String accountId;
  late String name;
  late String type; // cash, bank, card, other
  late String currency;
  String? logoBase64;
  double openingBalance = 0;
  double currentBalance = 0;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class CategoryEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String categoryId;
  late String name;
  late String type; // income or expense
  String? icon;
  int? color; // ARGB
  int sortOrder = 0;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class TransactionEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String accountId;

  @Index()
  late String categoryId;

  @Index()
  late String transactionId;
  late String type; // income, expense, transfer
  late double amount;
  late String currency;

  @Index()
  late DateTime date;

  String? note;
  bool isRecurring = false;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class TransferEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String fromAccountId;

  @Index()
  late String toAccountId;

  @Index()
  late String transferId;
  late double amount;

  @Index()
  late DateTime date;

  String? note;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class BudgetEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  String? categoryId; // null = overall

  @Index()
  late String budgetId;
  late String period; // weekly, monthly, yearly
  late double amount;
  late DateTime startDate;
  DateTime? endDate;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class RecurringTransactionEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String accountId;

  @Index()
  late String categoryId;

  @Index()
  late String recurringId;
  late String type; // income or expense
  late double amount;
  late String interval; // daily, weekly, monthly, yearly

  @Index()
  late DateTime nextRunAt;

  bool isActive = true;
  late DateTime createdAt;
  late DateTime updatedAt;
  @Index()
  DateTime? deletedAt;
}

@collection
class SummaryCacheEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String summaryKey;

  @Index()
  late String userId;

  @Index()
  late String period; // weekly, monthly, yearly, lifetime

  @Index()
  late DateTime startDate;

  DateTime? endDate;
  late double totalIncome;
  late double totalExpense;
  late double net;
  String? byCategoryJson;
}

@collection
class SyncOutboxEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String entityType;

  @Index()
  late String entityId;

  @Index()
  late String status; // pending, synced

  late String action; // upsert
  late String payloadJson;
  late DateTime createdAt;
  DateTime? lastAttemptAt;
  int attempts = 0;
  String? lastError;
}
