import 'package:flutter_poc/models/db_mode.dart';

class Note extends DbModel {
  final String title;
  final String content;

  const Note({required super.id, required this.title, required this.content, super.createdAt, super.updatedAt});

  @override
  String get tableName => 'notes';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'content': content};

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'].toString(),
    title: map['title'].toString(),
    content: map['content'].toString(),
    createdAt: DateTime.tryParse(map['created_at'].toString()),
    updatedAt: DateTime.tryParse(map['updated_at'].toString()),
  );
}
