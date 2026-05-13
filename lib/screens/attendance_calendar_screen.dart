import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_activity.dart';
import '../models/todo_attendance.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  String? _selectedTodoId;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _activityController = TextEditingController();

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoProvider>().todos;
    final serviceTodos = todos;
    if (serviceTodos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Service calendar'),
        ),
        body: _EmptyServiceState(
          onAddPressed: () => Navigator.pop(context),
        ),
      );
    }

    _selectedTodoId ??= serviceTodos.first.id;
    final selectedTodo = serviceTodos.firstWhere(
      (todo) => todo.id == _selectedTodoId,
      orElse: () => serviceTodos.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service calendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Track present, absent, and task activity in one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Todo>(
            value: selectedTodo,
            decoration: const InputDecoration(
              labelText: 'Service / task',
            ),
            items: serviceTodos
                .map(
                  (todo) => DropdownMenuItem<Todo>(
                    value: todo,
                    child: Text(todo.title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedTodoId = value.id;
                _visibleMonth = DateTime(value.createdAt.year, value.createdAt.month);
                _selectedDate = DateTime.now();
              });
            },
          ),
          const SizedBox(height: 16),
          _MonthHeader(
            month: _visibleMonth,
            onPrevious: () {
              setState(() {
                _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
              });
            },
            onNext: () {
              setState(() {
                _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
              });
            },
          ),
          const SizedBox(height: 12),
          _AttendanceCalendar(
            month: _visibleMonth,
            records: selectedTodo.attendanceRecords,
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const SizedBox(height: 16),
          _Legend(),
          const SizedBox(height: 16),
          _ActionCard(
            selectedDate: _selectedDate,
            selectedTodo: selectedTodo,
            activityController: _activityController,
            onPresent: () => _markAttendance(AttendanceStatus.present),
            onAbsent: () => _markAttendance(AttendanceStatus.absent),
            onAddActivity: () => _addActivity(),
          ),
          const SizedBox(height: 16),
          Text(
            'Recent activities',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...selectedTodo.activities.reversed.take(8).map(
                (activity) => _ActivityTile(activity: activity),
              ),
          const SizedBox(height: 16),
          Text(
            'Attendance history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...selectedTodo.attendanceRecords.reversed.take(12).map(
                (record) => _AttendanceTile(record: record),
              ),
        ],
      ),
    );
  }

  Future<void> _markAttendance(AttendanceStatus status) async {
    final todo = _currentSelectedTodo(context);
    if (todo == null) return;

    await context.read<TodoProvider>().markAttendance(
          todo.id,
          _selectedDate,
          status,
        );
  }

  Future<void> _addActivity() async {
    final todo = _currentSelectedTodo(context);
    final text = _activityController.text.trim();
    if (todo == null || text.isEmpty) return;

    await context.read<TodoProvider>().addActivity(
          todo.id,
          text,
        );
    _activityController.clear();
  }

  Todo? _currentSelectedTodo(BuildContext context) {
    final todos = context.read<TodoProvider>().todos;
    if (todos.isEmpty) return null;
    final selectedId = _selectedTodoId ?? todos.first.id;
    return todos.firstWhere(
      (todo) => todo.id == selectedId,
      orElse: () => todos.first,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  final DateTime month;
  final List<TodoAttendanceRecord> records;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _AttendanceCalendar({
    required this.month,
    required this.records,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlank = firstDay.weekday % 7;
    final totalCells = leadingBlank + daysInMonth;
    final trailingBlank = (7 - (totalCells % 7)) % 7;
    final cells = totalCells + trailingBlank;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leadingBlank + 1;
        if (index < leadingBlank || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(month.year, month.month, dayNumber);
        final record = _recordForDate(date);
        final selected = _isSameDay(date, selectedDate);
        final colorScheme = Theme.of(context).colorScheme;

        final backgroundColor = record == null
            ? colorScheme.surfaceContainerHighest.withAlpha(120)
            : record.status == AttendanceStatus.present
                ? Colors.green.withAlpha(40)
                : Colors.red.withAlpha(40);
        final borderColor = selected
            ? colorScheme.primary
            : record == null
                ? colorScheme.outlineVariant.withAlpha(70)
                : record.status == AttendanceStatus.present
                    ? Colors.green.withAlpha(140)
                    : Colors.red.withAlpha(140);

        return InkWell(
          onTap: () => onDateSelected(date),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                if (record != null)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: record.status == AttendanceStatus.present ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  TodoAttendanceRecord? _recordForDate(DateTime date) {
    for (final record in records) {
      if (_isSameDay(record.date, date)) {
        return record;
      }
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendChip(label: 'Present', color: Colors.green),
        _LegendChip(label: 'Absent', color: Colors.red),
        _LegendChip(label: 'No record', color: Colors.grey),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final DateTime selectedDate;
  final Todo selectedTodo;
  final TextEditingController activityController;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onAddActivity;

  const _ActionCard({
    required this.selectedDate,
    required this.selectedTodo,
    required this.activityController,
    required this.onPresent,
    required this.onAbsent,
    required this.onAddActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions for ${selectedTodo.title}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEE, MMM d').format(selectedDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onPresent,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Present'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAbsent,
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Absent'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: activityController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Activity note',
                hintText: 'For example: cleaned kitchen, paid rent, inspected room',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAddActivity,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final TodoActivity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_activity_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final TodoAttendanceRecord record;

  const _AttendanceTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.status == AttendanceStatus.present ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            record.status == AttendanceStatus.present ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.status.label} - ${DateFormat('EEE, MMM d').format(record.date)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    record.note,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyServiceState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyServiceState({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No service tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a maid or service task first, then use the calendar to mark present and absent days.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAddPressed,
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
