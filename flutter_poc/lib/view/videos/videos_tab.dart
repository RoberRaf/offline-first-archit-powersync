import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_poc/di.dart';
import 'package:flutter_poc/models/video.dart';
import 'package:flutter_poc/services/database_service.dart';
import 'package:flutter_poc/view/videos/videos_data_source.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class VideosTab extends StatefulWidget {
  const VideosTab({super.key});

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  late final Stream<List<Video>> _stream;
  final nameCtrl = TextEditingController();
  final offsetCtrl = TextEditingController();
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _stream = di<DatabaseService>().watchAllVideos();
  }

  Future<void> _addVideo() async {
    final n = _random.nextInt(900) + 100;
    final video = Video(id: '', name: 'Video #$n', offset: _random.nextInt(300), isCompleted: _random.nextBool());
    await di<DatabaseService>().insert(video);
  }

  Future<void> _add100Videos() async {
    final models = List.generate(
      100,
      (i) => Video(
        id: '',
        name: 'Video #${_random.nextInt(9000) + 1000}',
        offset: _random.nextInt(300),
        isCompleted: _random.nextBool(),
      ),
    );
    await di<DatabaseService>().bulkInsert(models);
  }

  Future<void> _showEditVideoDialog(Video video) async {
    nameCtrl.text = video.name;
    offsetCtrl.text = video.offset.toString();
    bool isCompleted = video.isCompleted;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: offsetCtrl,
                decoration: const InputDecoration(labelText: 'Offset'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Completed'),
                  const Spacer(),
                  Switch(value: isCompleted, onChanged: (val) => setDialogState(() => isCompleted = val)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await di<DatabaseService>().update(
        Video(
          id: video.id,
          name: nameCtrl.text.trim(),
          offset: int.tryParse(offsetCtrl.text.trim()) ?? video.offset,
          isCompleted: isCompleted,
          createdAt: video.createdAt,
          updatedAt: video.updatedAt,
        ),
      );
    }

    nameCtrl.clear();
    offsetCtrl.clear();
  }

@override
  void dispose() {
    nameCtrl.dispose();
    offsetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Videos')),
      body: StreamBuilder<List<Video>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SfDataGrid(
                  source: VideosDataSource(videos: snapshot.data!, onEdit: _showEditVideoDialog),
                  columnWidthMode: ColumnWidthMode.auto,
                  columns: [
                    GridColumn(
                      columnName: 'index',
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text('#'),
                      ),
                    ),
                    // GridColumn(
                    //   columnName: 'id',
                    //   label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('ID')),
                    // ),
                    GridColumn(
                      columnName: 'name',
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text('Name'),
                      ),
                    ),
                    GridColumn(
                      columnName: 'offset',
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text('Offset'),
                      ),
                    ),
                    GridColumn(
                      columnName: 'is_completed',
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text('Completed'),
                      ),
                    ),
                    GridColumn(
                      columnName: 'created_at',
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text('Created At'),
                      ),
                    ),
                    GridColumn(
                      columnName: 'actions',
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: const Text('Actions'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _addVideo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16.0),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Video'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _add100Videos,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16.0),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add 100'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
