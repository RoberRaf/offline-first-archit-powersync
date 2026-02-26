import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import 'connector.dart';
import 'schema.dart';

late PowerSyncDatabase db;
late LaravelConnector connector;

Future<void> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = join(dir.path, 'powersync.db');

  db = PowerSyncDatabase(schema: schema, path: path);
  await db.initialize();
  db.logger.onRecord.listen((record) {
    // log('[${record.level.name}] ${record.time}: ${record.message}');
  });
  connector = LaravelConnector();
  await db.connect(connector: connector);
}
