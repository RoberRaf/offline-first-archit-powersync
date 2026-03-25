import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_poc/di.dart';
import 'package:flutter_poc/models/video.dart';
import 'package:flutter_poc/services/database_service.dart';

class VideosTab extends StatefulWidget {
  const VideosTab({super.key});

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  late final Stream<List<Video>> _stream;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _stream = di<DatabaseService>().watchAllVideos();
  }

  Future<void> _addVideo() async {
    final n = _random.nextInt(900) + 100;
    final offset = _random.nextInt(100);
    final video = Video(id: '', name: 'Video #$n', offset: offset, isCompleted: offset >= 100);
    await di<DatabaseService>().insert(video);
  }

  Future<void> _add100Videos() async {
    final models = List.generate(100, (i) {
      final offset = _random.nextInt(100);
      return Video(id: '', name: 'Video #${_random.nextInt(9000) + 1000}', offset: offset, isCompleted: offset >= 100);
    });
    await di<DatabaseService>().bulkInsert(models);
  }

  Future<void> _updateOffset(Video video, int newOffset) async {
    await di<DatabaseService>().update(
      Video(
        id: video.id,
        name: video.name,
        offset: newOffset,
        isCompleted: video.isCompleted || newOffset >= 100,
        createdAt: video.createdAt,
        updatedAt: video.updatedAt,
      ),
    );
  }

  Future<void> _deleteVideo(Video video) async {
    await di<DatabaseService>().delete(video);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Videos')),
      body: StreamBuilder<List<Video>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snapshot.data!;
          if (videos.isEmpty) {
            return const Center(child: Text('No videos yet. Tap + to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: videos.length,
            itemBuilder: (context, index) => _VideoCard(
              video: videos[index],
              onOffsetChanged: (val) => _updateOffset(videos[index], val),
              onDelete: () => _deleteVideo(videos[index]),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _addVideo,
              icon: const Icon(Icons.add),
              label: const Text('Add Video'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _add100Videos,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add 100'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Video video;
  final ValueChanged<int> onOffsetChanged;
  final VoidCallback onDelete;

  const _VideoCard({required this.video, required this.onOffsetChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final offsetPercent = video.offset.clamp(0, 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_fill, color: video.isCompleted ? Colors.green : Colors.deepPurple, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(video.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (video.isCompleted) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Offset', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const Spacer(),
                Text('$offsetPercent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: offsetPercent.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: Colors.deepPurple,
              label: '$offsetPercent%',
              onChanged: (val) => onOffsetChanged(val.round()),
            ),
            Row(
              children: [
                const Text('Completed', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const Spacer(),
                AbsorbPointer(
                  child: Switch(value: video.isCompleted, activeColor: Colors.deepPurple, onChanged: (c) {}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
