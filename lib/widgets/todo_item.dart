import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_activity.dart';
import '../models/todo_attendance.dart';
import '../models/todo_field.dart';
import '../models/todo_model.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeProvider>();
    final compact = settings.compactMode;
    final showDescriptions = settings.showDescriptions;
    final showTimestamps = settings.showTimestamps;

    final basePadding = compact ? 12.0 : 16.0;
    final titleSize = compact ? 16.0 : 18.0;
    final descriptionSize = compact ? 13.0 : 14.0;
    final timestampSize = compact ? 11.0 : 12.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(
          color: todo.isCompleted
              ? Theme.of(context).colorScheme.outlineVariant.withAlpha(120)
              : Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          onTap: () {
            Provider.of<TodoProvider>(context, listen: false).toggleTodoStatus(todo);
          },
          child: Padding(
            padding: EdgeInsets.all(basePadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Provider.of<TodoProvider>(context, listen: false).toggleTodoStatus(todo);
                  },
                  child: Container(
                    width: compact ? 24 : 28,
                    height: compact ? 24 : 28,
                    margin: EdgeInsets.only(top: compact ? 2 : 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: todo.isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                      color: todo.isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: todo.isCompleted
                        ? Icon(
                            Icons.check,
                            size: compact ? 15 : 18,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
                SizedBox(width: compact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: todo.isCompleted
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            completed: todo.isCompleted,
                            compact: compact,
                          ),
                        ],
                      ),
                      if (showDescriptions && todo.description.isNotEmpty) ...[
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          todo.description,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: descriptionSize,
                            height: 1.35,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                      if (todo.reminderAt != null) ...[
                        SizedBox(height: compact ? 8 : 10),
                        _ReminderChip(
                          reminderAt: todo.reminderAt!,
                          completed: todo.isCompleted,
                          compact: compact,
                        ),
                      ],
                      if (todo.customFields.isNotEmpty) ...[
                        SizedBox(height: compact ? 8 : 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: todo.customFields
                              .map((field) => _FieldView(field: field, compact: compact))
                              .toList(),
                        ),
                      ],
                      if (todo.activities.isNotEmpty) ...[
                        SizedBox(height: compact ? 8 : 10),
                        _ActivityPreview(activities: todo.activities, compact: compact),
                      ],
                      if (todo.attendanceRecords.isNotEmpty) ...[
                        SizedBox(height: compact ? 8 : 10),
                        _AttendancePreview(records: todo.attendanceRecords, compact: compact),
                      ],
                      if (showTimestamps) ...[
                        SizedBox(height: compact ? 6 : 8),
                        Text(
                          DateFormat('MMM d, h:mm a').format(todo.createdAt),
                          style: TextStyle(
                            fontSize: timestampSize,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(180),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                  onPressed: () {
                    _showDeleteConfirm(context);
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<TodoProvider>(context, listen: false).removeTodo(todo.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool completed;
  final bool compact;

  const _StatusChip({
    required this.completed,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: completed
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer.withAlpha(180),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        completed ? 'Done' : 'Active',
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: completed
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _FieldView extends StatelessWidget {
  final TodoField field;
  final bool compact;

  const _FieldView({
    required this.field,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: field.type == TodoFieldType.image
          ? 180
          : null,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(130),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(70)),
      ),
      child: switch (field.type) {
        TodoFieldType.text => _TextFieldView(field: field, compact: compact),
        TodoFieldType.image => _ImageFieldView(field: field, compact: compact),
        TodoFieldType.video => _VideoFieldView(field: field, compact: compact),
        TodoFieldType.number => _NumberFieldView(field: field, compact: compact),
      },
    );
  }
}

class _TextFieldView extends StatelessWidget {
  final TodoField field;
  final bool compact;

  const _TextFieldView({
    required this.field,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          field.value,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ImageFieldView extends StatelessWidget {
  final TodoField field;
  final bool compact;

  const _ImageFieldView({
    required this.field,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeImageBytes(field.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (imageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          _MediaPlaceholder(
            icon: Icons.image_rounded,
            text: 'Image attached',
          ),
      ],
    );
  }

  Uint8List? _decodeImageBytes(String value) {
    if (!value.startsWith('base64:')) {
      return null;
    }

    try {
      return base64Decode(value.substring('base64:'.length));
    } catch (_) {
      return null;
    }
  }
}

class _VideoFieldView extends StatelessWidget {
  final TodoField field;
  final bool compact;

  const _VideoFieldView({
    required this.field,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        _MediaPlaceholder(
          icon: Icons.play_circle_fill_rounded,
          text: field.value,
        ),
      ],
    );
  }
}

class _NumberFieldView extends StatelessWidget {
  final TodoField field;
  final bool compact;

  const _NumberFieldView({
    required this.field,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pin_rounded,
              size: compact ? 14 : 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              field.value,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MediaPlaceholder({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final DateTime reminderAt;
  final bool completed;
  final bool compact;

  const _ReminderChip({
    required this.reminderAt,
    required this.completed,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = !completed && reminderAt.isBefore(DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: overdue
            ? colorScheme.errorContainer.withAlpha(180)
            : colorScheme.primaryContainer.withAlpha(160),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue
              ? colorScheme.error.withAlpha(70)
              : colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.notification_important_rounded : Icons.notifications_active_rounded,
            size: compact ? 16 : 18,
            color: overdue ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            overdue
                ? 'Reminder due ${DateFormat('MMM d, h:mm a').format(reminderAt)}'
                : 'Reminder ${DateFormat('MMM d, h:mm a').format(reminderAt)}',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: overdue ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPreview extends StatelessWidget {
  final List<TodoActivity> activities;
  final bool compact;

  const _ActivityPreview({
    required this.activities,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final recent = activities.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activities',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recent
              .map(
                (activity) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(130),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AttendancePreview extends StatelessWidget {
  final List<TodoAttendanceRecord> records;
  final bool compact;

  const _AttendancePreview({
    required this.records,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final recent = records.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recent
              .map(
                (record) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: record.status == AttendanceStatus.present
                        ? Colors.green.withAlpha(28)
                        : Colors.red.withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${record.status.label} ${DateFormat('MMM d').format(record.date)}',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: record.status == AttendanceStatus.present
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
