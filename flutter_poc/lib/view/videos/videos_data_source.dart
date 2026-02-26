import 'package:flutter/material.dart';
import 'package:flutter_poc/models/video.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class VideosDataSource extends DataGridSource {
  final List<Video> _videosList;
  final void Function(Video) onEdit;

  VideosDataSource({required List<Video> videos, required this.onEdit}) : _videosList = videos {
    _rows = videos
        .asMap()
        .entries
        .map<DataGridRow>(
          (entry) => DataGridRow(
            cells: [
              DataGridCell<int>(columnName: 'index', value: entry.key + 1),
              // DataGridCell<String>(columnName: 'id', value: entry.value.id),
              DataGridCell<String>(columnName: 'name', value: entry.value.name),
              DataGridCell<int>(columnName: 'offset', value: entry.value.offset),
              DataGridCell<bool>(columnName: 'is_completed', value: entry.value.isCompleted),
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
              onPressed: () => onEdit(_videosList[index]),
            ),
          );
        }
        return Container(
          alignment: (dataGridCell.columnName == 'index' ||
                  dataGridCell.columnName == 'offset' ||
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
