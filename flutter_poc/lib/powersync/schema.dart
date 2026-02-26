import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('notes', [Column.text('title'), Column.text('content'), Column.text('created_at'), Column.text('updated_at')]),
  Table('videos', [
    Column.text('name'),
    Column.integer('offset'),
    Column.integer('is_completed'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  Table('quizzes', [Column.text('name'), Column.text('grade'), Column.text('created_at'), Column.text('updated_at')]),
]);
