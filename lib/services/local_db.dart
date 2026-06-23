import 'app_database.dart';

class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();
  AppDatabase? _db;

  Future<AppDatabase> open() async {
    if (_db != null) {
      return _db!;
    }

    _db = await AppDatabase.open();
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
