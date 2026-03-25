import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_poc/di.dart';
import 'package:flutter_poc/models/quiz.dart';
import 'package:flutter_poc/services/database_service.dart';
import 'package:intl/intl.dart';

class QuizzesTab extends StatefulWidget {
  const QuizzesTab({super.key});

  @override
  State<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<QuizzesTab> {
  late final Stream<List<Quiz>> _stream;
  final _random = Random();
  final nameCtrl = TextEditingController();
  final gradeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stream = di<DatabaseService>().watchAllQuizzes();
  }

  Future<void> _addQuiz() async {
    final n = _random.nextInt(900) + 100;
    final quiz = Quiz(id: '', name: 'Quiz #$n');
    await di<DatabaseService>().insert(quiz);
  }

  Future<void> _add100Quizzes() async {
    final models = List.generate(
      100,
      (i) => Quiz(
        id: '',
        name: 'Quiz #${_random.nextInt(9000) + 1000}',
        grade: double.parse((_random.nextDouble() * 100).toStringAsFixed(1)),
      ),
    );
    await di<DatabaseService>().bulkInsert(models);
  }

  Future<void> _showEditQuizDialog(Quiz quiz) async {
    nameCtrl.text = quiz.name;
    gradeCtrl.text = quiz.grade.toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeCtrl,
              decoration: const InputDecoration(labelText: 'Grade'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        Quiz(
          id: quiz.id,
          name: nameCtrl.text.trim(),
          grade: double.tryParse(gradeCtrl.text.trim()) ?? quiz.grade,
          createdAt: quiz.createdAt,
          updatedAt: quiz.updatedAt,
        ),
      );
    }

    nameCtrl.clear();
    gradeCtrl.clear();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    gradeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Quizzes')),
      body: StreamBuilder<List<Quiz>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          return Column(
            children: [
              if (snapshot.data?.isNotEmpty != true)
                Expanded(
                  child: const Center(
                    child: Text(
                      'No quizzes yet. Tap "Add Quiz" to create one.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    itemBuilder: (context, index) {
                      final quiz = snapshot.data![index];
                      final createdAt = quiz.createdAt != null
                          ? DateFormat('d MMM h:mm a').format(quiz.createdAt!)
                          : '';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(quiz.name),
                          subtitle: Text(createdAt),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${quiz.grade}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                onPressed: () => _showEditQuizDialog(quiz),
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
                      onPressed: _addQuiz,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 16.0),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Quiz'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _add100Quizzes,
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
