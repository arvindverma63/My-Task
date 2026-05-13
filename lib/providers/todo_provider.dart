import 'package:flutter/material.dart';
import '../models/todo_activity.dart';
import '../models/todo_attendance.dart';
import '../models/todo_model.dart';
import '../models/todo_field.dart';
import '../repositories/todo_repository.dart';
import '../services/notification_service.dart';

class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;
  List<Todo> _todos = [];
  bool _isLoading = false;

  TodoProvider(this._repository) {
    loadTodos();
  }

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    _todos = await _repository.getTodos();
    _isLoading = false;
    notifyListeners();
  }

  Future<Todo> addTodo(
    String title,
    String description, {
    List<TodoField> customFields = const [],
    DateTime? reminderAt,
  }) async {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      reminderAt: reminderAt,
      customFields: customFields,
      activities: [
        TodoActivity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: TodoActivityType.created,
          title: 'Task created',
          createdAt: DateTime.now(),
        ),
      ],
    );
    await _repository.saveTodo(newTodo);
    _todos.add(newTodo);
    notifyListeners();
    return newTodo;
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repository.updateTodo(updatedTodo);
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      notifyListeners();
    }

    if (updatedTodo.isCompleted) {
      await TodoNotificationService.instance.cancelReminder(updatedTodo);
      await addActivity(
        todo.id,
        'Task completed',
        type: TodoActivityType.completed,
      );
    } else {
      await TodoNotificationService.instance.scheduleReminder(updatedTodo);
      await addActivity(
        todo.id,
        'Task reopened',
        type: TodoActivityType.reopened,
      );
    }
  }

  Future<void> removeTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final todo = _todos[index];
    await TodoNotificationService.instance.cancelReminder(todo);
    await _repository.deleteTodo(id);
    _todos.removeAt(index);
    notifyListeners();
  }

  Future<void> rescheduleAllReminders() async {
    for (final todo in _todos) {
      await TodoNotificationService.instance.cancelReminder(todo);
      if (!todo.isCompleted && todo.reminderAt != null && todo.reminderAt!.isAfter(DateTime.now())) {
        await TodoNotificationService.instance.scheduleReminder(todo);
      }
    }
  }

  Future<void> addActivity(
    String todoId,
    String title, {
    TodoActivityType type = TodoActivityType.note,
    String description = '',
  }) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index == -1) return;

    final todo = _todos[index];
    final updated = todo.copyWith(
      activities: [
        ...todo.activities,
        TodoActivity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: type,
          title: title,
          description: description,
          createdAt: DateTime.now(),
        ),
      ],
    );
    await _repository.updateTodo(updated);
    _todos[index] = updated;
    notifyListeners();
  }

  Future<void> markAttendance(
    String todoId,
    DateTime date,
    AttendanceStatus status, {
    String note = '',
  }) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index == -1) return;

    final todo = _todos[index];
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final records = [...todo.attendanceRecords];
    final recordIndex = records.indexWhere(
      (record) =>
          record.date.year == normalizedDate.year &&
          record.date.month == normalizedDate.month &&
          record.date.day == normalizedDate.day,
    );

    final updatedRecord = TodoAttendanceRecord(
      id: recordIndex == -1
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : records[recordIndex].id,
      date: normalizedDate,
      status: status,
      note: note,
      createdAt: DateTime.now(),
    );

    if (recordIndex == -1) {
      records.add(updatedRecord);
    } else {
      records[recordIndex] = updatedRecord;
    }

    final updated = todo.copyWith(attendanceRecords: records);
    await _repository.updateTodo(updated);
    _todos[index] = updated;
    notifyListeners();

    await addActivity(
      todoId,
      status == AttendanceStatus.present ? 'Marked present' : 'Marked absent',
      description: DateTime(date.year, date.month, date.day).toIso8601String().split('T').first,
    );
  }
}
