import 'package:flutter_poc/models/db_mode.dart';

class Video extends DbModel {
  final String name;
  final int offset;
  final bool isCompleted;

  const Video({
    required super.id,
    required this.name,
    this.offset = 0,
    this.isCompleted = false,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get tableName => 'videos';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'offset': offset, 'is_completed': isCompleted ? 1 : 0};

  factory Video.fromMap(Map<String, dynamic> map) => Video(
    id: map['id'].toString(),
    name: map['name'].toString(),
    offset: int.tryParse(map['offset'].toString()) ?? 0,
    isCompleted: (map['is_completed'] == 1 || map['is_completed'] == true),
    createdAt: DateTime.tryParse(map['created_at'].toString()),
    updatedAt: DateTime.tryParse(map['updated_at'].toString()),
  );
}
