import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_poc/di.dart';
import 'package:flutter_poc/models/note.dart';
import 'package:flutter_poc/services/database_service.dart';
import 'package:intl/intl.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  late final Stream<List<Note>> _stream;
  final _random = Random();
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _stream = di<DatabaseService>().watchAllNotes();
  }

  Future<void> _addNote() async {
    final n = _random.nextInt(900) + 100;
    final note = Note(id: '', title: 'Note #$n', content: 'Auto-generated content for note $n.');
    await di<DatabaseService>().insert(note);
  }

  Future<void> _add100Notes() async {
    final models = List.generate(100, (i) {
      final n = _random.nextInt(9000) + 1000;
      return Note(id: '', title: 'Note #$n', content: 'Auto-generated content for note $n.');
    });
    await di<DatabaseService>().bulkInsert(models);
  }

  Future<void> _deleteNote(Note note) async {
    await di<DatabaseService>().delete(note);
  }

  Future<void> _showEditNoteDialog(Note note) async {
    titleCtrl.text = note.title;
    contentCtrl.text = note.content;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
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
    );

    if (confirmed == true) {
      await di<DatabaseService>().update(
        Note(
          id: note.id,
          title: titleCtrl.text.trim(),
          content: contentCtrl.text.trim(),
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
        ),
      );
    }

    titleCtrl.clear();
    contentCtrl.clear();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Notes')),
      body: StreamBuilder<List<Note>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (snapshot.data?.isNotEmpty != true)
                Expanded(
                  child: Center(
                    child: Text(
                      'No notes yet. Tap "Add Note" to create one.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (context, index) {
                      final note = snapshot.data![index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(
                                      note.updatedAt != null
                                          ? DateFormat('d MMM, h:mm a').format(note.updatedAt!)
                                          : '—',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                onPressed: () => _showEditNoteDialog(note),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNote(note),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _addNote,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16.0),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Note'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _add100Notes,
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
