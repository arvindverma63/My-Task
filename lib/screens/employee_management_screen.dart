import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final employees = context.watch<EmployeeProvider>().employees.where((e) {
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             e.contact.contains(_searchQuery);
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x1E10B981), // Emerald green 12% alpha
                      Color(0x0A10B981), // Emerald green 4% alpha
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x3310B981), width: 1.5), // 20% alpha border
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_ind_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Attendance Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x2210B981),
                            foregroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                          tooltip: 'Generate PDF Report',
                          onPressed: () => _generateMainReport(context),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.person_add_rounded, size: 20),
                          tooltip: 'Add Employee',
                          onPressed: () => _showAddEmployeeDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSearchAndCalendar(colorScheme, employees),
          ),
          employees.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('No employees found')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateDailyReport(context, employees),
        icon: const Icon(Icons.description_rounded),
        label: const Text('Daily Report'),
      ),
    );
  }

  Widget _buildSearchAndCalendar(ColorScheme colorScheme, List<Employee> employees) {
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  const SizedBox(width: 12),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name or contact...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    })
                  : null,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(150),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(100),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
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
              selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: colorScheme.primary.withAlpha(100), shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
              cellMargin: const EdgeInsets.all(2),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              formatButtonPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            rowHeight: 48,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Text(
                'Attendance for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const Spacer(),
              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

  void _showAddEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EmployeeFormDialog(),
    );
  }
}

class _CompactEmployeeCard extends StatelessWidget {
  final Employee employee;
  final DateTime selectedDate;

