import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/employee_model.dart';
import '../providers/employee_provider.dart';
import '../services/pdf_service.dart';
import 'employee_detail_screen.dart';

enum ReportPeriod { today, thisWeek, thisMonth, lastMonth, custom }

enum ReportStatusFilter { all, present, absent, withPayment }

class EmployeeReportScreen extends StatefulWidget {
  final Employee? initialEmployee;

  const EmployeeReportScreen({super.key, this.initialEmployee});

  @override
  State<EmployeeReportScreen> createState() => _EmployeeReportScreenState();
}

class _EmployeeReportScreenState extends State<EmployeeReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  ReportStatusFilter _statusFilter = ReportStatusFilter.all;
  String? _selectedEmployeeId;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmployee != null) {
      _selectedEmployeeId = widget.initialEmployee!.id;
    }
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case ReportPeriod.today:
        return DateTimeRange(start: today, end: today);
      case ReportPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: today);
      case ReportPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: today);
      case ReportPeriod.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
      case ReportPeriod.custom:
        return _customDateRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: today,
            );
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _getDateRange(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0D9488),
                  onPrimary: Colors.white,
                  surface: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedPeriod = ReportPeriod.custom;
        _customDateRange = picked;
      });
    }
  }

  void _showEmployeeSearchPicker(BuildContext context, List<Employee> allEmployees, bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _EmployeeSearchBottomSheet(
          allEmployees: allEmployees,
          selectedEmployeeId: _selectedEmployeeId,
          isDark: isDark,
          onSelected: (selectedId) {
            setState(() => _selectedEmployeeId = selectedId);
          },
        );
      },
    );
  }

  List<Color> _getAvatarGradient(String name) {
    final palettes = [
      [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
      [const Color(0xFFF59E0B), const Color(0xFFFB923C)],
      [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
      [const Color(0xFFE11D48), const Color(0xFFFB7185)],
      [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
      [const Color(0xFF059669), const Color(0xFF34D399)],
    ];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<EmployeeProvider>();
    final allEmployees = provider.employees;
    final dateRange = _getDateRange();

    final filteredEmployees = _selectedEmployeeId == null
        ? allEmployees
        : allEmployees.where((e) => e.id == _selectedEmployeeId).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // Professional App Bar
          _buildProfessionalAppBar(isDark, filteredEmployees, allEmployees, provider, dateRange),

          // Main Interactive Body
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, List<AttendanceEntry>>>(
              future: _loadAllAttendance(provider, allEmployees),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                    ),
                  );
                }

                final attendanceData = snapshot.data ?? {};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Easy Time Filter Strip (This Month, This Week, etc.)
                    _buildEasyPeriodSelector(isDark, dateRange),

                    // 2. Search & Select Field for Staff (Scalable for 100+ employees)
                    _buildEmployeeSearchField(isDark, allEmployees),

                    // 3. Conversational Summary Box (Easy sentence for anyone to read)
                    _buildConversationalSummaryCard(isDark, filteredEmployees, attendanceData, dateRange),

                    // 4. Cheerful 4-Color KPI Big Numbers (Earnings, Advances, Due, Presence)
                    _buildCheerfulKpiCards(isDark, filteredEmployees, attendanceData, dateRange),

                    // 5. Visual Salary & Payment Split Bar (Visual Graph)
                    _buildPaymentSplitGraph(isDark, filteredEmployees, attendanceData, dateRange),

                    // 6. Visual Attendance Graph (Days breakdown)
                    _buildAttendanceVisualBarGraph(isDark, filteredEmployees, attendanceData, dateRange),

                    // 7. Individual Helper Cards (With clear settlement status)
                    _buildHelperSettlementCards(isDark, filteredEmployees, attendanceData, dateRange),

                    // 8. Filter by status (All, Present, Absent, Advance)
                    _buildStatusFilterRow(isDark),

                    // 9. Daily Diary Ledger
                    _buildDailyDiaryLedger(isDark, filteredEmployees, attendanceData, dateRange),

                    const SizedBox(height: 50),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildProfessionalAppBar(
    bool isDark,
    List<Employee> filteredEmployees,
    List<Employee> allEmployees,
    EmployeeProvider provider,
    DateTimeRange dateRange,
  ) {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F766E),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF134E4A),
                      const Color(0xFF1E293B),
                    ]
                  : [
                      const Color(0xFF0F766E),
                      const Color(0xFF0D9488),
                      const Color(0xFF14B8A6),
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(isDark ? 10 : 25),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 18,
                right: 18,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(isDark ? 25 : 35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.summarize_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Helper Reports & Diary',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Attendance, Wages & Settlement Ledger',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final allAttendance = <String, List<AttendanceEntry>>{};
              for (final emp in filteredEmployees) {
                final list = await provider.getAttendance(emp.id);
                allAttendance[emp.id] = list;
              }
              if (mounted) {
                await PdfService.generateEmployeeReport(filteredEmployees, allAttendance);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(isDark ? 30 : 40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(60)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Export PDF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<Map<String, List<AttendanceEntry>>> _loadAllAttendance(
    EmployeeProvider provider,
    List<Employee> employees,
  ) async {
    final Map<String, List<AttendanceEntry>> result = {};
    for (final emp in employees) {
      final list = await provider.getAttendance(emp.id);
      result[emp.id] = list;
    }
    return result;
  }

  // 1. Easy Period Selector
  Widget _buildEasyPeriodSelector(bool isDark, DateTimeRange dateRange) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  const Icon(Icons.date_range_rounded, size: 18, color: Color(0xFF0D9488)),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('d MMM').format(dateRange.start)} – ${DateFormat('d MMM yyyy').format(dateRange.end)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _selectCustomDateRange,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0D9488).withAlpha(80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF0D9488)),
                      SizedBox(width: 4),
                      Text(
                        'Change Dates',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEasyPeriodButton(ReportPeriod.thisMonth, 'This Month (इस महीने)', isDark),
                const SizedBox(width: 6),
                _buildEasyPeriodButton(ReportPeriod.thisWeek, 'This Week (इस हफ्ते)', isDark),
                const SizedBox(width: 6),
                _buildEasyPeriodButton(ReportPeriod.today, 'Today (आज)', isDark),
                const SizedBox(width: 6),
                _buildEasyPeriodButton(ReportPeriod.lastMonth, 'Last Month (पिछला महीना)', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEasyPeriodButton(ReportPeriod period, String title, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPeriod = period);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D9488)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // 2. Professional Search & Select Field for Staff (Scalable for 100+ employees)
  Widget _buildEmployeeSearchField(bool isDark, List<Employee> allEmployees) {
    final selectedEmp = _selectedEmployeeId != null
        ? allEmployees.where((e) => e.id == _selectedEmployeeId).firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedEmployeeId != null
              ? const Color(0xFF0D9488)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: _selectedEmployeeId != null ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEmployeeSearchPicker(context, allEmployees, isDark),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (selectedEmp != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: _getAvatarGradient(selectedEmp.name)),
                    ),
                    child: Center(
                      child: Text(
                        selectedEmp.name.isNotEmpty ? selectedEmp.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedEmp.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${selectedEmp.contact} • ₹${selectedEmp.baseSalary.toStringAsFixed(0)}/${selectedEmp.salaryBasis == 'monthly' ? 'mo' : 'day'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.grey,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedEmployeeId = null);
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withAlpha(isDark ? 35 : 18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF0D9488)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter by Staff: All Helpers (${allEmployees.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Tap to search and select individual helper',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0D9488)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Conversational Summary Card (Friendly text)
  Widget _buildConversationalSummaryCard(
    bool isDark,
    List<Employee> employees,
    Map<String, List<AttendanceEntry>> attendanceMap,
    DateTimeRange range,
  ) {
    int totalWorkingDays = 0;
    int totalAbsentDays = 0;
    double totalEarned = 0.0;
    double totalPaid = 0.0;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    for (final emp in employees) {
      final joinDate = DateTime(emp.joiningDate.year, emp.joiningDate.month, emp.joiningDate.day);
      final relDate = emp.relievingDate != null
          ? DateTime(emp.relievingDate!.year, emp.relievingDate!.month, emp.relievingDate!.day)
          : end;

      final effStart = start.isBefore(joinDate) ? joinDate : start;
      final effEnd = end.isAfter(relDate) ? relDate : end;

      if (effStart.isAfter(effEnd)) continue;

      final rangeDays = effEnd.difference(effStart).inDays + 1;
      final empEntries = attendanceMap[emp.id] ?? [];

      final absentCount = empEntries.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return e.status == AttendanceStatus.absent && !d.isBefore(effStart) && !d.isAfter(effEnd);
      }).length;

      final worked = (rangeDays - absentCount).clamp(0, rangeDays);
      totalWorkingDays += worked;
      totalAbsentDays += absentCount;

      final wageRate = emp.salaryBasis == 'monthly' ? (emp.baseSalary / 30.0) : emp.baseSalary;
      totalEarned += worked * wageRate;

      for (final e in empEntries) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (!d.isBefore(effStart) && !d.isAfter(effEnd) && e.amountGiven > 0) {
          totalPaid += e.amountGiven;
        }
      }
    }

    final balance = totalEarned - totalPaid;
    final empText = employees.length == 1 ? employees.first.name : '${employees.length} Helpers';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF134E4A), const Color(0xFF1E293B)]
              : [const Color(0xFFCCFBF1), const Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF14B8A6).withAlpha(50) : const Color(0xFF99F6E4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 20, color: Color(0xFF0D9488)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Summary (आसान सारांश)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance >= 0
                      ? '$empText worked $totalWorkingDays days ($totalAbsentDays absent). ₹${totalPaid.toStringAsFixed(0)} advance paid, ₹${balance.toStringAsFixed(0)} balance to give.'
                      : '$empText worked $totalWorkingDays days. ₹${totalPaid.toStringAsFixed(0)} advance paid, ₹${balance.abs().toStringAsFixed(0)} extra advance given.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Cheerful 4-Color Big Number Cards
  Widget _buildCheerfulKpiCards(
    bool isDark,
    List<Employee> employees,
    Map<String, List<AttendanceEntry>> attendanceMap,
    DateTimeRange range,
  ) {
    int totalWorkingDays = 0;
    int totalAbsentDays = 0;
    double totalEarned = 0.0;
    double totalPaid = 0.0;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    for (final emp in employees) {
      final joinDate = DateTime(emp.joiningDate.year, emp.joiningDate.month, emp.joiningDate.day);
      final relDate = emp.relievingDate != null
          ? DateTime(emp.relievingDate!.year, emp.relievingDate!.month, emp.relievingDate!.day)
          : end;

      final effStart = start.isBefore(joinDate) ? joinDate : start;
      final effEnd = end.isAfter(relDate) ? relDate : end;

      if (effStart.isAfter(effEnd)) continue;

      final rangeDays = effEnd.difference(effStart).inDays + 1;
      final empEntries = attendanceMap[emp.id] ?? [];

      final absentCount = empEntries.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return e.status == AttendanceStatus.absent && !d.isBefore(effStart) && !d.isAfter(effEnd);
      }).length;

      final worked = (rangeDays - absentCount).clamp(0, rangeDays);
      totalWorkingDays += worked;
      totalAbsentDays += absentCount;

      final wageRate = emp.salaryBasis == 'monthly' ? (emp.baseSalary / 30.0) : emp.baseSalary;
      totalEarned += worked * wageRate;

      for (final e in empEntries) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (!d.isBefore(effStart) && !d.isAfter(effEnd) && e.amountGiven > 0) {
          totalPaid += e.amountGiven;
        }
      }
    }

    final balance = totalEarned - totalPaid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              // 1. Emerald Mint - Total Earned (कमाई)
              Expanded(
                child: _buildPlayfulMetricTile(
                  icon: Icons.account_balance_wallet_rounded,
                  titleEn: 'Total Earned',
                  titleHi: 'कुल कमाई',
                  amount: '₹${totalEarned.toStringAsFixed(0)}',
                  subText: '$totalWorkingDays days worked',
                  bgGradient: [const Color(0xFF059669), const Color(0xFF10B981)],
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // 2. Warm Amber - Total Advance Paid (पेशगी)
              Expanded(
                child: _buildPlayfulMetricTile(
                  icon: Icons.payments_rounded,
                  titleEn: 'Advance Paid',
                  titleHi: 'दी गई पेशगी',
                  amount: '₹${totalPaid.toStringAsFixed(0)}',
                  subText: 'Given in advance',
                  bgGradient: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 3. Sky Blue / Coral - Net Due Balance (देना बाकी)
              Expanded(
                child: _buildPlayfulMetricTile(
                  icon: balance >= 0 ? Icons.handshake_rounded : Icons.warning_amber_rounded,
                  titleEn: balance >= 0 ? 'Due to Pay' : 'Overpaid',
                  titleHi: balance >= 0 ? 'देना बाकी है' : 'ज्यादा दिया',
                  amount: '₹${balance.abs().toStringAsFixed(0)}',
                  subText: balance >= 0 ? 'Final payment' : 'Carry forward',
                  bgGradient: balance >= 0
                      ? [const Color(0xFF0284C7), const Color(0xFF38BDF8)]
                      : [const Color(0xFFDC2626), const Color(0xFFF87171)],
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // 4. Rose Pink - Attendance Summary (हाजिरी)
              Expanded(
                child: _buildPlayfulMetricTile(
                  icon: Icons.calendar_today_rounded,
                  titleEn: 'Days Present',
                  titleHi: 'आए हुए दिन',
                  amount: '$totalWorkingDays Days',
                  subText: '$totalAbsentDays days absent',
                  bgGradient: [const Color(0xFFE11D48), const Color(0xFFFB7185)],
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayfulMetricTile({
    required IconData icon,
    required String titleEn,
    required String titleHi,
    required String amount,
    required String subText,
    required List<Color> bgGradient,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgGradient[0].withAlpha(isDark ? 60 : 35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: bgGradient[0].withAlpha(isDark ? 30 : 15),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgGradient[0].withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: bgGradient[0]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bgGradient[0].withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  titleHi,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: bgGradient[0],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            titleEn,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: bgGradient[0],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Visual Salary & Payment Split Graph
  Widget _buildPaymentSplitGraph(
    bool isDark,
    List<Employee> employees,
    Map<String, List<AttendanceEntry>> attendanceMap,
    DateTimeRange range,
  ) {
    double totalEarned = 0.0;
    double totalPaid = 0.0;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    for (final emp in employees) {
      final joinDate = DateTime(emp.joiningDate.year, emp.joiningDate.month, emp.joiningDate.day);
      final relDate = emp.relievingDate != null
          ? DateTime(emp.relievingDate!.year, emp.relievingDate!.month, emp.relievingDate!.day)
          : end;

      final effStart = start.isBefore(joinDate) ? joinDate : start;
      final effEnd = end.isAfter(relDate) ? relDate : end;

      if (effStart.isAfter(effEnd)) continue;

      final rangeDays = effEnd.difference(effStart).inDays + 1;
      final empEntries = attendanceMap[emp.id] ?? [];

      final absentCount = empEntries.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return e.status == AttendanceStatus.absent && !d.isBefore(effStart) && !d.isAfter(effEnd);
      }).length;

      final worked = (rangeDays - absentCount).clamp(0, rangeDays);
      final wageRate = emp.salaryBasis == 'monthly' ? (emp.baseSalary / 30.0) : emp.baseSalary;
      totalEarned += worked * wageRate;

      for (final e in empEntries) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (!d.isBefore(effStart) && !d.isAfter(effEnd) && e.amountGiven > 0) {
          totalPaid += e.amountGiven;
        }
      }
    }

    if (totalEarned <= 0 && totalPaid <= 0) return const SizedBox.shrink();

    final paidFraction = totalEarned > 0 ? (totalPaid / totalEarned).clamp(0.0, 1.0) : 1.0;
    final dueBalance = totalEarned - totalPaid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 17, color: Color(0xFF0D9488)),
              SizedBox(width: 6),
              Text(
                'Payment Split Graph (हिसाब की स्थिति)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multi-color segmented visual progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (paidFraction > 0)
                    Expanded(
                      flex: (paidFraction * 100).round(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
                          ),
                        ),
                      ),
                    ),
                  if (paidFraction < 1.0)
                    Expanded(
                      flex: ((1.0 - paidFraction) * 100).round(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Advance Given: ₹${totalPaid.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    dueBalance >= 0 ? 'Remaining Due: ₹${dueBalance.toStringAsFixed(0)}' : 'Overpaid',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Visual Attendance Graph (Days breakdown)
  Widget _buildAttendanceVisualBarGraph(
    bool isDark,
    List<Employee> employees,
    Map<String, List<AttendanceEntry>> attendanceMap,
    DateTimeRange range,
  ) {
    int totalWorkingDays = 0;
    int totalAbsentDays = 0;
    int totalLate = 0;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    for (final emp in employees) {
      final joinDate = DateTime(emp.joiningDate.year, emp.joiningDate.month, emp.joiningDate.day);
      final relDate = emp.relievingDate != null
          ? DateTime(emp.relievingDate!.year, emp.relievingDate!.month, emp.relievingDate!.day)
          : end;

      final effStart = start.isBefore(joinDate) ? joinDate : start;
      final effEnd = end.isAfter(relDate) ? relDate : end;

      if (effStart.isAfter(effEnd)) continue;

      final rangeDays = effEnd.difference(effStart).inDays + 1;
      final empEntries = attendanceMap[emp.id] ?? [];

      final absentCount = empEntries.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return e.status == AttendanceStatus.absent && !d.isBefore(effStart) && !d.isAfter(effEnd);
      }).length;

      final lateCount = empEntries.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return (e.status == AttendanceStatus.late || e.status == AttendanceStatus.early) &&
            !d.isBefore(effStart) &&
            !d.isAfter(effEnd);
      }).length;

      final worked = (rangeDays - absentCount).clamp(0, rangeDays);
      totalWorkingDays += worked;
      totalAbsentDays += absentCount;
      totalLate += lateCount;
    }

    final totalDays = totalWorkingDays + totalAbsentDays;
    final presentPercent = totalDays > 0 ? (totalWorkingDays / totalDays * 100).round() : 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, size: 17, color: Color(0xFF0D9488)),
                  SizedBox(width: 6),
                  Text(
                    'Attendance Score (हाजिरी का स्कोर)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$presentPercent% Presence',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Visual 3-Pillar Comparison
          Row(
            children: [
              Expanded(
                child: _buildAttendancePillar(
                  icon: Icons.check_circle_rounded,
                  label: 'Present (आए)',
                  count: '$totalWorkingDays Days',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendancePillar(
                  icon: Icons.cancel_rounded,
                  label: 'Absent (छुट्टी)',
                  count: '$totalAbsentDays Days',
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendancePillar(
                  icon: Icons.schedule_rounded,
                  label: 'Late (देरी)',
                  count: '$totalLate Times',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePillar({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(isDark ? 50 : 30)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 7. Individual Helper Settlement Cards
  Widget _buildHelperSettlementCards(
    bool isDark,
    List<Employee> employees,
    Map<String, List<AttendanceEntry>> attendanceMap,
    DateTimeRange range,
  ) {
    if (employees.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 16, color: Color(0xFF0D9488)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Staff Settlements (कर्मचारी हिसाब)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tap for profile',
                style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...employees.map((emp) {
            final start = DateTime(range.start.year, range.start.month, range.start.day);
            final end = DateTime(range.end.year, range.end.month, range.end.day);
            final joinDate = DateTime(emp.joiningDate.year, emp.joiningDate.month, emp.joiningDate.day);
            final relDate = emp.relievingDate != null
                ? DateTime(emp.relievingDate!.year, emp.relievingDate!.month, emp.relievingDate!.day)
                : end;

            final effStart = start.isBefore(joinDate) ? joinDate : start;
            final effEnd = end.isAfter(relDate) ? relDate : end;

            final rangeDays = effStart.isAfter(effEnd) ? 0 : effEnd.difference(effStart).inDays + 1;
            final empEntries = attendanceMap[emp.id] ?? [];

            final absentCount = empEntries.where((e) {
              final d = DateTime(e.date.year, e.date.month, e.date.day);
              return e.status == AttendanceStatus.absent && !d.isBefore(effStart) && !d.isAfter(effEnd);
            }).length;

            final worked = (rangeDays - absentCount).clamp(0, rangeDays);
            final wageRate = emp.salaryBasis == 'monthly' ? (emp.baseSalary / 30.0) : emp.baseSalary;
            final earned = worked * wageRate;

            double paid = 0.0;
            for (final e in empEntries) {
              final d = DateTime(e.date.year, e.date.month, e.date.day);
              if (!d.isBefore(effStart) && !d.isAfter(effEnd) && e.amountGiven > 0) {
                paid += e.amountGiven;
              }
            }

            final bal = earned - paid;
            final gradient = _getAvatarGradient(emp.name);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeDetailScreen(employee: emp),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: gradient),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[0].withAlpha(60),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      emp.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withAlpha(isDark ? 35 : 18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '₹${emp.baseSalary.toStringAsFixed(0)}/${emp.salaryBasis == 'monthly' ? 'mo' : 'day'}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$worked present • $absentCount absent',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${earned.toStringAsFixed(0)} earned',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: bal >= 0
                                    ? const Color(0xFF0284C7).withAlpha(isDark ? 35 : 18)
                                    : const Color(0xFFEF4444).withAlpha(isDark ? 35 : 18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bal >= 0 ? 'Due: ₹${bal.toStringAsFixed(0)}' : 'Adv: ₹${bal.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.5,
                                  color: bal >= 0 ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 8. Filter by status
  Widget _buildStatusFilterRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusTag(ReportStatusFilter.all, 'All Records', Icons.list_alt_rounded, const Color(0xFF0D9488), isDark),
            const SizedBox(width: 6),
            _buildStatusTag(ReportStatusFilter.present, 'Present Only', Icons.check_circle_rounded, const Color(0xFF10B981), isDark),
            const SizedBox(width: 6),
            _buildStatusTag(ReportStatusFilter.absent, 'Absent Only', Icons.cancel_rounded, const Color(0xFFEF4444), isDark),
            const SizedBox(width: 6),
            _buildStatusTag(ReportStatusFilter.withPayment, 'Payments / Advance', Icons.payments_rounded, const Color(0xFFF59E0B), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(ReportStatusFilter filter, String label, IconData icon, Color color, bool isDark) {
    final isSelected = _statusFilter == filter;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _statusFilter = filter);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 9. Daily Diary Ledger
  Widget _buildDailyDiaryLedger(
    bool isDark,
    List<Employee> employees,
    Map<String, List<AttendanceEntry>> attendanceMap,
    DateTimeRange range,
  ) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    final List<_LedgerItem> items = [];

    for (final emp in employees) {
      final empEntries = attendanceMap[emp.id] ?? [];
      for (final entry in empEntries) {
        final d = DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (!d.isBefore(start) && !d.isAfter(end)) {
          if (_statusFilter == ReportStatusFilter.absent && entry.status != AttendanceStatus.absent) {
            continue;
          }
          if (_statusFilter == ReportStatusFilter.present && entry.status == AttendanceStatus.absent) {
            continue;
          }
          if (_statusFilter == ReportStatusFilter.withPayment && entry.amountGiven <= 0) {
            continue;
          }

          items.add(_LedgerItem(employee: emp, entry: entry));
        }
      }
    }

    items.sort((a, b) => b.entry.date.compareTo(a.entry.date));

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 17, color: Color(0xFF0D9488)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Daily Attendance & Payment Ledger',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${items.length} records',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 32, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  const SizedBox(height: 6),
                  Text(
                    'No records found for this filter',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((item) {
              final isAbsent = item.entry.status == AttendanceStatus.absent;
              final isLate = item.entry.status == AttendanceStatus.late;
              final isEarly = item.entry.status == AttendanceStatus.early;
              final hasPayment = item.entry.amountGiven > 0;

              final statusColor = isAbsent
                  ? const Color(0xFFEF4444)
                  : isLate
                      ? const Color(0xFFF59E0B)
                      : isEarly
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF10B981);

              final statusIcon = isAbsent
                  ? Icons.cancel_rounded
                  : isLate
                      ? Icons.schedule_rounded
                      : isEarly
                          ? Icons.logout_rounded
                          : Icons.check_circle_rounded;

              final statusShortText = isAbsent
                  ? 'Absent'
                  : isLate
                      ? 'Late'
                      : isEarly
                          ? 'Early'
                          : 'Present';

              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withAlpha(isDark ? 50 : 35),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 20 : 5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cheerful date pill
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(isDark ? 30 : 15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd').format(item.entry.date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(item.entry.date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.employee.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(isDark ? 35 : 18),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 11, color: statusColor),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      statusShortText,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, dd MMMM').format(item.entry.date),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.entry.lateTime != null || item.entry.earlyTime != null)
                            Text(
                              item.entry.lateTime != null
                                  ? 'Arrival: ${item.entry.lateTime}'
                                  : 'Departure: ${item.entry.earlyTime}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (hasPayment)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(isDark ? 35 : 18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withAlpha(70)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${item.entry.amountGiven.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                item.entry.paymentDescription?.isNotEmpty == true
                                    ? item.entry.paymentDescription!
                                    : 'Advance',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// Searchable Bottom Sheet Picker for large employee datasets
class _EmployeeSearchBottomSheet extends StatefulWidget {
  final List<Employee> allEmployees;
  final String? selectedEmployeeId;
  final bool isDark;
  final ValueChanged<String?> onSelected;

  const _EmployeeSearchBottomSheet({
    required this.allEmployees,
    required this.selectedEmployeeId,
    required this.isDark,
    required this.onSelected,
  });

  @override
  State<_EmployeeSearchBottomSheet> createState() => _EmployeeSearchBottomSheetState();
}

class _EmployeeSearchBottomSheetState extends State<_EmployeeSearchBottomSheet> {
  String _query = '';
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allEmployees.where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.name.toLowerCase().contains(q) || e.contact.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Staff Member',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Search Field
          TextField(
            controller: _ctrl,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search by name or contact number...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                // "All Helpers" Tile
                if (_query.isEmpty)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    selected: widget.selectedEmployeeId == null,
                    selectedTileColor: const Color(0xFF0D9488).withAlpha(widget.isDark ? 35 : 20),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D9488),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                    ),
                    title: const Text('All Staff Members (सब कर्मचारी)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${widget.allEmployees.length} total staff in directory'),
                    trailing: widget.selectedEmployeeId == null
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488))
                        : null,
                    onTap: () {
                      widget.onSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                const Divider(height: 12),
                ...filtered.map((emp) {
                  final isSelected = widget.selectedEmployeeId == emp.id;
                  final initial = emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?';
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF0D9488).withAlpha(widget.isDark ? 35 : 20),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D9488),
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${emp.contact} • ₹${emp.baseSalary.toStringAsFixed(0)}/${emp.salaryBasis}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488))
                        : null,
                    onTap: () {
                      widget.onSelected(emp.id);
                      Navigator.pop(context);
                    },
                  );
                }),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No staff member matching "$_query"',
                        style: TextStyle(
                          color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _LedgerItem {
  final Employee employee;
  final AttendanceEntry entry;

  _LedgerItem({required this.employee, required this.entry});
}
