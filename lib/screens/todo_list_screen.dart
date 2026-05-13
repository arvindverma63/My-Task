import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';
import 'attendance_calendar_screen.dart';
import 'service_report_screen.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/todo_item.dart';
import 'theme_settings_screen.dart';
import 'employee_management_screen.dart';

import '../widgets/tutorial_guide.dart';

enum TodoFilter { all, active, completed }

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  TodoFilter _filter = TodoFilter.all;
  bool _tipsChecked = false;
  int _currentIndex = 0;
  bool _showTour = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowTips();
  }

  void _maybeShowTips() {
    if (_tipsChecked) return;
    final settings = context.read<ThemeProvider>();
    if (!settings.isLoaded) return;
    _tipsChecked = true;

    if (!settings.hasSeenTips) {
      setState(() => _showTour = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final settings = context.watch<ThemeProvider>();

    final filteredTodos = _applyFilter(todoProvider.todos, settings.groupCompletedAtBottom);
    final activeCount = todoProvider.todos.where((todo) => !todo.isCompleted).length;
    final completedCount = todoProvider.todos.length - activeCount;

    return Scaffold(
      body: Stack(
        children: [
          _buildBody(todoProvider, settings, filteredTodos, activeCount, completedCount),
          if (_showTour)
            TutorialOverlay(
              steps: const [
                TutorialStep(
                  title: 'Welcome to Premium Todo',
                  message: 'This is your focused space for productivity. Let\'s explore!',
                  alignment: Alignment.center,
                  icon: Icons.auto_awesome_rounded,
                ),
                TutorialStep(
                  title: 'Quick Actions',
                  message: 'Access your settings, service calendar, and add tasks quickly from here.',
                  alignment: Alignment.topRight,
                  icon: Icons.touch_app_rounded,
                ),
                TutorialStep(
                  title: 'Smart Navigation',
                  message: 'Switch between Tasks, Services, Employees, and Reports.',
                  alignment: Alignment.bottomCenter,
                  icon: Icons.navigation_rounded,
                ),
                TutorialStep(
                  title: 'Ready to start?',
                  message: 'Tap the "+" button to capture your first task and stay organized!',
                  alignment: Alignment.bottomRight,
                  icon: Icons.add_task_rounded,
                ),
              ],
              onFinish: () async {
                setState(() => _showTour = false);
                await context.read<ThemeProvider>().markTipsSeen();
              },
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 ? (settings.compactMode
          ? FloatingActionButton(
              onPressed: () => _showAddTodoDialog(context),
              child: const Icon(Icons.add_task_rounded),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showAddTodoDialog(context),
              label: const Text('New Task'),
              icon: const Icon(Icons.add_task_rounded),
            )) : null,
    );
  }

  Widget _buildBody(TodoProvider todoProvider, ThemeProvider settings, List<Todo> filteredTodos, int activeCount, int completedCount) {
    switch (_currentIndex) {
      case 0:
        return _buildTasksList(todoProvider, settings, filteredTodos, activeCount, completedCount);
      case 1:
        return const AttendanceCalendarScreen();
      case 2:
        return const EmployeeManagementScreen();
      case 3:
        return const ServiceReportScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.task_alt_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Employees',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Reports',
        ),
      ],
    );
  }

  Widget _buildTasksList(TodoProvider todoProvider, ThemeProvider settings, List<Todo> filteredTodos, int activeCount, int completedCount) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(160),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () => todoProvider.loadTodos(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    settings.compactMode ? 12 : 20,
                    20,
                    12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: const DecorationImage(
                                        image: AssetImage('assets/images/logo.png'),
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(20),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'My Tasks',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.6,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'A focused space for what matters today',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _HeaderActionButton(
                              icon: Icons.calendar_month_rounded,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              onPressed: () => _openAttendanceCalendar(context),
                              tooltip: 'Open Service Calendar',
                            ),
                            const SizedBox(width: 10),
                            _HeaderActionButton(
                              icon: Icons.settings_rounded,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              onPressed: () => _showSettingsSheet(context),
                              tooltip: 'App Settings',
                            ),
                            const SizedBox(width: 10),
                            _HeaderActionButton(
                              icon: Icons.add_rounded,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              onPressed: () => _showAddTodoDialog(context),
                              iconSize: 28,
                              tooltip: 'Quick Add Task',
                            ),
                          ],
                        ),
                        SizedBox(height: settings.compactMode ? 12 : 16),
                        _SummaryStrip(
                          activeCount: activeCount,
                          completedCount: completedCount,
                        ),
                        const SizedBox(height: 12),
                        if (!settings.hasSeenTips) const _TipsBanner(),
                        const SizedBox(height: 12),
                        _FilterBar(
                          filter: _filter,
                          onChanged: (value) {
                            setState(() {
                              _filter = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (todoProvider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredTodos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      filter: _filter,
                      compact: settings.compactMode,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      settings.compactMode ? 96 : 112,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final todo = filteredTodos[index];
                          return TodoItem(todo: todo);
                        },
                        childCount: filteredTodos.length,
                      ),
                    ),
                  ),
              ],
            ),
        ),
      ),
    );
  }

  List<Todo> _applyFilter(List<Todo> todos, bool groupCompletedAtBottom) {
    final filtered = switch (_filter) {
      TodoFilter.all => List<Todo>.from(todos),
      TodoFilter.active => todos.where((todo) => !todo.isCompleted).toList(),
      TodoFilter.completed => todos.where((todo) => todo.isCompleted).toList(),
    };

    if (groupCompletedAtBottom && _filter == TodoFilter.all) {
      filtered.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return a.isCompleted ? 1 : -1;
      });
    } else {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  void _showAddTodoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const AddTodoDialog(),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ThemeSettingsScreen(
          onStartTour: () {
            Navigator.pop(context);
            setState(() {
              _showTour = true;
            });
          },
        ),
      ),
    );
  }

  void _openAttendanceCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AttendanceCalendarScreen(),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final TodoFilter filter;
  final bool compact;

  const EmptyState({
    super.key,
    required this.filter,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      TodoFilter.all => 'No tasks yet',
      TodoFilter.active => 'No active tasks',
      TodoFilter.completed => 'No completed tasks',
    };
    final message = switch (filter) {
      TodoFilter.all => 'Create a task to get started and keep your day on track.',
      TodoFilter.active => 'You are all caught up. New tasks will appear here.',
      TodoFilter.completed => 'Finished tasks will appear here once you mark them done.',
    };

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 28 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 72 : 84,
              height: compact ? 72 : 84,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(170),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: compact ? 36 : 42,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final int activeCount;
  final int completedCount;

  const _SummaryStrip({
    required this.activeCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Active',
            value: activeCount.toString(),
            icon: Icons.radio_button_unchecked_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Completed',
            value: completedCount.toString(),
            icon: Icons.check_circle_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(160),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TodoFilter filter;
  final ValueChanged<TodoFilter> onChanged;

  const _FilterBar({
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      (TodoFilter.all, 'All'),
      (TodoFilter.active, 'Active'),
      (TodoFilter.completed, 'Done'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.$1 == filter;

          return ChoiceChip(
            label: Text(item.$2),
            selected: selected,
            onSelected: (_) => onChanged(item.$1),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _TipsBanner extends StatelessWidget {
  const _TipsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(180),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick tips',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a task to mark it done, use filters to focus, and open Settings to keep the list compact.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsSheet extends StatefulWidget {
  const _TipsSheet({super.key});

  @override
  State<_TipsSheet> createState() => _TipsSheetState();
}

class _TipsSheetState extends State<_TipsSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TourStep> _steps = [
    const _TourStep(
      icon: Icons.auto_awesome_rounded,
      title: 'Welcome to Todo Board',
      description: 'Your premium space for productivity. Let\'s get you started with a quick tour.',
    ),
    const _TourStep(
      icon: Icons.add_task_rounded,
      title: 'Quick Capture',
      description: 'Tap the "+" button to add tasks instantly. You can add titles, descriptions, and even set reminders.',
    ),
    const _TourStep(
      icon: Icons.payments_rounded,
      title: 'Service & Reports',
      description: 'Track earnings and sessions with the Service Calendar. View detailed financial reports anytime.',
    ),
    const _TourStep(
      icon: Icons.tune_rounded,
      title: 'Personalize Everything',
      description: 'Change currencies, toggle compact mode, or adjust colors in Settings to match your workflow.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 480,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.icon,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  _steps.length,
                  (index) => Container(
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == index ? colorScheme.primary : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  if (_currentPage < _steps.length - 1)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(_currentPage == _steps.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TourStep {
  final IconData icon;
  final String title;
  final String description;

  const _TourStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TipRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final double iconSize;
  final String? tooltip;

  const _HeaderActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.iconSize = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: foregroundColor,
          size: iconSize,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    return button;
  }
}
