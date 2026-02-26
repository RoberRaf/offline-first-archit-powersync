import 'package:flutter/material.dart';
import 'package:flutter_poc/models/quiz.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class QuizzesDataSource extends DataGridSource {
  final List<Quiz> _quizzesList;
  final void Function(Quiz) onEdit;

  QuizzesDataSource({required List<Quiz> quizzes, required this.onEdit}) : _quizzesList = quizzes {
    _rows = quizzes
        .asMap()
        .entries
        .map<DataGridRow>(
          (entry) => DataGridRow(
            cells: [
              DataGridCell<int>(columnName: 'index', value: entry.key + 1),
              DataGridCell<String>(columnName: 'id', value: entry.value.id),
              DataGridCell<String>(columnName: 'name', value: entry.value.name),
              DataGridCell<double>(columnName: 'grade', value: entry.value.grade),
              DataGridCell<String>(columnName: 'created_at', value: entry.value.createdAt?.toString() ?? ''),
              DataGridCell<int>(columnName: 'actions', value: entry.key),
            ],
          ),
        )
        .toList();
  }

  List<DataGridRow> _rows = [];

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        if (dataGridCell.columnName == 'actions') {
          final index = dataGridCell.value as int;
          return Center(
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => onEdit(_quizzesList[index]),
            ),
          );
        }
        return Container(
          alignment: (dataGridCell.columnName == 'index' ||
                  dataGridCell.columnName == 'grade' ||
                  dataGridCell.columnName == 'created_at')
              ? Alignment.centerRight
              : Alignment.centerLeft,
          padding: const EdgeInsets.all(16.0),
          child: Text(dataGridCell.value.toString()),
        );
      }).toList(),
    );
  }
}
