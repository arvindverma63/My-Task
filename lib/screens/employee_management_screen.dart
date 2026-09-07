import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/employee_provider.dart';
import '../models/employee_model.dart';
import 'employee_detail_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/pdf_service.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isMarkingAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final employeeProvider = context.watch<EmployeeProvider>();
    final employees = employeeProvider.employees.where((e) {
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             e.contact.contains(_searchQuery);
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        onRefresh: () => context.read<EmployeeProvider>().refreshData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0x1E10B981), // Emerald green 12% alpha
                            Color(0x0A10B981), // Emerald green 4% alpha
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x3310B981), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.assignment_ind_rounded, color: Color(0xFF10B981), size: 17),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Attendance Register',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Manage check-ins, wages, and offsets',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant.withAlpha(180),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0x2210B981),
                                  foregroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(6),
                                ),
                                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                tooltip: 'PDF Report',
                                onPressed: () => _generateMainReport(context),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(6),
                                ),
                                icon: const Icon(Icons.person_add_rounded, size: 18),
                                tooltip: 'Add Helper',
                                onPressed: () => _showAddEmployeeDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (employeeProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                          child: LinearProgressIndicator(
                            minHeight: 2.5,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSearchAndCalendar(colorScheme, employees),
          ),
          employees.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: employeeProvider.isLoading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 2.8,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Syncing employee records...',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded, size: 48, color: colorScheme.outlineVariant),
                              const SizedBox(height: 10),
                              const Text('No employees found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                'Tap the + button above to add a helper.',
                                style: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(160), fontSize: 11.5),
                              ),
                            ],
                          ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final employee = employees[index];
                        return _CompactEmployeeCard(
                          employee: employee,
                          selectedDate: _selectedDate,
                        );
                      },
                      childCount: employees.length,
                    ),
                  ),
                ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateDailyReport(context, employees),
        icon: const Icon(Icons.description_rounded),
        label: const Text('Daily Report'),
      ),
    );
  }

  Widget _buildSearchAndCalendar(ColorScheme colorScheme, List<Employee> employees) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        FutureBuilder<Map<String, List<AttendanceStatus>>>(
          future: _getDailyStatuses(context, employees, _selectedDate),
          builder: (context, snapshot) {
            final statuses = snapshot.data ?? {};
            final total = employees.length;
            final present = statuses.values.where((sList) => sList.any((s) => s != AttendanceStatus.absent)).length;
            final absent = statuses.values.where((sList) => sList.isNotEmpty && sList.every((s) => s == AttendanceStatus.absent)).length;
            final unmarked = total - statuses.values.where((sList) => sList.isNotEmpty).length;

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: _buildGradientSummaryCard(
                      context,
                      title: 'Present Today',
                      value: '$present',
                      icon: Icons.check_circle_rounded,
                      colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGradientSummaryCard(
                      context,
                      title: 'Absent / Unmarked',
                      value: '${absent + unmarked}',
                      icon: Icons.cancel_rounded,
                      colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name or contact...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 51 : 7),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDate,
            calendarFormat: _calendarFormat,
            headerVisible: true,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Week',
              CalendarFormat.month: 'Month',
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                shape: BoxShape.rectangle,
              ),
              todayDecoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 1.2),
                borderRadius: BorderRadius.circular(8),
                shape: BoxShape.rectangle,
              ),
              defaultDecoration: const BoxDecoration(
                shape: BoxShape.rectangle,
              ),
              weekendDecoration: const BoxDecoration(
                shape: BoxShape.rectangle,
              ),
              holidayDecoration: const BoxDecoration(
                shape: BoxShape.rectangle,
              ),
              outsideDecoration: const BoxDecoration(
                shape: BoxShape.rectangle,
              ),
              markerDecoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
              cellMargin: const EdgeInsets.all(2),
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontSize: 12),
              weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontSize: 12),
              holidayTextStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontSize: 12),
              todayTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 12),
              selectedTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurface),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary.withAlpha(120), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              formatButtonTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 9.5),
              formatButtonPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: colorScheme.primary, size: 18),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: colorScheme.primary, size: 18),
              headerPadding: const EdgeInsets.symmetric(vertical: 2),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(150), fontWeight: FontWeight.bold, fontSize: 10),
              weekendStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(150), fontWeight: FontWeight.bold, fontSize: 10),
              dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0].toUpperCase(),
            ),
            rowHeight: 34,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: colorScheme.primary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tap ✓ for Present, ✕ for Absent',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                onPressed: (employees.isEmpty || _isMarkingAll) ? null : () => _markAllPresent(context, employees),
                icon: _isMarkingAll
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.done_all_rounded, size: 15),
                label: Text(
                  _isMarkingAll ? 'Marking...' : 'All Present',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.first.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70, 
                    fontSize: 9.5, 
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 15, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, List<AttendanceStatus>>> _getDailyStatuses(BuildContext context, List<Employee> employees, DateTime date) async {
    final provider = context.read<EmployeeProvider>();
    final Map<String, List<AttendanceStatus>> statuses = {};
    for (var emp in employees) {
      final list = await provider.getAttendance(emp.id);
      final today = list.where((e) => isSameDay(e.date, date)).map((e) => e.status).toList();
      statuses[emp.id] = today;
    }
    return statuses;
  }

  Future<void> _generateMainReport(BuildContext context) async {
    final provider = context.read<EmployeeProvider>();
    await PdfService.generateEmployeeReport(provider.employees, {});
  }

  Future<void> _generateDailyReport(BuildContext context, List<Employee> employees) async {
    final provider = context.read<EmployeeProvider>();
    final Map<String, List<AttendanceEntry>> dailyStatus = {};
    
    for (var emp in employees) {
      final attendance = await provider.getAttendance(emp.id);
      dailyStatus[emp.id] = attendance.where((e) => isSameDay(e.date, _selectedDate)).toList();
    }

    await PdfService.generateAttendanceReport(_selectedDate, employees, dailyStatus);
  }

  Future<void> _markAllPresent(BuildContext context, List<Employee> employees) async {
    if (employees.isEmpty || _isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    HapticFeedback.heavyImpact();
    final provider = context.read<EmployeeProvider>();
    int count = 0;
    try {
      for (final emp in employees) {
        final list = await provider.getAttendance(emp.id);
        final existing = list.where((e) => isSameDay(e.date, _selectedDate)).firstOrNull;
        final dateStr = DateFormat('yyyyMMdd').format(_selectedDate);
        final entry = AttendanceEntry(
          id: existing?.id ?? '${emp.id}_$dateStr',
          employeeId: emp.id,
          date: _selectedDate,
          status: AttendanceStatus.present,
          checkInTime: existing?.checkInTime ?? '09:00',
          checkOutTime: existing?.checkOutTime ?? '18:00',
          amountGiven: existing?.amountGiven ?? 0.0,
          paymentDescription: existing?.paymentDescription,
        );
        await provider.markAttendance(entry);
        count++;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎉 All $count helpers marked Present for ${DateFormat('dd MMM').format(_selectedDate)}!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(milliseconds: 2000),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  void _showAddEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EmployeeFormDialog(),
    );
  }
}

class _QuickStatusButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickStatusButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_QuickStatusButton> createState() => _QuickStatusButtonState();
}

class _QuickStatusButtonState extends State<_QuickStatusButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        widget.color,
                        widget.color == const Color(0xFF10B981)
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: active
                  ? null
                  : (isDark ? widget.color.withAlpha(25) : widget.color.withAlpha(18)),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? widget.color : widget.color.withAlpha(isDark ? 80 : 70),
                width: active ? 2.0 : 1.2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: widget.color.withAlpha(90),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 18,
                color: active ? Colors.white : widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactEmployeeCard extends StatelessWidget {
  final Employee employee;
  final DateTime selectedDate;

  const _CompactEmployeeCard({required this.employee, required this.selectedDate});

  List<Color> _getAvatarGradient(String name) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Indigo
      [const Color(0xFF0EA5E9), const Color(0xFF0284C7)], // Sky
      [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Violet
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
      [const Color(0xFFEC4899), const Color(0xFFDB2777)], // Pink
    ];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<AttendanceEntry>>(
      future: context.watch<EmployeeProvider>().getAttendance(employee.id),
      builder: (context, snapshot) {
        final attendance = snapshot.data ?? [];
        final dayEntries = attendance.where((e) => isSameDay(e.date, selectedDate)).toList();

        final firstStatus = dayEntries.firstOrNull?.status;
        final sideColor = firstStatus == null 
            ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)) 
            : _getStatusColor(firstStatus);

        final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final cardBorderColor = firstStatus == AttendanceStatus.present
            ? (isDark ? const Color(0x6610B981) : const Color(0x4410B981))
            : firstStatus == AttendanceStatus.absent
                ? (isDark ? const Color(0x66EF4444) : const Color(0x44EF4444))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cardBorderColor,
              width: firstStatus != null ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(75)
                    : (firstStatus == AttendanceStatus.present
                        ? const Color(0xFF10B981).withAlpha(18)
                        : firstStatus == AttendanceStatus.absent
                            ? const Color(0xFFEF4444).withAlpha(18)
                            : Colors.black.withAlpha(9)),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 4.5,
                  color: sideColor,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _showQuickActionsBottomSheet(context, dayEntries),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'emp_avatar_${employee.id}',
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sideColor.withAlpha(isDark ? 160 : 120),
                                  width: 1.8,
                                ),
                                gradient: employee.photoPath == null
                                    ? LinearGradient(
                                        colors: _getAvatarGradient(employee.name),
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                image: employee.photoPath != null
                                    ? DecorationImage(
                                        image: FileImage(File(employee.photoPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: employee.photoPath == null
                                  ? Center(
                                      child: Text(
                                        employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  employee.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                _buildFriendlyStatusHint(context, firstStatus, colorScheme, dayEntries),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Quick 1-Tap Attendance Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Present Button (Green Check)
                      _QuickStatusButton(
                        icon: Icons.check_rounded,
                        label: 'P',
                        tooltip: 'Mark Present (आया)',
                        color: const Color(0xFF10B981),
                        isActive: firstStatus == AttendanceStatus.present,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (firstStatus == AttendanceStatus.present && dayEntries.isNotEmpty) {
                            _clearAttendance(context);
                          } else {
                            _markAttendanceStatus(context, AttendanceStatus.present, dayEntries.firstOrNull);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      // Absent Button (Red Cross)
                      _QuickStatusButton(
                        icon: Icons.close_rounded,
                        label: 'A',
                        tooltip: 'Mark Absent (छुट्टी)',
                        color: const Color(0xFFEF4444),
                        isActive: firstStatus == AttendanceStatus.absent,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (firstStatus == AttendanceStatus.absent && dayEntries.isNotEmpty) {
                            _clearAttendance(context);
                          } else {
                            _markAttendanceStatus(context, AttendanceStatus.absent, dayEntries.firstOrNull);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // More options menu
                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 19,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip: 'More options / Advance / Late',
                        onPressed: () => _showQuickActionsBottomSheet(context, dayEntries),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendlyStatusHint(
    BuildContext context,
    AttendanceStatus? status,
    ColorScheme colorScheme,
    List<AttendanceEntry> dayEntries,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget statusWidget;
    if (status == AttendanceStatus.present) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0x5510B981) : const Color(0x4410B981),
            width: 0.8,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 11),
            SizedBox(width: 3.5),
            Text(
              'Present',
              style: TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else if (status == AttendanceStatus.absent) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x28EF4444) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0x55EF4444) : const Color(0x44EF4444),
            width: 0.8,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 11),
            SizedBox(width: 3.5),
            Text(
              'Absent',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else if (status == AttendanceStatus.late) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x28F59E0B) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0x55F59E0B) : const Color(0x44F59E0B),
            width: 0.8,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, color: Color(0xFFD97706), size: 11),
            SizedBox(width: 3.5),
            Text(
              'Late',
              style: TextStyle(
                color: Color(0xFFD97706),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else if (status == AttendanceStatus.early) {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x283B82F6) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0x553B82F6) : const Color(0x443B82F6),
            width: 0.8,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF2563EB), size: 11),
            SizedBox(width: 3.5),
            Text(
              'Left Early',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else {
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x2864748B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0x4464748B) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 11),
            const SizedBox(width: 3.5),
            Text(
              'Tap to mark',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    final advanceEntry = dayEntries.where((e) => e.amountGiven > 0).firstOrNull;
    if (advanceEntry != null) {
      return Wrap(
        spacing: 4,
        runSpacing: 3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          statusWidget,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x28F59E0B) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x44F59E0B), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_rounded, color: Color(0xFFD97706), size: 10),
                const SizedBox(width: 3),
                Text(
                  '₹${advanceEntry.amountGiven.toInt()} Paid',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return statusWidget;
  }

  void _showQuickActionsBottomSheet(BuildContext context, List<AttendanceEntry> dayEntries) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Helper Header
                  Row(
                    children: [
                      Hero(
                        tag: 'bottomsheet_avatar_${employee.id}',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                            gradient: employee.photoPath == null
                                ? LinearGradient(
                                    colors: _getAvatarGradient(employee.name),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            image: employee.photoPath != null
                                ? DecorationImage(
                                    image: FileImage(File(employee.photoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: employee.photoPath == null
                              ? Center(
                                  child: Text(
                                    employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  employee.contact.isNotEmpty ? employee.contact : 'No contact added',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                          padding: const EdgeInsets.all(6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Date header badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x286366F1) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0x556366F1) : const Color(0xFFC7D2FE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available_rounded, size: 15, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 6),
                        Text(
                          'Shifts for ${DateFormat('EEE, d MMM yyyy').format(selectedDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Existing Shifts List
                  if (dayEntries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No attendance entries marked for this date.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: dayEntries.length,
                        itemBuilder: (context, idx) {
                          final entry = dayEntries[idx];
                          final color = _getStatusColor(entry.status);
                          final checkIn = entry.checkInTime ?? '--:--';
                          final checkOut = entry.checkOutTime ?? '--:--';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(isDark ? 40 : 25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: color.withAlpha(isDark ? 100 : 70)),
                                  ),
                                  child: Text(
                                    entry.status.name.toUpperCase(),
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time: $checkIn - $checkOut',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (entry.amountGiven > 0)
                                        Text(
                                          'Paid: ₹${entry.amountGiven.toInt()} (${entry.paymentDescription ?? "Advance"})',
                                          style: const TextStyle(
                                            color: Color(0xFFD97706),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      else if (entry.lateTime != null)
                                        Text('Late: ${entry.lateTime}', style: const TextStyle(fontSize: 10, color: Colors.orange))
                                      else if (entry.earlyTime != null)
                                        Text('Early: ${entry.earlyTime}', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 16),
                                      color: colorScheme.primary,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showEditAttendanceDialog(context, entry);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        _confirmDeleteAttendance(context, entry);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Mark Status for Today',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.35,
                    children: [
                      _buildQuickActionButton(
                        context,
                        label: 'PRESENT',
                        subtitle: 'आया • Full day',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.pop(context);
                          _markAttendanceStatus(context, AttendanceStatus.present, dayEntries.firstOrNull);
                        },
                      ),
                      _buildQuickActionButton(
                        context,
                        label: 'ABSENT',
                        subtitle: 'छुट्टी • Off today',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          Navigator.pop(context);
                          _markAttendanceStatus(context, AttendanceStatus.absent, dayEntries.firstOrNull);
                        },
                      ),
                      _buildQuickActionButton(
                        context,
                        label: 'LATE',
                        subtitle: 'देर से • After shift',
                        icon: Icons.timer_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(context);
                          _showTimeOffsetDialog(context, AttendanceStatus.late, dayEntries.firstOrNull);
                        },
                      ),
                      _buildQuickActionButton(
                        context,
                        label: 'EARLY',
                        subtitle: 'जल्दी • Left early',
                        icon: Icons.logout_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.pop(context);
                          _showTimeOffsetDialog(context, AttendanceStatus.early, dayEntries.firstOrNull);
                        },
                      ),
                    ],
                  ),

                  if (dayEntries.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          backgroundColor: isDark ? const Color(0x18EF4444) : const Color(0xFFFEF2F2),
                          side: BorderSide(color: const Color(0xFFEF4444).withAlpha(isDark ? 80 : 60)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAttendance(context);
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Clear Today\'s Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  _buildFullWidthActionButton(
                    context,
                    label: 'Give Pay / Advance',
                    subtitle: 'Record cash advance or wage payment directly',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFFD97706),
                    gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    onTap: () {
                      Navigator.pop(context);
                      _showDirectPaymentDialog(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildFullWidthActionButton(
                    context,
                    label: 'View Profile & Reports',
                    subtitle: 'Full calendar, financial ledger, and PDF report',
                    icon: Icons.account_circle_rounded,
                    color: const Color(0xFF6366F1),
                    gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeDetailScreen(employee: employee),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(22) : color.withAlpha(16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(isDark ? 90 : 65), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 55 : 35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withAlpha(220),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthActionButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAttendanceStatus(
    BuildContext context,
    AttendanceStatus status,
    AttendanceEntry? existing,
  ) async {
    final dateStr = DateFormat('yyyyMMdd').format(selectedDate);
    final entry = AttendanceEntry(
      id: existing?.id ?? '${employee.id}_$dateStr',
      employeeId: employee.id,
      date: selectedDate,
      status: status,
      checkInTime: status == AttendanceStatus.present ? (existing?.checkInTime ?? '09:00') : null,
      checkOutTime: status == AttendanceStatus.present ? (existing?.checkOutTime ?? '18:00') : null,
      amountGiven: existing?.amountGiven ?? 0.0,
      paymentDescription: existing?.paymentDescription,
    );
    await context.read<EmployeeProvider>().markAttendance(entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == AttendanceStatus.present ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${employee.name}: ${status == AttendanceStatus.present ? "Present (आया)" : "Absent (छुट्टी)"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: status == AttendanceStatus.present ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _clearAttendance(BuildContext context) async {
    await context.read<EmployeeProvider>().deleteDailyAttendance(employee.id, selectedDate);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.remove_circle_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attendance cleared for ${employee.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildDialogInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hintText,
    String? prefixText,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary.withAlpha(200), size: 18),
        prefixText: prefixText,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
      ),
    );
  }

  void _showTimeOffsetDialog(
    BuildContext context,
    AttendanceStatus status,
    AttendanceEntry? existing,
  ) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(
      text: status == AttendanceStatus.late
          ? (existing?.lateTime ?? '30 mins')
          : (existing?.earlyTime ?? '30 mins'),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = status == AttendanceStatus.late ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: dialogColor.withAlpha(isDark ? 30 : 20),
                          border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: dialogColor.withAlpha(isDark ? 50 : 35),
                              child: Icon(Icons.timer_rounded, color: dialogColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status == AttendanceStatus.late ? 'Late Offset' : 'Early Offset',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              style: IconButton.styleFrom(padding: const EdgeInsets.all(4), minimumSize: Size.zero),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildDialogInputField(
                          context: context,
                          controller: controller,
                          label: status == AttendanceStatus.late ? 'Late by (e.g. 30 mins)' : 'Early by (e.g. 1 hour)',
                          prefixIcon: Icons.timer_rounded,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Enter time offset' : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: dialogColor,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDlgState(() => isSaving = true);
                                      try {
                                        final entry = AttendanceEntry(
                                          id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                          employeeId: employee.id,
                                          date: selectedDate,
                                          status: status,
                                          checkInTime: '09:00',
                                          checkOutTime: '18:00',
                                          lateTime: status == AttendanceStatus.late ? controller.text.trim() : null,
                                          earlyTime: status == AttendanceStatus.early ? controller.text.trim() : null,
                                          amountGiven: existing?.amountGiven ?? 0.0,
                                          paymentDescription: existing?.paymentDescription,
                                        );
                                        await context.read<EmployeeProvider>().markAttendance(entry);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Marked ${employee.name} as ${status.name.toUpperCase()}'),
                                              backgroundColor: dialogColor,
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to save offset: $e'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setDlgState(() => isSaving = false);
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Save Offset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDirectPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    final presetAmounts = [500, 1000, 2000, 5000];
    final presetReasons = ['Advance', 'Daily Wage', 'Bonus', 'Emergency'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                              ? [const Color(0xFF78350F), const Color(0xFFB45309)] 
                              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF92400E) : const Color(0xFFFCD34D))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFD97706),
                            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Give Pay / Advance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF78350F),
                                  ),
                                ),
                                Text(
                                  'Payee: ${employee.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withAlpha(20),
                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF78350F),
                              padding: const EdgeInsets.all(4),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogInputField(
                            context: context,
                            controller: amountController,
                            label: 'Amount (₹)',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter payment amount';
                              final val = double.tryParse(value);
                              if (val == null || val <= 0) return 'Enter a valid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Preset Amount Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetAmounts.map((amt) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text('+₹$amt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onPressed: () {
                                      final current = double.tryParse(amountController.text) ?? 0;
                                      amountController.text = (current + amt).toStringAsFixed(0);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildDialogInputField(
                            context: context,
                            controller: descController,
                            label: 'Purpose / Note (Optional)',
                            prefixIcon: Icons.edit_note_rounded,
                            hintText: 'e.g. Advance, daily wage...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          // Preset Reason Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetReasons.map((reason) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(reason, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onPressed: () {
                                      descController.text = reason;
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDlgState(() => isSaving = true);
                                    try {
                                      final amount = double.parse(amountController.text);
                                      final entry = AttendanceEntry(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        employeeId: employee.id,
                                        date: selectedDate,
                                        status: AttendanceStatus.present,
                                        amountGiven: amount,
                                        paymentDescription: descController.text.trim().isNotEmpty 
                                            ? descController.text.trim() 
                                            : 'Advance',
                                      );

                                      await context.read<EmployeeProvider>().markAttendance(entry);

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                Text('₹${amount.toStringAsFixed(0)} recorded for ${employee.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF059669),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to save payment: $e'), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    } finally {
                                      setDlgState(() => isSaving = false);
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late: return Colors.orange;
      case AttendanceStatus.early: return Colors.blue;
    }
  }

  void _confirmDeleteAttendance(BuildContext context, AttendanceEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete this ${entry.status.name.toUpperCase()} attendance entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<EmployeeProvider>().deleteAttendance(employee.id, entry.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance entry deleted'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditAttendanceDialog(BuildContext context, AttendanceEntry existing) {
    final checkInController = TextEditingController(text: existing.checkInTime ?? '09:00');
    final checkOutController = TextEditingController(text: existing.checkOutTime ?? '18:00');
    final lateEarlyController = TextEditingController(text: existing.lateTime ?? existing.earlyTime ?? '');
    final amountController = TextEditingController(text: existing.amountGiven > 0 ? existing.amountGiven.toString() : '');
    final descController = TextEditingController(text: existing.paymentDescription ?? '');

    AttendanceStatus selectedStatus = existing.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          final statusColor = _getStatusColor(selectedStatus);
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                        ),
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF10B981) : const Color(0xFFA7F3D0))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF10B981),
                            child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Attendance Entry',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                                  ),
                                ),
                                Text(
                                  '${employee.name} • ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF047857),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withAlpha(20),
                              padding: const EdgeInsets.all(4),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT STATUS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: AttendanceStatus.values.map((s) {
                              final isSelected = selectedStatus == s;
                              final color = _getStatusColor(s);
                              return ChoiceChip(
                                label: Text(
                                  s.name.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: color,
                                backgroundColor: color.withAlpha(isDark ? 30 : 20),
                                side: BorderSide(
                                  color: isSelected ? color : color.withAlpha(isDark ? 80 : 60),
                                  width: 1,
                                ),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onSelected: (selected) {
                                  if (selected) {
                                    setDlgState(() => selectedStatus = s);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          if (selectedStatus != AttendanceStatus.absent) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDialogInputField(
                                    context: context,
                                    controller: checkInController,
                                    label: 'In Time',
                                    prefixIcon: Icons.login_rounded,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDialogInputField(
                                    context: context,
                                    controller: checkOutController,
                                    label: 'Out Time',
                                    prefixIcon: Icons.logout_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (selectedStatus == AttendanceStatus.late || selectedStatus == AttendanceStatus.early) ...[
                            _buildDialogInputField(
                              context: context,
                              controller: lateEarlyController,
                              label: selectedStatus == AttendanceStatus.late ? 'Late by (e.g. 30 mins)' : 'Early by (e.g. 1 hour)',
                              prefixIcon: Icons.timer_rounded,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildDialogInputField(
                            context: context,
                            controller: amountController,
                            label: 'Payment / Advance Given (₹)',
                            prefixIcon: Icons.payments_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: descController,
                            label: 'Payment Description (Optional)',
                            prefixIcon: Icons.description_rounded,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: statusColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setDlgState(() => isSaving = true);
                                    try {
                                      final amount = double.tryParse(amountController.text) ?? 0.0;
                                      final entry = AttendanceEntry(
                                        id: existing.id,
                                        employeeId: employee.id,
                                        date: selectedDate,
                                        status: selectedStatus,
                                        checkInTime: selectedStatus != AttendanceStatus.absent ? checkInController.text.trim() : null,
                                        checkOutTime: selectedStatus != AttendanceStatus.absent ? checkOutController.text.trim() : null,
                                        lateTime: selectedStatus == AttendanceStatus.late ? lateEarlyController.text.trim() : null,
                                        earlyTime: selectedStatus == AttendanceStatus.early ? lateEarlyController.text.trim() : null,
                                        amountGiven: amount,
                                        paymentDescription: descController.text.trim(),
                                      );
                                      await context.read<EmployeeProvider>().markAttendance(entry);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Attendance entry updated successfully!'), backgroundColor: Color(0xFF059669)),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    } finally {
                                      setDlgState(() => isSaving = false);
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EmployeeFormDialog extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormDialog({super.key, this.employee});

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _salaryController;
  late DateTime _joiningDate;
  String? _photoPath;
  DateTime? _relievingDate;
  late String _salaryBasis;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _contactController = TextEditingController(text: widget.employee?.contact);
    _salaryController = TextEditingController(text: widget.employee?.baseSalary.toString());
    _joiningDate = widget.employee?.joiningDate ?? DateTime.now();
    _photoPath = widget.employee?.photoPath;
    _relievingDate = widget.employee?.relievingDate;
    _salaryBasis = widget.employee?.salaryBasis ?? 'daily';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Widget _buildFormInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hintText,
    String? prefixText,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF10B981), size: 18),
        prefixText: prefixText,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.employee != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                        : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  ),
                  border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF10B981) : const Color(0xFFA7F3D0))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF10B981),
                      child: Icon(
                        isEditing ? Icons.manage_accounts_rounded : Icons.person_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Staff Profile' : 'Add New Helper / Staff',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF064E3B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withAlpha(20),
                        padding: const EdgeInsets.all(4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  setState(() {
                                    _photoPath = image.path;
                                  });
                                }
                              },
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withAlpha(100),
                                    width: 2,
                                  ),
                                  image: _photoPath != null
                                      ? DecorationImage(
                                          image: FileImage(File(_photoPath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _photoPath == null
                                    ? const Icon(Icons.add_a_photo_rounded, size: 26, color: Color(0xFF10B981))
                                    : null,
                              ),
                            ),
                            if (_photoPath != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photoPath = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFormInputField(
                        context: context,
                        controller: _nameController,
                        label: 'Full Name',
                        prefixIcon: Icons.badge_rounded,
                        hintText: 'e.g. Ramesh Kumar, Sunita Devi',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter helper name' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormInputField(
                        context: context,
                        controller: _contactController,
                        label: 'Contact Phone (Optional)',
                        prefixIcon: Icons.phone_rounded,
                        hintText: 'e.g. +91 98765 43210',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Text('Salary Basis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            const Spacer(),
                            ChoiceChip(
                              label: const Text('Daily', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: _salaryBasis == 'daily',
                              selectedColor: const Color(0xFF10B981),
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: _salaryBasis == 'daily' ? const Color(0xFF10B981) : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                              ),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              onSelected: (selected) {
                                if (selected) setState(() => _salaryBasis = 'daily');
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Monthly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: _salaryBasis == 'monthly',
                              selectedColor: const Color(0xFF10B981),
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: _salaryBasis == 'monthly' ? const Color(0xFF10B981) : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                              ),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              onSelected: (selected) {
                                if (selected) setState(() => _salaryBasis = 'monthly');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFormInputField(
                        context: context,
                        controller: _salaryController,
                        label: _salaryBasis == 'daily' ? 'Daily Wage (₹)' : 'Monthly Base Salary (₹)',
                        prefixIcon: Icons.payments_rounded,
                        prefixText: '₹ ',
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Enter valid amount' : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Text('Joining Date', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMMM yyyy').format(_joiningDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          leading: const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF10B981)),
                          trailing: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF10B981)),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _joiningDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) setState(() => _joiningDate = date);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Text('Relieving Date (Optional)', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            _relievingDate == null
                                ? 'Currently Employed / Active'
                                : DateFormat('dd MMMM yyyy').format(_relievingDate!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _relievingDate == null ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          leading: Icon(Icons.event_busy_rounded, size: 20, color: _relievingDate == null ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)) : const Color(0xFFEF4444)),
                          trailing: _relievingDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFFEF4444)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => _relievingDate = null),
                                )
                              : const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF10B981)),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _relievingDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) setState(() => _relievingDate = date);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isSaving = true);
                                final employee = Employee(
                                  id: isEditing ? widget.employee!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: _nameController.text.trim(),
                                  contact: _contactController.text.trim(),
                                  joiningDate: _joiningDate,
                                  baseSalary: double.parse(_salaryController.text),
                                  salaryBasis: _salaryBasis,
                                  photoPath: _photoPath,
                                  relievingDate: _relievingDate,
                                );
                                try {
                                  if (isEditing) {
                                    await context.read<EmployeeProvider>().updateEmployee(employee);
                                  } else {
                                    await context.read<EmployeeProvider>().addEmployee(employee);
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEditing
                                            ? 'Employee "${employee.name}" updated!'
                                            : 'Employee "${employee.name}" added!'),
                                        backgroundColor: const Color(0xFF059669),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to save employee: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Add Helper', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}