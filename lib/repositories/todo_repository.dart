import '../models/todo_model.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos();
  Future<void> saveTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
}
