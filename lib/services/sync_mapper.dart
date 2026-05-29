import '../models/isar_models.dart';

class SyncPayloadMapper {
  static Map<String, dynamic> user(UserEntity user) {
    return {
      'id': user.userId,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoUrl,
      'created_at': _iso(user.createdAt),
      'updated_at': _iso(user.updatedAt),
      'deleted_at': _iso(user.deletedAt),
    };
  }

  static Map<String, dynamic> account(AccountEntity account) {
    return {
      'id': account.accountId,
      'user_id': account.userId,
      'name': account.name,
      'type': account.type,
      'currency': account.currency,
      'opening_balance': account.openingBalance,
      'current_balance': account.currentBalance,
      'created_at': _iso(account.createdAt),
      'updated_at': _iso(account.updatedAt),
      'deleted_at': _iso(account.deletedAt),
    };
  }

  static Map<String, dynamic> category(CategoryEntity category) {
    return {
      'id': category.categoryId,
      'user_id': category.userId,
      'name': category.name,
      'type': category.type,
      'icon': category.icon,
      'color': category.color,
      'sort_order': category.sortOrder,
      'created_at': _iso(category.createdAt),
      'updated_at': _iso(category.updatedAt),
      'deleted_at': _iso(category.deletedAt),
    };
  }

  static Map<String, dynamic> transaction(TransactionEntity tx) {
    return {
      'id': tx.transactionId,
      'user_id': tx.userId,
      'account_id': tx.accountId,
      'category_id': tx.categoryId,
      'type': tx.type,
      'amount': tx.amount,
      'currency': tx.currency,
      'date': _iso(tx.date),
      'note': tx.note,
      'is_recurring': tx.isRecurring,
      'created_at': _iso(tx.createdAt),
      'updated_at': _iso(tx.updatedAt),
      'deleted_at': _iso(tx.deletedAt),
    };
  }

  static Map<String, dynamic> transfer(TransferEntity transfer) {
    return {
      'id': transfer.transferId,
      'user_id': transfer.userId,
      'from_account_id': transfer.fromAccountId,
      'to_account_id': transfer.toAccountId,
      'amount': transfer.amount,
      'date': _iso(transfer.date),
      'note': transfer.note,
      'created_at': _iso(transfer.createdAt),
      'updated_at': _iso(transfer.updatedAt),
      'deleted_at': _iso(transfer.deletedAt),
    };
  }

  static Map<String, dynamic> budget(BudgetEntity budget) {
    return {
      'id': budget.budgetId,
      'user_id': budget.userId,
      'category_id': budget.categoryId,
      'period': budget.period,
      'amount': budget.amount,
      'start_date': _iso(budget.startDate),
      'end_date': _iso(budget.endDate),
      'created_at': _iso(budget.createdAt),
      'updated_at': _iso(budget.updatedAt),
      'deleted_at': _iso(budget.deletedAt),
    };
  }

  static Map<String, dynamic> recurring(RecurringTransactionEntity recurring) {
    return {
      'id': recurring.recurringId,
      'user_id': recurring.userId,
      'account_id': recurring.accountId,
      'category_id': recurring.categoryId,
      'type': recurring.type,
      'amount': recurring.amount,
      'interval': recurring.interval,
      'next_run_at': _iso(recurring.nextRunAt),
      'is_active': recurring.isActive,
      'created_at': _iso(recurring.createdAt),
      'updated_at': _iso(recurring.updatedAt),
      'deleted_at': _iso(recurring.deletedAt),
    };
  }

  static Map<String, dynamic> paymentCardCredential(
    PaymentCardCredentialEntity credential,
  ) {
    return {
      'id': credential.cardCredentialId,
      'user_id': credential.userId,
      'bank_name': credential.bankName,
      'bank_logo_base64': credential.bankLogoBase64,
      'card_type': credential.cardType,
      'network': credential.network,
      'cardholder_name': credential.cardholderName,
      'card_number': credential.cardNumber,
      'expiry': credential.expiry,
      'has_nfc': credential.hasNfc,
      'created_at': _iso(credential.createdAt),
      'updated_at': _iso(credential.updatedAt),
      'deleted_at': _iso(credential.deletedAt),
    };
  }

  static Map<String, dynamic> bankAccountCredential(
    BankAccountCredentialEntity credential,
  ) {
    return {
      'id': credential.bankCredentialId,
      'user_id': credential.userId,
      'bank_name': credential.bankName,
      'bank_logo_base64': credential.bankLogoBase64,
      'branch_name': credential.branchName,
      'account_name': credential.accountName,
      'account_number': credential.accountNumber,
      'routing_number': credential.routingNumber,
      'swift_code': credential.swiftCode,
      'created_at': _iso(credential.createdAt),
      'updated_at': _iso(credential.updatedAt),
      'deleted_at': _iso(credential.deletedAt),
    };
  }

  static String? _iso(DateTime? value) => value?.toUtc().toIso8601String();
}
