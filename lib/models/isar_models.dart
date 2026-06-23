class UserEntity {
  UserEntity();

  UserEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        email = map['email'] as String,
        displayName = map['display_name'] as String,
        photoUrl = map['photo_url'] as String?,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String email = '';
  String displayName = '';
  String? photoUrl;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class AccountEntity {
  AccountEntity();

  AccountEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        accountId = map['account_id'] as String,
        name = map['name'] as String,
        type = map['type'] as String,
        currency = map['currency'] as String,
        logoBase64 = map['logo_base64'] as String?,
        openingBalance = _toDouble(map['opening_balance']),
        currentBalance = _toDouble(map['current_balance']),
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String accountId = '';
  String name = '';
  String type = '';
  String currency = '';
  String? logoBase64;
  double openingBalance = 0;
  double currentBalance = 0;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'account_id': accountId,
      'name': name,
      'type': type,
      'currency': currency,
      'logo_base64': logoBase64,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class CategoryEntity {
  CategoryEntity();

  CategoryEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        categoryId = map['category_id'] as String,
        name = map['name'] as String,
        type = map['type'] as String,
        icon = map['icon'] as String?,
        color = map['color'] as int?,
        sortOrder = (map['sort_order'] as num?)?.toInt() ?? 0,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String categoryId = '';
  String name = '';
  String type = '';
  String? icon;
  int? color;
  int sortOrder = 0;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class TransactionEntity {
  TransactionEntity();

  TransactionEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        accountId = map['account_id'] as String,
        categoryId = map['category_id'] as String,
        transactionId = map['transaction_id'] as String,
        type = map['type'] as String,
        amount = _toDouble(map['amount']),
        currency = map['currency'] as String,
        date = DateTime.parse(map['date'] as String),
        note = map['note'] as String?,
        isRecurring = (map['is_recurring'] as int? ?? 0) == 1,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String accountId = '';
  String categoryId = '';
  String transactionId = '';
  String type = '';
  double amount = 0;
  String currency = '';
  DateTime date = DateTime.now();
  String? note;
  bool isRecurring = false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'transaction_id': transactionId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'date': date.toUtc().toIso8601String(),
      'note': note,
      'is_recurring': isRecurring ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class TransferEntity {
  TransferEntity();

  TransferEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        fromAccountId = map['from_account_id'] as String,
        toAccountId = map['to_account_id'] as String,
        transferId = map['transfer_id'] as String,
        amount = _toDouble(map['amount']),
        date = DateTime.parse(map['date'] as String),
        note = map['note'] as String?,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String fromAccountId = '';
  String toAccountId = '';
  String transferId = '';
  double amount = 0;
  DateTime date = DateTime.now();
  String? note;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'transfer_id': transferId,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'note': note,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class BudgetEntity {
  BudgetEntity();

  BudgetEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        categoryId = map['category_id'] as String?,
        budgetId = map['budget_id'] as String,
        period = map['period'] as String,
        amount = _toDouble(map['amount']),
        startDate = DateTime.parse(map['start_date'] as String),
        endDate = _parseNullableDate(map['end_date']),
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String? categoryId;
  String budgetId = '';
  String period = '';
  double amount = 0;
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'budget_id': budgetId,
      'period': period,
      'amount': amount,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class RecurringTransactionEntity {
  RecurringTransactionEntity();

  RecurringTransactionEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        accountId = map['account_id'] as String,
        categoryId = map['category_id'] as String,
        recurringId = map['recurring_id'] as String,
        type = map['type'] as String,
        amount = _toDouble(map['amount']),
        interval = map['interval'] as String,
        nextRunAt = DateTime.parse(map['next_run_at'] as String),
        isActive = (map['is_active'] as int? ?? 1) == 1,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String accountId = '';
  String categoryId = '';
  String recurringId = '';
  String type = '';
  double amount = 0;
  String interval = '';
  DateTime nextRunAt = DateTime.now();
  bool isActive = true;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'recurring_id': recurringId,
      'type': type,
      'amount': amount,
      'interval': interval,
      'next_run_at': nextRunAt.toUtc().toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class PaymentCardCredentialEntity {
  PaymentCardCredentialEntity();

  PaymentCardCredentialEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        cardCredentialId = map['card_credential_id'] as String,
        bankName = map['bank_name'] as String,
        bankLogoBase64 = map['bank_logo_base64'] as String?,
        cardType = map['card_type'] as String,
        network = map['network'] as String,
        cardholderName = map['cardholder_name'] as String,
        cardNumber = map['card_number'] as String,
        expiry = map['expiry'] as String,
        hasNfc = (map['has_nfc'] as int? ?? 0) == 1,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String cardCredentialId = '';
  String bankName = '';
  String? bankLogoBase64;
  String cardType = '';
  String network = '';
  String cardholderName = '';
  String cardNumber = '';
  String expiry = '';
  bool hasNfc = false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'card_credential_id': cardCredentialId,
      'bank_name': bankName,
      'bank_logo_base64': bankLogoBase64,
      'card_type': cardType,
      'network': network,
      'cardholder_name': cardholderName,
      'card_number': cardNumber,
      'expiry': expiry,
      'has_nfc': hasNfc ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class BankAccountCredentialEntity {
  BankAccountCredentialEntity();

  BankAccountCredentialEntity.fromMap(Map<String, Object?> map)
      : userId = map['user_id'] as String,
        bankCredentialId = map['bank_credential_id'] as String,
        bankName = map['bank_name'] as String,
        bankLogoBase64 = map['bank_logo_base64'] as String?,
        branchName = map['branch_name'] as String,
        accountName = map['account_name'] as String,
        accountNumber = map['account_number'] as String,
        routingNumber = map['routing_number'] as String,
        swiftCode = map['swift_code'] as String,
        createdAt = DateTime.parse(map['created_at'] as String),
        updatedAt = DateTime.parse(map['updated_at'] as String),
        deletedAt = _parseNullableDate(map['deleted_at']);

  String userId = '';
  String bankCredentialId = '';
  String bankName = '';
  String? bankLogoBase64;
  String branchName = '';
  String accountName = '';
  String accountNumber = '';
  String routingNumber = '';
  String swiftCode = '';
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'bank_credential_id': bankCredentialId,
      'bank_name': bankName,
      'bank_logo_base64': bankLogoBase64,
      'branch_name': branchName,
      'account_name': accountName,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'swift_code': swiftCode,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }
}

class SummaryCacheEntity {
  SummaryCacheEntity();

  SummaryCacheEntity.fromMap(Map<String, Object?> map)
      : summaryKey = map['summary_key'] as String,
        userId = map['user_id'] as String,
        period = map['period'] as String,
        startDate = DateTime.parse(map['start_date'] as String),
        endDate = _parseNullableDate(map['end_date']),
        totalIncome = _toDouble(map['total_income']),
        totalExpense = _toDouble(map['total_expense']),
        net = _toDouble(map['net']),
        byCategoryJson = map['by_category_json'] as String?;

  String summaryKey = '';
  String userId = '';
  String period = '';
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  double totalIncome = 0;
  double totalExpense = 0;
  double net = 0;
  String? byCategoryJson;

  Map<String, Object?> toMap() {
    return {
      'summary_key': summaryKey,
      'user_id': userId,
      'period': period,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net': net,
      'by_category_json': byCategoryJson,
    };
  }
}

class SyncOutboxEntity {
  SyncOutboxEntity();

  SyncOutboxEntity.fromMap(Map<String, Object?> map)
      : id = (map['id'] as num?)?.toInt(),
        userId = map['user_id'] as String,
        entityType = map['entity_type'] as String,
        entityId = map['entity_id'] as String,
        status = map['status'] as String,
        action = map['action'] as String,
        payloadJson = map['payload_json'] as String,
        createdAt = DateTime.parse(map['created_at'] as String),
        lastAttemptAt = _parseNullableDate(map['last_attempt_at']),
        attempts = (map['attempts'] as num?)?.toInt() ?? 0,
        lastError = map['last_error'] as String?;

  int? id;
  String userId = '';
  String entityType = '';
  String entityId = '';
  String status = '';
  String action = '';
  String payloadJson = '';
  DateTime createdAt = DateTime.now();
  DateTime? lastAttemptAt;
  int attempts = 0;
  String? lastError;

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'status': status,
      'action': action,
      'payload_json': payloadJson,
      'created_at': createdAt.toUtc().toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toUtc().toIso8601String(),
      'attempts': attempts,
      'last_error': lastError,
    };
  }
}

DateTime? _parseNullableDate(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    return 0;
  }
  return double.parse(value.toString());
}
