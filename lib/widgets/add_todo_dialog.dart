import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../models/todo_field.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';

class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<_FieldDraft> _fields = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _reminderEnabled = false;
  DateTime? _reminderAt;
  TodoType _type = TodoType.task;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  List<TodoFieldType> _availableFieldTypes(ThemeProvider settings) {
    return [
      if (settings.allowTextFields) TodoFieldType.text,
      if (settings.allowImageFields) TodoFieldType.image,
      if (settings.allowVideoFields) TodoFieldType.video,
      if (settings.allowNumberFields) TodoFieldType.number,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<ThemeProvider>();
    final availableTypes = _availableFieldTypes(settings);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.72,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant.withAlpha(160),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.add_task_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New task',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Keep it short, clear, and useful',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<TodoType>(
                      segments: const [
                        ButtonSegment(
                          value: TodoType.task,
                          label: Text('Task'),
                          icon: Icon(Icons.task_alt_rounded),
                        ),
                        ButtonSegment(
                          value: TodoType.service,
                          label: Text('Service'),
                          icon: Icon(Icons.cleaning_services_rounded),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (value) {
                        setState(() {
                          _type = value.first;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      hintText: 'What needs to be done?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: settings.compactMode ? 2 : 3,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      hintText: 'Optional notes or context',
                    ),
                  ),
                  if (_type == TodoType.service) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Estimated price / salary per session',
                        hintText: 'e.g. 50.0',
                        prefixIcon: const Icon(Icons.payments_rounded),
                        prefixText: '${settings.currency.symbol} ',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _ReminderCard(
                    enabled: _reminderEnabled,
                    reminderAt: _reminderAt,
                    onToggle: (value) {
                      setState(() {
                        _reminderEnabled = value;
                        _reminderAt ??= DateTime.now().add(const Duration(hours: 1));
                        if (!value) {
                          _reminderAt = null;
                        }
                      });
                    },
                    onPick: () => _pickReminderDateTime(context),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Fields',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (availableTypes.isNotEmpty)
                        _FieldMenuButton(
                          availableTypes: availableTypes,
                          onSelected: _addField,
                        )
                      else
                        Expanded(
                          child: Text(
                            'Enable field types in Settings',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_fields.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Text(
                        availableTypes.isEmpty
                            ? 'Turn on field types from Settings.'
                            : 'Tap Add field to include notes, a camera image, a video link, or a number.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final field in _fields) ...[
                          _FieldDraftCard(
                            field: field,
                            availableTypes: availableTypes,
                            imagePicker: _imagePicker,
                            onChanged: () => setState(() {}),
                            onRemove: () {
                              setState(() {
                                _fields.remove(field);
                                field.dispose();
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      if (title.isEmpty) return;
                      if (_reminderEnabled) {
                        if (_reminderAt == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please choose a reminder date and time.'),
                            ),
                          );
                          return;
                        }
                        if (_reminderAt!.isBefore(DateTime.now())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reminder must be in the future.'),
                            ),
                          );
                          return;
                        }
                      }

                      final customFields = _fields
                          .map((field) => field.toTodoField())
                          .whereType<TodoField>()
                          .toList();

                      final todo = await Provider.of<TodoProvider>(context, listen: false).addTodo(
                        title,
                        _descController.text.trim(),
                        type: _type,
                        basePrice: double.tryParse(_priceController.text),
                        customFields: customFields,
                        reminderAt: _reminderEnabled ? _reminderAt : null,
                      );
                      if (_reminderEnabled) {
                        final scheduled = await TodoNotificationService.instance.scheduleReminder(todo);
                        if (!scheduled && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not schedule reminder on this device.'),
                            ),
                          );
                        }
                      }
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save task'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addField(TodoFieldType type) {
    setState(() {
      _fields.add(
        _FieldDraft(
          type: type,
          labelController: TextEditingController(text: type.label),
          valueController: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _pickReminderDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initial = _reminderAt ?? now.add(const Duration(hours: 1));
    final initialDate = initial.isAfter(now) ? initial : now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (!context.mounted) return;

    if (combined.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a future reminder time.'),
        ),
      );
      return;
    }

    setState(() {
      _reminderEnabled = true;
      _reminderAt = combined;
    });
  }
}

class _ReminderCard extends StatelessWidget {
  final bool enabled;
  final DateTime? reminderAt;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPick;

  const _ReminderCard({
    required this.enabled,
    required this.reminderAt,
    required this.onToggle,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: enabled,
            onChanged: onToggle,
            title: const Text('Reminder'),
            subtitle: const Text('Get a notification and alert sound'),
          ),
          if (enabled) ...[
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: Text(
                reminderAt == null
                    ? 'Select date and time'
                    : DateFormat('EEE, MMM d - h:mm a').format(reminderAt!),
              ),
              subtitle: const Text('Choose when you want to be reminded'),
              trailing: TextButton(
                onPressed: onPick,
                child: const Text('Pick'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldMenuButton extends StatelessWidget {
  final List<TodoFieldType> availableTypes;
  final ValueChanged<TodoFieldType> onSelected;

  const _FieldMenuButton({
    required this.availableTypes,
    required this.onSelected,
  });

  IconData _iconForType(TodoFieldType type) {
    return switch (type) {
      TodoFieldType.text => Icons.subject_rounded,
      TodoFieldType.image => Icons.image_rounded,
      TodoFieldType.video => Icons.videocam_rounded,
      TodoFieldType.number => Icons.pin_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodoFieldType>(
      tooltip: 'Add field',
      onSelected: onSelected,
      itemBuilder: (context) => availableTypes
          .map(
            (type) => PopupMenuItem<TodoFieldType>(
              value: type,
              child: Row(
                children: [
                  Icon(_iconForType(type), size: 18),
                  const SizedBox(width: 10),
                  Text(type.label),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Add field',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldDraft {
  TodoFieldType type;
  final TextEditingController labelController;
  final TextEditingController valueController;
  Uint8List? imageBytes;
  String? imageName;

  _FieldDraft({
    required this.type,
    required this.labelController,
    required this.valueController,
  });

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }

  bool get hasImage => imageBytes != null;

  Future<void> setImage(XFile file) async {
    imageBytes = await file.readAsBytes();
    imageName = file.name;
    valueController.clear();
  }

  TodoField? toTodoField() {
    final label = labelController.text.trim();

    switch (type) {
      case TodoFieldType.text:
      case TodoFieldType.video:
      case TodoFieldType.number:
        final value = valueController.text.trim();
        if (value.isEmpty && label.isEmpty) {
          return null;
        }
        if (value.isEmpty) {
          return null;
        }
        return TodoField(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: type,
          label: label.isEmpty ? type.label : label,
          value: value,
        );
      case TodoFieldType.image:
        if (imageBytes == null) {
          return null;
        }
        return TodoField(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: type,
          label: label.isEmpty ? type.label : label,
          value: 'base64:${base64Encode(imageBytes!)}',
        );
    }
  }
}

class _FieldDraftCard extends StatelessWidget {
  final _FieldDraft field;
  final List<TodoFieldType> availableTypes;
  final ImagePicker imagePicker;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _FieldDraftCard({
    required this.field,
    required this.availableTypes,
    required this.imagePicker,
    required this.onChanged,
    required this.onRemove,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (image == null) return;
      await field.setImage(image);
      onChanged();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker is not ready yet. Please fully restart the app after pub get.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TodoFieldType>(
                  value: field.type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                  ),
                  items: [
                    ...availableTypes,
                    if (!availableTypes.contains(field.type)) field.type,
                  ]
                      .map(
                        (type) => DropdownMenuItem<TodoFieldType>(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    field.type = value;
                    if (field.labelController.text.trim().isEmpty) {
                      field.labelController.text = value.label;
                    }
                    if (value == TodoFieldType.image) {
                      field.valueController.clear();
                    } else {
                      field.imageBytes = null;
                      field.imageName = null;
                    }
                    onChanged();
                  },
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: field.labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'For example: Cover image',
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          switch (field.type) {
            TodoFieldType.text => TextField(
                controller: field.valueController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  hintText: 'Add extra notes or instructions',
                ),
                onChanged: (_) => onChanged(),
              ),
            TodoFieldType.video => TextField(
                controller: field.valueController,
                decoration: const InputDecoration(
                  labelText: 'Video link',
                  hintText: 'Paste a video URL',
                ),
                onChanged: (_) => onChanged(),
              ),
            TodoFieldType.number => TextField(
                controller: field.valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Number',
                  hintText: 'Enter a price or count',
                ),
                onChanged: (_) => onChanged(),
              ),
            TodoFieldType.image => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (field.hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.memory(
                          field.imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.photo_camera_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Select an image from camera or gallery',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _pickImage(context, ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _pickImage(context, ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  if (field.hasImage) ...[
                    const SizedBox(height: 8),
                    Text(
                      field.imageName ?? 'Selected image',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
          },
        ],
      ),
    );
  }
}
