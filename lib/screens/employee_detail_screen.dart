import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/employee_provider.dart';
import '../models/employee_model.dart';
import 'employee_management_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:${widget.employee.contact}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
  }

  Future<void> _sendSMS() async {
    final Uri url = Uri.parse('sms:${widget.employee.contact}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: _buildHeaderBackground(colorScheme),
                title: Text(
                  widget.employee.name,
                  style: TextStyle(
                    color: innerBoxIsScrolled ? colorScheme.onSurface : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  onPressed: () => _showEditOptions(context),
                  icon: const Icon(Icons.more_vert_rounded),
                  color: innerBoxIsScrolled ? colorScheme.onSurface : Colors.white,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildQuickActions(colorScheme),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(icon: Icon(Icons.fact_check_rounded), text: 'Attendance'),
                    Tab(icon: Icon(Icons.payments_rounded), text: 'Payments'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _EmployeeAttendanceTab(employee: widget.employee),
            _EmployeePaymentsTab(employee: widget.employee),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(150),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'emp_avatar_${widget.employee.id}',
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: widget.employee.photoPath != null 
                      ? FileImage(File(widget.employee.photoPath!)) 
                      : null,
                  child: widget.employee.photoPath == null
                      ? Text(
                          widget.employee.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.employee.contact,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Joined: ${DateFormat('dd MMM yyyy').format(widget.employee.joiningDate)}'
              '${widget.employee.relievingDate != null ? '  •  Relieved: ${DateFormat('dd MMM yyyy').format(widget.employee.relievingDate!)}' : ''}',
              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.call_rounded,
            label: 'Call',
            onTap: _makeCall,
          ),
          _ActionButton(
            icon: Icons.message_rounded,
            label: 'SMS',
            onTap: _sendSMS,
          ),
          _ActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onTap: () => _showEditDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(employee: widget.employee),
    );
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: const Text('Delete Employee', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: Text('Are you sure you want to remove ${widget.employee.name} and all their history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<EmployeeProvider>().deleteEmployee(widget.employee.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to management
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _EmployeeAttendanceTab extends StatefulWidget {
  final Employee employee;
  const _EmployeeAttendanceTab({required this.employee});

  @override
  State<_EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<_EmployeeAttendanceTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<AttendanceEntry>>(
      future: context.watch<EmployeeProvider>().getAttendance(widget.employee.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        
        final Map<DateTime, AttendanceEntry> entryMap = {
          for (var e in entries) 
            DateTime(e.date.year, e.date.month, e.date.day): e
        };

        final selectedEntry = entryMap[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)];

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              eventLoader: (day) {
                final entry = entryMap[DateTime(day.year, day.month, day.day)];
                return entry != null ? [entry] : [];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  final entry = events.first as AttendanceEntry;
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _getStatusColor(entry.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (entry.amountGiven > 0) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.currency_rupee_rounded, size: 10, color: Colors.amber),
                        ],
                      ],
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  final entry = entryMap[DateTime(day.year, day.month, day.day)];
                  if (entry != null) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.status).withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(entry.status).withAlpha(100)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text('${day.day}', style: TextStyle(color: _getStatusColor(entry.status), fontWeight: FontWeight.bold)),
                          if (entry.amountGiven > 0)
                            const Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(Icons.star_rounded, size: 8, color: Colors.amber),
                            ),
                        ],
                      ),
                    );
                  }
                  return null;
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (selectedEntry != null)
                        _getStatusBadge(selectedEntry.status, colorScheme)
                      else
                        const Text('No entry', style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedEntry != null) ...[
                    _buildDetailRow(Icons.access_time_rounded, 'In Time', selectedEntry.checkInTime ?? '--:--', colorScheme),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.logout_rounded, 'Out Time', selectedEntry.checkOutTime ?? '--:--', colorScheme),
                    if (selectedEntry.status == AttendanceStatus.late) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.timer_rounded, 'Late by', selectedEntry.lateTime ?? '--', Colors.orange),
                    ],
                    if (selectedEntry.status == AttendanceStatus.early) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.timer_rounded, 'Early by', selectedEntry.earlyTime ?? '--', Colors.blue),
                    ],
                    if (selectedEntry.amountGiven > 0) ...[
                      const Divider(height: 24),
                      _buildDetailRow(Icons.payments_rounded, 'Money Given', '₹${selectedEntry.amountGiven}', Colors.amber),
                      if (selectedEntry.paymentDescription != null && selectedEntry.paymentDescription!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 32, top: 4),
                          child: Text(
                            selectedEntry.paymentDescription!,
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _showAttendanceDetailsDialog(
                        context, 
                        selectedEntry?.status ?? AttendanceStatus.present, 
                        selectedEntry ?? AttendanceEntry(id: '', employeeId: widget.employee.id, date: _selectedDay, status: AttendanceStatus.present)
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 24),
                      label: Text(
                        selectedEntry == null ? 'Mark Attendance' : 'Update Attendance',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

  Widget _getStatusBadge(AttendanceStatus status, ColorScheme colorScheme) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, dynamic color) {
    final useColor = color is Color ? color : (color as ColorScheme).onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: useColor.withAlpha(200)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _showAttendanceDetailsDialog(BuildContext context, AttendanceStatus initialStatus, AttendanceEntry existing) {
    final checkInController = TextEditingController(text: existing.checkInTime ?? '09:00');
    final checkOutController = TextEditingController(text: existing.checkOutTime ?? '18:00');
    final lateEarlyController = TextEditingController(text: existing.lateTime ?? existing.earlyTime ?? '');

    AttendanceStatus selectedStatus = initialStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('Mark Attendance', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  if (selectedStatus == AttendanceStatus.late || selectedStatus == AttendanceStatus.early)
                    TextField(
                      controller: lateEarlyController,
                      decoration: InputDecoration(
                        labelText: selectedStatus == AttendanceStatus.late ? 'Late by (time/mins)' : 'Early by (time/mins)',
                        prefixIcon: const Icon(Icons.timer_rounded),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final entry = AttendanceEntry(
                    id: existing.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : existing.id,
                    employeeId: widget.employee.id,
                    date: _selectedDay,
                    status: selectedStatus,
                    checkInTime: selectedStatus != AttendanceStatus.absent ? checkInController.text : null,
                    checkOutTime: selectedStatus != AttendanceStatus.absent ? checkOutController.text : null,
                    lateTime: selectedStatus == AttendanceStatus.late ? lateEarlyController.text : null,
                    earlyTime: selectedStatus == AttendanceStatus.early ? lateEarlyController.text : null,
                    amountGiven: existing.amountGiven,
                    paymentDescription: existing.paymentDescription,
                  );
                  context.read<EmployeeProvider>().markAttendance(entry);
                  Navigator.pop(context);
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

class _EmployeePaymentsTab extends StatelessWidget {
  final Employee employee;
  const _EmployeePaymentsTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceEntry>>(
      future: context.watch<EmployeeProvider>().getAttendance(employee.id),
      builder: (context, snapshot) {
        final entries = snapshot.data?.where((e) => e.amountGiven > 0).toList() ?? [];
        final totalGiven = entries.fold(0.0, (sum, e) => sum + e.amountGiven);

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Total Money Given (Advances)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalGiven.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            if (entries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No payments recorded yet.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
                ),
              )
            else
              ...entries.map((entry) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 1,
                shadowColor: Colors.black.withAlpha(15),
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100), width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                    child: Icon(Icons.currency_rupee_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  title: Text(
                    '₹${entry.amountGiven.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${entry.date.day}/${entry.date.month}/${entry.date.year}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (entry.paymentDescription != null && entry.paymentDescription!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.paymentDescription!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _showAddPaymentDialog(context),
                  icon: const Icon(Icons.add_card_rounded, size: 24),
                  label: const Text(
                    'Give Money / Advance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Column(
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('Give Advance', textAlign: TextAlign.center),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount', 
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)', 
                    prefixIcon: Icon(Icons.description_rounded),
                    hintText: 'e.g. For festival, emergency...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18),
                        const SizedBox(width: 12),
                        Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                
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
                      content: Text('₹$amount added to ${employee.name}\'s account'),
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
    );
  }
}
