import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_models.dart';

class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();
  Isar? _isar;

  Future<Isar> open() async {
    if (_isar != null) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserEntitySchema,
        AccountEntitySchema,
        CategoryEntitySchema,
        TransactionEntitySchema,
        TransferEntitySchema,
        BudgetEntitySchema,
        RecurringTransactionEntitySchema,
        SummaryCacheEntitySchema,
        SyncOutboxEntitySchema,
      ],
      directory: dir.path,
    );

    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
