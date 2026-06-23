import '../cqrs/cqrs_bus.dart';
import '../cqrs/commands.dart';
import '../cqrs/handlers_sqlite.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import 'app_database.dart';
import 'local_db.dart';
import 'sync_outbox.dart';

class CqrsService {
  CqrsService._(this.bus, this.db);

  final CqrsBus bus;
  final AppDatabase db;

  static Future<CqrsService> create() async {
    final db = await LocalDb.instance.open();
    final bus = CqrsBus();
    final summaryWriter = SummaryCacheWriter(db);
    final outboxWriter = SyncOutboxWriter(db);

    bus.registerCommandHandler<CreateUserCommand>(
      CreateUserHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<CreateAccountCommand>(
      CreateAccountHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<UpdateAccountCommand>(
      UpdateAccountHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<DeleteAccountCommand>(
      DeleteAccountHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<CreateCategoryCommand>(
      CreateCategoryHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<UpdateCategoryCommand>(
      UpdateCategoryHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<DeleteCategoryCommand>(
      DeleteCategoryHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<CreateTransactionCommand>(
      CreateTransactionHandler(db, summaryWriter, outboxWriter),
    );
    bus.registerCommandHandler<UpdateTransactionCommand>(
      UpdateTransactionHandler(db, summaryWriter, outboxWriter),
    );
    bus.registerCommandHandler<DeleteTransactionCommand>(
      DeleteTransactionHandler(db, summaryWriter, outboxWriter),
    );
    bus.registerCommandHandler<CreateTransferCommand>(
      CreateTransferHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<CreateBudgetCommand>(
      CreateBudgetHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<CreateRecurringTransactionCommand>(
      CreateRecurringTransactionHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<UpsertPaymentCardCredentialCommand>(
      UpsertPaymentCardCredentialHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<DeletePaymentCardCredentialCommand>(
      DeletePaymentCardCredentialHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<UpsertBankAccountCredentialCommand>(
      UpsertBankAccountCredentialHandler(db, outboxWriter),
    );
    bus.registerCommandHandler<DeleteBankAccountCredentialCommand>(
      DeleteBankAccountCredentialHandler(db, outboxWriter),
    );

    bus.registerQueryHandler<GetAccountsQuery, List<AccountEntity>>(
      GetAccountsHandler(db),
    );
    bus.registerQueryHandler<GetCategoriesQuery, List<CategoryEntity>>(
      GetCategoriesHandler(db),
    );
    bus.registerQueryHandler<GetTransactionsQuery, List<TransactionEntity>>(
      GetTransactionsHandler(db),
    );
    bus.registerQueryHandler<GetBudgetsQuery, List<BudgetEntity>>(
      GetBudgetsHandler(db),
    );
    bus.registerQueryHandler<GetRecurringQuery,
        List<RecurringTransactionEntity>>(
      GetRecurringHandler(db),
    );
    bus.registerQueryHandler<GetTransfersQuery, List<TransferEntity>>(
      GetTransfersHandler(db),
    );
    bus.registerQueryHandler<GetSummaryQuery, SummaryCacheEntity?>(
      GetSummaryHandler(db, summaryWriter),
    );
    bus.registerQueryHandler<GetPaymentCardCredentialsQuery,
        List<PaymentCardCredentialEntity>>(
      GetPaymentCardCredentialsHandler(db),
    );
    bus.registerQueryHandler<GetBankAccountCredentialsQuery,
        List<BankAccountCredentialEntity>>(
      GetBankAccountCredentialsHandler(db),
    );

    return CqrsService._(bus, db);
  }
}
