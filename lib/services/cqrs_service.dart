import 'package:isar/isar.dart';

import '../cqrs/cqrs_bus.dart';
import '../cqrs/commands.dart';
import '../cqrs/handlers.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import 'local_db.dart';
import 'sync_outbox.dart';

class CqrsService {
  CqrsService._(this.bus, this.isar);

  final CqrsBus bus;
  final Isar isar;

  static Future<CqrsService> create() async {
    final isar = await LocalDb.instance.open();
    final bus = CqrsBus();
    final summaryWriter = SummaryCacheWriter(isar);
    final outboxWriter = SyncOutboxWriter(isar);

    bus.registerCommandHandler<CreateUserCommand>(
      CreateUserHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<CreateAccountCommand>(
      CreateAccountHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<UpdateAccountCommand>(
      UpdateAccountHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<DeleteAccountCommand>(
      DeleteAccountHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<CreateCategoryCommand>(
      CreateCategoryHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<UpdateCategoryCommand>(
      UpdateCategoryHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<DeleteCategoryCommand>(
      DeleteCategoryHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<CreateTransactionCommand>(
      CreateTransactionHandler(isar, summaryWriter, outboxWriter),
    );
    bus.registerCommandHandler<UpdateTransactionCommand>(
      UpdateTransactionHandler(isar, summaryWriter, outboxWriter),
    );
    bus.registerCommandHandler<DeleteTransactionCommand>(
      DeleteTransactionHandler(isar, summaryWriter, outboxWriter),
    );
    bus.registerCommandHandler<CreateTransferCommand>(
      CreateTransferHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<CreateBudgetCommand>(
      CreateBudgetHandler(isar, outboxWriter),
    );
    bus.registerCommandHandler<CreateRecurringTransactionCommand>(
      CreateRecurringTransactionHandler(isar, outboxWriter),
    );

    bus.registerQueryHandler<GetAccountsQuery, List<AccountEntity>>(
      GetAccountsHandler(isar),
    );
    bus.registerQueryHandler<GetCategoriesQuery, List<CategoryEntity>>(
      GetCategoriesHandler(isar),
    );
    bus.registerQueryHandler<GetTransactionsQuery, List<TransactionEntity>>(
      GetTransactionsHandler(isar),
    );
    bus.registerQueryHandler<GetBudgetsQuery, List<BudgetEntity>>(
      GetBudgetsHandler(isar),
    );
    bus.registerQueryHandler<GetRecurringQuery,
        List<RecurringTransactionEntity>>(
      GetRecurringHandler(isar),
    );
    bus.registerQueryHandler<GetTransfersQuery, List<TransferEntity>>(
      GetTransfersHandler(isar),
    );
    bus.registerQueryHandler<GetSummaryQuery, SummaryCacheEntity?>(
      GetSummaryHandler(isar, summaryWriter),
    );

    return CqrsService._(bus, isar);
  }
}
