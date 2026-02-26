abstract class DbModel {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DbModel({
    required this.id,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert model to map for SQLite insert/update
  Map<String, dynamic> toMap();

  /// Table name this model belongs to
  String get tableName;

  /// Columns to return in SELECT (override to restrict)
  String get selectColumns => '*';
}