  const _CompactEmployeeCard({required this.employee, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<AttendanceEntry>>(
      future: context.watch<EmployeeProvider>().getAttendance(employee.id),
      builder: (context, snapshot) {
        final attendance = snapshot.data ?? [];
        final dayEntries = attendance.where((e) => isSameDay(e.date, selectedDate)).toList();

        final firstStatus = dayEntries.firstOrNull?.status;
        final sideColor = firstStatus == null 
            ? colorScheme.outlineVariant.withAlpha(100) 
            : _getStatusColor(firstStatus);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 80,
                color: sideColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _showQuickActionsBottomSheet(context, dayEntries),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'emp_avatar_${employee.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sideColor.withAlpha(100),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: colorScheme.primaryContainer,
                              backgroundImage: employee.photoPath != null ? FileImage(File(employee.photoPath!)) : null,
                              child: employee.photoPath == null
                                  ? Text(
                                      employee.name[0].toUpperCase(),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer, fontSize: 18),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              employee.contact.trim().isNotEmpty
                                  ? Row(
                                      children: [
                                        Icon(Icons.phone_rounded, size: 12, color: colorScheme.onSurfaceVariant.withAlpha(180)),
                                        const SizedBox(width: 4),
                                        Text(
                                          employee.contact,
                                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withAlpha(180)),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'No contact number',
                                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant.withAlpha(120)),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: dayEntries.isEmpty
                              ? _buildStatusBadge(null, colorScheme)
                              : Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: dayEntries.map((e) => _buildStatusBadge(e, colorScheme)).toList(),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurfaceVariant.withAlpha(120)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActionsBottomSheet(BuildContext context, List<AttendanceEntry> dayEntries) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withAlpha(120),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: employee.photoPath != null ? FileImage(File(employee.photoPath!)) : null,
                      child: employee.photoPath == null
                          ? Text(
                              employee.name[0].toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer, fontSize: 16),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.contact,
                            style: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(180), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(120),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Attendance Shifts for ${DateFormat('EEEE, d MMMM yyyy').format(selectedDate)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                // Existing Shifts List
                if (dayEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No attendance entries marked for today.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(160), fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: dayEntries.length,
                      itemBuilder: (context, idx) {
                        final entry = dayEntries[idx];
                        final color = _getStatusColor(entry.status);
                        final checkIn = entry.checkInTime ?? '--:--';
                        final checkOut = entry.checkOutTime ?? '--:--';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withAlpha(80)),
                              ),
                              child: Text(
                                entry.status.name.toUpperCase(),
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              'Time: $checkIn - $checkOut',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            subtitle: entry.amountGiven > 0 
                                ? Text(
                                    'Payment: ₹${entry.amountGiven} (${entry.paymentDescription ?? "Advance"})',
                                    style: TextStyle(color: Colors.amber[800], fontSize: 10, fontWeight: FontWeight.w600),
                                  )
                                : (entry.lateTime != null ? Text('Late: ${entry.lateTime}', style: const TextStyle(fontSize: 10)) : 
                                   entry.earlyTime != null ? Text('Early: ${entry.earlyTime}', style: const TextStyle(fontSize: 10)) : null),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 16),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditAttendanceDialog(context, entry);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                                  onPressed: () {
                                    _confirmDeleteAttendance(context, entry);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Mark New Attendance/Shift',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildQuickActionButton(
                      context,
                      label: 'PRESENT',
                      subtitle: 'At work',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _markAttendanceStatus(context, AttendanceStatus.present, null);
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      label: 'ABSENT',
                      subtitle: 'No show',
                      icon: Icons.cancel_rounded,
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _markAttendanceStatus(context, AttendanceStatus.absent, null);
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      label: 'LATE',
                      subtitle: 'Came late',
                      icon: Icons.timer_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _showTimeOffsetDialog(context, AttendanceStatus.late, null);
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      label: 'EARLY',
                      subtitle: 'Left early',
                      icon: Icons.logout_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _showTimeOffsetDialog(context, AttendanceStatus.early, null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFullWidthActionButton(
                  context,
                  label: 'Give Pay / Advance',
                  subtitle: 'Record payments directly',
                  icon: Icons.payments_rounded,
                  color: Colors.amber[800]!,
                  onTap: () {
                    Navigator.pop(context);
                    _showDirectPaymentDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildFullWidthActionButton(
                  context,
                  label: 'View Profile & Reports',
                  subtitle: 'Full calendar, payments, and print reports',
                  icon: Icons.account_circle_rounded,
                  color: colorScheme.secondary,
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
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withAlpha(160),
                      fontSize: 10,
                    ),
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
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(60), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withAlpha(160),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant.withAlpha(150)),
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
    final entry = AttendanceEntry(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: employee.id,
      date: selectedDate,
      status: status,
      checkInTime: status == AttendanceStatus.present ? '09:00' : null,
      checkOutTime: status == AttendanceStatus.present ? '18:00' : null,
      amountGiven: existing?.amountGiven ?? 0.0,
      paymentDescription: existing?.paymentDescription,
    );
    await context.read<EmployeeProvider>().markAttendance(entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked ${employee.name} as ${status.name.toUpperCase()}'),
          backgroundColor: status == AttendanceStatus.present ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary.withAlpha(200)),
        prefixText: prefixText,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(50),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
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
    final colorScheme = Theme.of(context).colorScheme;
    final dialogColor = status == AttendanceStatus.late ? Colors.orange : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dialogColor.withAlpha(20),
                      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: dialogColor.withAlpha(30),
                          child: Icon(Icons.timer_rounded, color: dialogColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status == AttendanceStatus.late ? 'Late Offset' : 'Early Offset',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildDialogInputField(
                      context: context,
                      controller: controller,
                      label: status == AttendanceStatus.late ? 'Late by (e.g. 30 mins)' : 'Early by (e.g. 1 hour)',
                      prefixIcon: Icons.timer_rounded,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter time offset' : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
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
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: const Text('Save Offset'),
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
    );
  }

  void _showDirectPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(20),
                      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.amber.withAlpha(30),
                          child: Icon(Icons.payments_rounded, color: Colors.amber[800], size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Give Pay to ${employee.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDialogInputField(
                          context: context,
                          controller: amountController,
                          label: 'Amount (₹)',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Enter amount';
                            final val = double.tryParse(value);
                            if (val == null || val <= 0) return 'Enter a valid positive amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDialogInputField(
                          context: context,
                          controller: descController,
                          label: 'Description (Optional)',
                          prefixIcon: Icons.description_rounded,
                          hintText: 'e.g. Advance, daily wage...',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final amount = double.parse(amountController.text);
                            final entry = AttendanceEntry(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              employeeId: employee.id,
                              date: selectedDate,
                              status: AttendanceStatus.present,
                              amountGiven: amount,
                              paymentDescription: descController.text.trim(),
                            );

                            await context.read<EmployeeProvider>().markAttendance(entry);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('₹$amount paid to ${employee.name}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text('Confirm Payment'),
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
    );
  }

  Widget _buildStatusBadge(AttendanceEntry? entry, ColorScheme colorScheme) {
    if (entry == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('N/A', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      );
    }

    final color = _getStatusColor(entry.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.status.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          if (entry.amountGiven > 0) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
          ],
        ],
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('Edit Attendance Entry', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: AttendanceStatus.values.map((s) {
                      final isSelected = selectedStatus == s;
                      final color = _getStatusColor(s);
                      return ChoiceChip(
                        label: Text(
                          s.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        backgroundColor: color.withAlpha(20),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedStatus = s;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (selectedStatus != AttendanceStatus.absent) ...[
                    TextField(
                      controller: checkInController,
                      decoration: const InputDecoration(labelText: 'In Time', prefixIcon: Icon(Icons.login_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: checkOutController,
                      decoration: const InputDecoration(labelText: 'Out Time', prefixIcon: Icon(Icons.logout_rounded)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (selectedStatus == AttendanceStatus.late || selectedStatus == AttendanceStatus.early) ...[
                    TextField(
                      controller: lateEarlyController,
                      decoration: InputDecoration(
                        labelText: selectedStatus == AttendanceStatus.late ? 'Late by (time/mins)' : 'Early by (time/mins)',
                        prefixIcon: const Icon(Icons.timer_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Payment / Advance (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
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
                      const SnackBar(content: Text('Attendance entry updated'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary.withAlpha(200)),
        prefixText: prefixText,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(50),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.employee != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary.withAlpha(30),
                      child: Icon(
                        isEditing ? Icons.person_search_rounded : Icons.person_add_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Profile' : 'New Employee',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                          child: _photoPath == null
                              ? Icon(Icons.add_a_photo_rounded, size: 28, color: colorScheme.onPrimaryContainer)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormInputField(
                        context: context,
                        controller: _nameController,
                        label: 'Full Name',
                        prefixIcon: Icons.badge_rounded,
                        validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormInputField(
                        context: context,
                        controller: _contactController,
                        label: 'Contact Phone (Optional)',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: null, // Optional, can be any length or empty
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 20),
                          const SizedBox(width: 12),
                          const Text('Salary Basis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          ChoiceChip(
                            label: const Text('DAILY'),
                            selected: _salaryBasis == 'daily',
                            onSelected: (selected) {
                              if (selected) setState(() => _salaryBasis = 'daily');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('30 DAYS'),
                            selected: _salaryBasis == 'monthly',
                            onSelected: (selected) {
                              if (selected) setState(() => _salaryBasis = 'monthly');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFormInputField(
                        context: context,
                        controller: _salaryController,
                        label: _salaryBasis == 'daily' ? 'Daily Salary / Wage' : 'Monthly Salary (30 Days)',
                        prefixIcon: Icons.payments_rounded,
                        prefixText: '₹ ',
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid amount' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
                        ),
                        title: const Text('Joining Date', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        subtitle: Text('${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        leading: const Icon(Icons.calendar_month_rounded),
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
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
                        ),
                        title: const Text('Relieving Date (Optional)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _relievingDate == null
                              ? 'Not relieved yet'
                              : '${_relievingDate!.day}/${_relievingDate!.month}/${_relievingDate!.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _relievingDate == null ? colorScheme.onSurfaceVariant : Colors.red,
                          ),
                        ),
                        leading: const Icon(Icons.calendar_today_rounded),
                        trailing: _relievingDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () => setState(() => _relievingDate = null),
                              )
                            : null,
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
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
                          if (isEditing) {
                            context.read<EmployeeProvider>().updateEmployee(employee);
                          } else {
                            context.read<EmployeeProvider>().addEmployee(employee);
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(isEditing ? 'Update' : 'Create'),
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