import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PreferencesService _service = PreferencesService();
  final TextEditingController _addController = TextEditingController();

  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final loadedTasks = await _service.loadTasks();

    if (!mounted) return;

    setState(() {
      _tasks = loadedTasks;
      _isLoading = false;
    });
  }

  Future<void> _saveTasks(List<Task> updatedTasks) async {
    await _service.saveTasks(updatedTasks);

    if (!mounted) return;

    setState(() {
      _tasks = updatedTasks;
    });
  }

  Future<void> _addTask() async {
    final title = _addController.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
    );

    await _saveTasks([..._tasks, task]);
    _addController.clear();
  }

  Future<void> _toggleDone(Task task) async {
    final updatedTasks = _tasks.map((currentTask) {
      if (currentTask.id == task.id) {
        return currentTask.copyWith(isDone: !currentTask.isDone);
      }
      return currentTask;
    }).toList();

    await _saveTasks(updatedTasks);
  }

  Future<void> _deleteTask(Task task) async {
    final updatedTasks = _tasks
        .where((currentTask) => currentTask.id != task.id)
        .toList();

    await _saveTasks(updatedTasks);
  }

  Future<void> _editTask(Task task) async {
    final controller = TextEditingController(text: task.title);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sửa task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nhập tiêu đề mới',
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || result == null) return;

    final newTitle = result.trim();
    if (newTitle.isEmpty) return;

    final updatedTasks = _tasks.map((currentTask) {
      if (currentTask.id == task.id) {
        return currentTask.copyWith(title: newTitle);
      }
      return currentTask;
    }).toList();

    await _saveTasks(updatedTasks);
  }

  Future<void> _clearAllTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa tất cả task?'),
          content: const Text('Bạn có chắc muốn xóa toàn bộ danh sách không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Có'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _service.clearTasks();

    if (!mounted) return;

    setState(() {
      _tasks = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Manager'),
        actions: [
          IconButton(
            tooltip: 'Xóa tất cả',
            onPressed: _clearAllTasks,
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: const InputDecoration(
                            labelText: 'Nhập task mới',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTask,
                        child: const Text('Thêm'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(child: Text('Chưa có task nào.'))
                      : ListView.separated(
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 0),
                          itemBuilder: (context, index) {
                            final task = _tasks[index];

                            return ListTile(
                              leading: Checkbox(
                                value: task.isDone,
                                onChanged: (_) => _toggleDone(task),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              onTap: () => _editTask(task),
                              trailing: IconButton(
                                tooltip: 'Xóa task',
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTask(task),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}