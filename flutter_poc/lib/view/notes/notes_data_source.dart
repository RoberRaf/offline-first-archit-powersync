import 'package:flutter/material.dart';
import 'package:flutter_poc/models/note.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class NotesDataSource extends DataGridSource {
  final List<Note> _notesList;
  final void Function(Note) onEdit;

  NotesDataSource({required List<Note> notes, required this.onEdit}) : _notesList = notes {
    _rows = notes
        .asMap()
        .entries
        .map<DataGridRow>(
          (entry) => DataGridRow(
            cells: [
              DataGridCell<int>(columnName: 'index', value: entry.key + 1),
              DataGridCell<String>(columnName: 'id', value: entry.value.id),
              DataGridCell<String>(columnName: 'title', value: entry.value.title),
              DataGridCell<String>(columnName: 'content', value: entry.value.content),
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
              onPressed: () => onEdit(_notesList[index]),
            ),
          );
        }
        return Container(
          alignment: (dataGridCell.columnName == 'index' ||
                  dataGridCell.columnName == 'id' ||
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
