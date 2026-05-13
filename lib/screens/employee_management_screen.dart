import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
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
          SliverAppBar.medium(
            title: const Text('Employees', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                onPressed: () => _generateMainReport(context),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Generate Report',
              ),
              IconButton(
                onPressed: () => _showAddEmployeeDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildSearchAndCalendar(colorScheme),
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

  Widget _buildSearchAndCalendar(ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

  Future<void> _generateMainReport(BuildContext context) async {
    final provider = context.read<EmployeeProvider>();
    await PdfService.generateEmployeeReport(provider.employees, {});
  }

  Future<void> _generateDailyReport(BuildContext context, List<Employee> employees) async {
    final provider = context.read<EmployeeProvider>();
    final Map<String, AttendanceEntry?> dailyStatus = {};
    
    for (var emp in employees) {
      final attendance = await provider.getAttendance(emp.id);
      dailyStatus[emp.id] = attendance.where((e) => isSameDay(e.date, _selectedDate)).firstOrNull;
    }

    await PdfService.generateAttendanceReport(_selectedDate, employees, dailyStatus);
  }
`
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
        final statusEntry = attendance.where((e) => isSameDay(e.date, selectedDate)).firstOrNull;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employee: employee)),
            ),
            leading: Hero(
              tag: 'emp_avatar_${employee.id}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: employee.photoPath != null ? FileImage(File(employee.photoPath!)) : null,
                child: employee.photoPath == null ? Text(employee.name[0].toUpperCase()) : null,
              ),
            ),
            title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(employee.contact, style: const TextStyle(fontSize: 11)),
            trailing: _buildStatusBadge(statusEntry, colorScheme),
          ),
        );
      },
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
}

class EmployeeFormDialog extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormDialog({this.employee});

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _salaryController;
  late DateTime _joiningDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _contactController = TextEditingController(text: widget.employee?.contact);
    _salaryController = TextEditingController(text: widget.employee?.baseSalary.toString());
    _joiningDate = widget.employee?.joiningDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.employee != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Column(
        children: [
          Icon(
            isEditing ? Icons.person_search_rounded : Icons.person_add_rounded,
            size: 40,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(isEditing ? 'Edit Profile' : 'New Employee', textAlign: TextAlign.center),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_rounded)),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact', prefixIcon: Icon(Icons.phone_rounded)),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.length < 10 ? 'Invalid contact' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(labelText: 'Daily Salary', prefixIcon: Icon(Icons.payments_rounded), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid amount' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Joining Date', style: TextStyle(fontSize: 12)),
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final employee = Employee(
                id: isEditing ? widget.employee!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                contact: _contactController.text.trim(),
                joiningDate: _joiningDate,
                baseSalary: double.parse(_salaryController.text),
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
    );
  }
}