import 'package:flutter/material.dart';
import 'package:flutter_poc/di.dart';
import 'package:flutter_poc/powersync/database.dart';
import 'package:flutter_poc/view/notes/notes_tab.dart';
import 'package:flutter_poc/view/quizzes/quizzes_tab.dart';
import 'package:flutter_poc/view/videos/videos_tab.dart';
import 'package:flutter_poc/view/widgets/sync_status_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await openDatabase();
  await init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(32),
          child: SyncStatusBar(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Notes'),
                Tab(text: 'Quizzes'),
              ],
              controller: tabController,
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  VideosTab(),
                  NotesTab(),
                  QuizzesTab(),
                  // Phase4Tab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
