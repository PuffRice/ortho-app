import 'package:uuid/uuid.dart';

String generateId() {
  const uuid = Uuid();
  return uuid.v4();
}
