import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../widgets/app_bar_actions.dart';

class RevisionsScreen extends StatefulWidget {
  const RevisionsScreen({super.key});

  @override
  State<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends State<RevisionsScreen> {
  static const _transitKey = 'transit_tasks';
  static const _dailyKey = 'daily_tasks';

  static const List<Map<String, dynamic>> _defaultTransit = [
    {"task": "Walkaround visual (Daños externos, fugas)", "isDone": false},
    {"task": "Revisar desgaste de frenos (Brake wear pins)", "isDone": false},
    {
      "task": "Comprobar nivel de aceite del motor (MCDU / FWD Panel)",
      "isDone": false
    },
  ];

  static const List<Map<String, dynamic>> _defaultDaily = [
    {"task": "Comprobar fluido hidráulico (Qty y estado)", "isDone": false},
    {
      "task": "Inspeccion visual APU (fugas, estado externo)",
      "isDone": false
    },
    {"task": "Verificar luces exteriores (NAV, STROBE, LOGO)", "isDone": false},
  ];

  List<Map<String, dynamic>> transitTasks = [];
  List<Map<String, dynamic>> dailyTasks = [];
  bool _loading = true;

  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final transitEncoded = prefs.getString(_transitKey);
    final dailyEncoded = prefs.getString(_dailyKey);

    if (mounted) {
      setState(() {
        transitTasks = transitEncoded != null
            ? (json.decode(transitEncoded) as List)
                .cast<Map<String, dynamic>>()
            : _defaultTransit.map((t) => Map<String, dynamic>.from(t)).toList();

        dailyTasks = dailyEncoded != null
            ? (json.decode(dailyEncoded) as List).cast<Map<String, dynamic>>()
            : _defaultDaily.map((t) => Map<String, dynamic>.from(t)).toList();

        _loading = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transitKey, json.encode(transitTasks));
    await prefs.setString(_dailyKey, json.encode(dailyTasks));
  }

  void _resetTasks() {
    setState(() {
      for (var item in transitTasks) {
        item["isDone"] = false;
      }
      for (var item in dailyTasks) {
        item["isDone"] = false;
      }
    });
    _saveTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.revisionsResetMsg)),
      );
    }
  }

  void _showAddTaskDialog(List<Map<String, dynamic>> targetList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.revisionsAddTask),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: AppStrings.revisionsTaskHint),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _taskController.clear();
              Navigator.pop(context);
            },
            child: const Text(AppStrings.revisionsCancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                setState(() {
                  targetList
                      .add({"task": _taskController.text, "isDone": false});
                });
                _saveTasks();
                _taskController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text(AppStrings.revisionsAdd),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No hay tareas. Pulsa + para añadir.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey('${task['task']}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            final removed = task['task'] as String;
            setState(() => tasks.removeAt(index));
            _saveTasks();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$removed — ${AppStrings.revisionsDeletedMsg}'),
                  action: SnackBarAction(
                    label: 'Deshacer',
                    onPressed: () {
                      setState(() => tasks.insert(index.clamp(0, tasks.length), task));
                      _saveTasks();
                    },
                  ),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: CheckboxListTile(
              title: Text(
                task["task"] as String,
                style: TextStyle(
                  decoration: task["isDone"] as bool
                      ? TextDecoration.lineThrough
                      : null,
                  color: task["isDone"] as bool
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              value: task["isDone"] as bool,
              activeColor: Colors.green,
              onChanged: (bool? newValue) {
                setState(() => task["isDone"] = newValue!);
                _saveTasks();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.revisionsTitle),
          backgroundColor: const Color(0xFF0033A0),
          foregroundColor: Colors.white,
          actions: [
            ...buildAppBarActions(context),
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: AppStrings.revisionsResetTooltip,
              onPressed: _resetTasks,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: AppStrings.revisionsTransit),
              Tab(text: AppStrings.revisionsDaily),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) => TabBarView(
                  children: [
                    _buildTaskList(transitTasks),
                    _buildTaskList(dailyTasks),
                  ],
                ),
              ),
        floatingActionButton: _loading
            ? null
            : Builder(
                builder: (context) {
                  final tabController = DefaultTabController.of(context);
                  return FloatingActionButton(
                    backgroundColor: const Color(0xFF0033A0),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      final targetList = tabController.index == 0
                          ? transitTasks
                          : dailyTasks;
                      _showAddTaskDialog(targetList);
                    },
                    child: const Icon(Icons.add),
                  );
                },
              ),
      ),
    );
  }
}
