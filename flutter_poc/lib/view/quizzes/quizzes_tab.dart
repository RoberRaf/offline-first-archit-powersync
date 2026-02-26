import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_poc/di.dart';
import 'package:flutter_poc/models/quiz.dart';
import 'package:flutter_poc/services/database_service.dart';
import 'package:flutter_poc/view/quizzes/quizzes_data_source.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

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
    final grade = double.parse((_random.nextDouble() * 100).toStringAsFixed(1));
    final quiz = Quiz(
      id: '',
      name: 'Quiz #$n',
      grade: grade,
    );
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
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gradeCtrl,
              decoration: const InputDecoration(labelText: 'Grade'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
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
      appBar: AppBar(centerTitle: true,title: const Text('Quizzes')),
      body: StreamBuilder<List<Quiz>>(
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
                  source: QuizzesDataSource(quizzes: snapshot.data!, onEdit: _showEditQuizDialog),
                  columnWidthMode: ColumnWidthMode.auto,
                  columns: [
                    GridColumn(
                      columnName: 'index',
                      label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('#')),
                    ),
                    GridColumn(
                      columnName: 'id',
                      label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('ID')),
                    ),
                    GridColumn(
                      columnName: 'name',
                      label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('Name')),
                    ),
                    GridColumn(
                      columnName: 'grade',
                      label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('Grade')),
                    ),
                    GridColumn(
                      columnName: 'created_at',
                      label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('Created At')),
                    ),
                    GridColumn(
                      columnName: 'actions',
                      label: Container(padding: const EdgeInsets.all(8.0), alignment: Alignment.center, child: const Text('Actions')),
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
