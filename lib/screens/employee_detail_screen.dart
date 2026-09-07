import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<Color> _getAvatarGradient(String name) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    ];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return palettes[hash % palettes.length];
  }

  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:${widget.employee.contact}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              elevation: innerBoxIsScrolled ? 2 : 0,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5),
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _buildHeaderBackground(isDark),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditDialog(context);
                    } else if (val == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                          const SizedBox(width: 10),
                          const Text('Edit Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 10),
                          Text('Delete Employee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildQuickActionsBar(isDark),
            ),
            if (context.watch<EmployeeProvider>().isLoading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E7FF),
                        width: 1,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: isDark ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withAlpha(80),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Attendance & Shifts'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Ledger & Payments'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildHeaderBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF1E293B)]
              : [const Color(0xFF4338CA), const Color(0xFF4F46E5), const Color(0xFF6366F1)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'emp_avatar_${widget.employee.id}',
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    gradient: widget.employee.photoPath == null
                        ? LinearGradient(
                            colors: _getAvatarGradient(widget.employee.name),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: widget.employee.photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(widget.employee.photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.employee.photoPath == null
                      ? Center(
                          child: Text(
                            widget.employee.name.isNotEmpty ? widget.employee.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.employee.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Salary and Basis Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(60), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee_rounded, size: 12, color: Color(0xFFFDE047)),
                        Text(
                          '${widget.employee.baseSalary.toStringAsFixed(0)} / ${widget.employee.salaryBasis}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (widget.employee.contact.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(50), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded, size: 11, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            widget.employee.contact,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Joined ${DateFormat('dd MMM yyyy').format(widget.employee.joiningDate)}'
                '${widget.employee.relievingDate != null ? '  •  Relieved ${DateFormat('dd MMM yyyy').format(widget.employee.relievingDate!)}' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar(bool isDark) {
    final hasContact = widget.employee.contact.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.call_rounded,
            label: 'Call',
            color: const Color(0xFF10B981),
            gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
            onTap: hasContact ? _makeCall : null,
          ),
          _ActionButton(
            icon: Icons.sms_rounded,
            label: 'SMS',
            color: const Color(0xFF3B82F6),
            gradient: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            onTap: hasContact ? _sendSMS : null,
          ),
          _ActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: const Color(0xFFF59E0B),
            gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: 'Employee: ${widget.employee.name}\nContact: ${widget.employee.contact}\nSalary: ₹${widget.employee.baseSalary}/${widget.employee.salaryBasis}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Employee details copied to clipboard'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
          ),
          _ActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit Info',
            color: const Color(0xFF8B5CF6),
            gradient: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
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

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Employee?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Are you sure you want to remove ${widget.employee.name} and all associated attendance & payment records?',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context.read<EmployeeProvider>().deleteEmployee(widget.employee.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEnabled ? null : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: color.withAlpha(isDark ? 80 : 60),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isEnabled ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? (isDark ? Colors.white70 : const Color(0xFF334155))
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._widget);
  final Widget _widget;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _widget;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
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

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981);
      case AttendanceStatus.absent:
        return const Color(0xFFEF4444);
      case AttendanceStatus.late:
        return const Color(0xFFF59E0B);
      case AttendanceStatus.early:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<AttendanceEntry>>(
      future: context.watch<EmployeeProvider>().getAttendance(widget.employee.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];

        final Map<DateTime, List<AttendanceEntry>> entryMap = {};
        for (var e in entries) {
          final dateKey = DateTime(e.date.year, e.date.month, e.date.day);
          entryMap.putIfAbsent(dateKey, () => []).add(e);
        }

        final selectedEntries = entryMap[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ?? [];

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Calendar Card
            Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
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
                  return entryMap[DateTime(day.year, day.month, day.day)] ?? [];
                },
                rowHeight: 36,
                daysOfWeekHeight: 22,
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withAlpha(80),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                    shape: BoxShape.rectangle,
                  ),
                  defaultDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                  weekendDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                  holidayDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                  outsideDecoration: const BoxDecoration(shape: BoxShape.rectangle),
                  cellMargin: const EdgeInsets.all(2),
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 12),
                  weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                  todayTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 12),
                  selectedTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  formatButtonDecoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
                    border: Border.all(color: const Color(0xFF4F46E5).withAlpha(120), width: 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 10),
                  formatButtonPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF4F46E5), size: 20),
                  rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF4F46E5), size: 20),
                  headerPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10.5),
                  weekendStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10.5),
                  dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0].toUpperCase(),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final dayEvents = events.cast<AttendanceEntry>();
                    final hasPayment = dayEvents.any((e) => e.amountGiven > 0);

                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...dayEvents.map((entry) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 4.5,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(entry.status),
                                  shape: BoxShape.circle,
                                ),
                              )),
                          if (hasPayment) ...[
                            const SizedBox(width: 1),
                            const Icon(Icons.payments_rounded, size: 7, color: Color(0xFFD97706)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Shifts Header & List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_selectedDay),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: selectedEntries.isNotEmpty
                              ? (isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5))
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedEntries.isNotEmpty ? '${selectedEntries.length} record(s)' : 'No records',
                          style: TextStyle(
                            color: selectedEntries.isNotEmpty ? const Color(0xFF059669) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedEntries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_rounded, size: 28, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          const SizedBox(height: 6),
                          Text(
                            'No shift recorded for this date',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...selectedEntries.map((selectedEntry) {
                      final statusColor = _getStatusColor(selectedEntry.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: statusColor.withAlpha(isDark ? 80 : 50), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 25 : 5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(isDark ? 40 : 25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withAlpha(isDark ? 100 : 70)),
                                  ),
                                  child: Text(
                                    selectedEntry.status.name.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.edit_rounded, size: 17, color: Color(0xFF4F46E5)),
                                      onPressed: () => _showAttendanceDetailsDialog(
                                        context,
                                        selectedEntry.status,
                                        selectedEntry,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                                      onPressed: () => _confirmDeleteAttendance(context, selectedEntry),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.login_rounded, 'Check In', selectedEntry.checkInTime ?? '--:--', isDark),
                            _buildDetailRow(Icons.logout_rounded, 'Check Out', selectedEntry.checkOutTime ?? '--:--', isDark),
                            if (selectedEntry.status == AttendanceStatus.late && selectedEntry.lateTime != null)
                              _buildDetailRow(Icons.timer_rounded, 'Late by', selectedEntry.lateTime!, isDark, const Color(0xFFD97706)),
                            if (selectedEntry.status == AttendanceStatus.early && selectedEntry.earlyTime != null)
                              _buildDetailRow(Icons.timer_rounded, 'Left early by', selectedEntry.earlyTime!, isDark, const Color(0xFF2563EB)),
                            if (selectedEntry.amountGiven > 0) ...[
                              Divider(height: 12, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              _buildDetailRow(
                                Icons.payments_rounded,
                                'Payment Paid',
                                '₹${selectedEntry.amountGiven.toStringAsFixed(0)} (${selectedEntry.paymentDescription ?? "Advance"})',
                                isDark,
                                const Color(0xFFD97706),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAttendanceDetailsDialog(
                        context,
                        AttendanceStatus.present,
                        AttendanceEntry(
                          id: '',
                          employeeId: widget.employee.id,
                          date: _selectedDay,
                          status: AttendanceStatus.present,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Record Shift for This Date',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAttendance(BuildContext context, AttendanceEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this ${entry.status.name.toUpperCase()} shift entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await context.read<EmployeeProvider>().deleteAttendance(widget.employee.id, entry.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance entry deleted'), backgroundColor: Color(0xFFDC2626)),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetailsDialog(BuildContext context, AttendanceStatus initialStatus, AttendanceEntry existing) {
    final checkInController = TextEditingController(text: existing.checkInTime ?? '09:00');
    final checkOutController = TextEditingController(text: existing.checkOutTime ?? '18:00');
    final lateEarlyController = TextEditingController(text: existing.lateTime ?? existing.earlyTime ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AttendanceStatus selectedStatus = initialStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_calendar_rounded, color: Color(0xFF4F46E5), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mark Attendance (${DateFormat('d MMM').format(_selectedDay)})',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Select Status:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                              fontSize: 10,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: color.withAlpha(isDark ? 40 : 20),
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              setDlgState(() => selectedStatus = s);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    if (selectedStatus != AttendanceStatus.absent) ...[
                      TextFormField(
                        controller: checkInController,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: 'Check In Time',
                          prefixIcon: const Icon(Icons.login_rounded, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: checkOutController,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: 'Check Out Time',
                          prefixIcon: const Icon(Icons.logout_rounded, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (selectedStatus == AttendanceStatus.late || selectedStatus == AttendanceStatus.early)
                      TextFormField(
                        controller: lateEarlyController,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: selectedStatus == AttendanceStatus.late ? 'Late by (e.g. 30 mins)' : 'Early by (e.g. 1 hour)',
                          prefixIcon: const Icon(Icons.timer_rounded, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final entry = AttendanceEntry(
                              id: existing.id.isEmpty
                                  ? '${widget.employee.id}_${DateFormat('yyyyMMdd').format(_selectedDay)}'
                                  : existing.id,
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
                          child: const Text('Save Shift'),
                        ),
                      ],
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

class _EmployeePaymentsTab extends StatelessWidget {
  final Employee employee;
  const _EmployeePaymentsTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<AttendanceEntry>>(
      future: context.watch<EmployeeProvider>().getAttendance(employee.id),
      builder: (context, snapshot) {
        final allEntries = snapshot.data ?? [];
        final entries = allEntries.where((e) => e.amountGiven > 0).toList();
        final totalPaid = entries.fold(0.0, (sum, e) => sum + e.amountGiven);

        final wageRate = employee.salaryBasis == 'monthly'
            ? (employee.baseSalary / 30.0)
            : employee.baseSalary;
        final workingDays = allEntries.where((e) => e.status != AttendanceStatus.absent).length;
        final totalEarned = workingDays * wageRate;
        final balance = totalEarned - totalPaid;

        final paidPercentage = totalEarned > 0 ? (totalPaid / totalEarned).clamp(0.0, 1.0) : 0.0;

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Executive Financial Summary Card
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 8),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withAlpha(isDark ? 40 : 25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.analytics_rounded, color: Color(0xFF4F46E5), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Financial Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withAlpha(isDark ? 30 : 15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          employee.salaryBasis.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Total Earned
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL EARNED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₹${totalEarned.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '$workingDays days worked',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      // Total Paid
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PAID',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₹${totalPaid.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              Text(
                                '${entries.length} payments',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      // Balance
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BALANCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₹${balance.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                              Text(
                                balance >= 0 ? 'Due to helper' : 'Advance surplus',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: balance >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payout Progress',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          Text(
                            '${(paidPercentage * 100).toStringAsFixed(0)}% settled',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: paidPercentage,
                          minHeight: 6,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payments Ledger History Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Transactions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (entries.isNotEmpty)
                    Text(
                      '${entries.length} entries',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),

            if (entries.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 36, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      const SizedBox(height: 8),
                      Text(
                        'No payment entries recorded yet.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the button below to give pay or advance.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...entries.map((entry) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 25 : 5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withAlpha(60),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '₹${entry.amountGiven.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.paymentDescription ?? 'Advance',
                                      style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat('EEEE, d MMM yyyy').format(entry.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () {
                            _confirmDeletePayment(context, entry);
                          },
                        ),
                      ],
                    ),
                  )),

            // Add Payment Pinned Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () => _showAddPaymentDialog(context),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text(
                    'Give Money / Record Advance',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePayment(BuildContext context, AttendanceEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Payment Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this ₹${entry.amountGiven.toStringAsFixed(0)} payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              // Update entry to set amountGiven to 0 or delete if it's only a payment entry
              await context.read<EmployeeProvider>().deleteAttendance(employee.id, entry.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment record removed'), backgroundColor: Color(0xFFDC2626)),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime selectedDate = DateTime.now();
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
                                  'Record Payment / Advance',
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
                          TextFormField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter payment amount';
                              final val = double.tryParse(value);
                              if (val == null || val <= 0) return 'Enter a valid amount';
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Amount (₹)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descController,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              labelText: 'Purpose / Note',
                              prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                              hintText: 'e.g. Advance, Wage...',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
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
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setDlgState(() => selectedDate = date);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Date: ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                ],
                              ),
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
}
