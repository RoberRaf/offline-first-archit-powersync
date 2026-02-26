import 'package:flutter_poc/powersync/database.dart';
import 'package:flutter_poc/services/database_service.dart';
import 'package:get_it/get_it.dart';

final di = GetIt.instance;

Future<void> init() async {
  di.registerSingleton(DatabaseService(db: db));
}
