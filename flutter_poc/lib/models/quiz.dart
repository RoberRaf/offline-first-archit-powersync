import 'package:flutter_poc/models/db_mode.dart';

class Quiz extends DbModel {
  final String name;
  final double grade;

  const Quiz({required super.id, required this.name, this.grade = 0, super.createdAt, super.updatedAt});

  @override
  String get tableName => 'quizzes';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'grade': grade};

  factory Quiz.fromMap(Map<String, dynamic> map) => Quiz(
    id: map['id'].toString(),
    name: map['name'].toString(),
    grade: double.tryParse(map['grade'].toString()) ?? 0.0,
    createdAt: DateTime.tryParse(map['created_at'].toString()),
    updatedAt: DateTime.tryParse(map['updated_at'].toString()),
  );
}
