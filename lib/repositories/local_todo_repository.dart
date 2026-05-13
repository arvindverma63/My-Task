import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';
import 'todo_repository.dart';

class LocalTodoRepository implements TodoRepository {
  static const String _storageKey = 'todos';

  @override
  Future<List<Todo>> getTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString(_storageKey);
    if (todosJson == null) return [];

    final List<dynamic> decoded = json.decode(todosJson);
    return decoded.map((item) => Todo.fromMap(item)).toList();
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    final todos = await getTodos();
    todos.add(todo);
    await _saveToDisk(todos);
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = todo;
      await _saveToDisk(todos);
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    final todos = await getTodos();
    todos.removeWhere((t) => t.id == id);
    await _saveToDisk(todos);
  }

  Future<void> _saveToDisk(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(todos.map((t) => t.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
