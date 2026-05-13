import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_attendance.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';

class ServiceReportScreen extends StatefulWidget {
  const ServiceReportScreen({super.key});

  @override
  State<ServiceReportScreen> createState() => _ServiceReportScreenState();
}

class _ServiceReportScreenState extends State<ServiceReportScreen> {
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final settings = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final totalEarnings = todoProvider.getTotalEarnings(_rangeStart, _rangeEnd);
    final dailyEarnings = todoProvider.getDailyEarnings(_rangeStart, _rangeEnd);
    final currencySymbol = settings.currency.symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _showExportImportDialog(context, todoProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _buildRangeSelector(theme),
          const SizedBox(height: 20),
          _SummaryCard(
            title: 'Total Earnings',
            value: '$currencySymbol${totalEarnings.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Daily Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (dailyEarnings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No earnings recorded for this range.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            _EarningsChart(dailyEarnings: dailyEarnings, start: _rangeStart, end: _rangeEnd),
          const SizedBox(height: 24),
          Text(
            'Recent Service Activity',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._buildRecentActivity(todoProvider, currencySymbol),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${DateFormat('MMM d').format(_rangeStart)} - ${DateFormat('MMM d, yyyy').format(_rangeEnd)}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _rangeStart = DateTime(2020);
                _rangeEnd = DateTime.now().add(const Duration(days: 365 * 10));
              });
            },
            child: const Text('All'),
          ),
          TextButton(
            onPressed: () => _selectRange(context),
            child: const Text('Range'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });
    }
  }

  List<Widget> _buildRecentActivity(TodoProvider provider, String currencySymbol) {
    final records = provider.todos
        .expand((t) => t.attendanceRecords.map((r) => MapEntry(t, r)))
        .where((e) => e.value.price != null)
        .toList();
    records.sort((a, b) => b.value.date.compareTo(a.value.date));

    return records.take(10).map((e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.payments_rounded)),
          title: Text(e.key.title),
          subtitle: Text(DateFormat('EEE, MMM d').format(e.value.date)),
          trailing: Text(
            '+$currencySymbol${e.value.price?.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      );
    }).toList();
  }

  void _showExportImportDialog(BuildContext context, TodoProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Data Management', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.upload_rounded),
              title: const Text('Export JSON'),
              subtitle: const Text('Copy data to clipboard or share'),
              onTap: () {
                final data = provider.exportData();
                debugPrint(data); // In a real app, use share_plus
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data exported to console (simulated)')));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Import JSON'),
              subtitle: const Text('Restore data from a backup string'),
              onTap: () => _showImportInput(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportInput(BuildContext context, TodoProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste JSON here'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              try {
                provider.importData(controller.text);
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data imported successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid data format')));
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(200), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withAlpha(60), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final Map<DateTime, double> dailyEarnings;
  final DateTime start;
  final DateTime end;

  const _EarningsChart({required this.dailyEarnings, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = end.difference(start).inDays + 1;
    final maxBars = 31;
    final chartDays = days > maxBars ? maxBars : days;
    final chartStart = days > maxBars ? end.subtract(Duration(days: maxBars - 1)) : start;

    final maxEarning = dailyEarnings.values.fold(0.0, (m, e) => e > m ? e : m);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartDays, (index) {
                final date = DateTime(chartStart.year, chartStart.month, chartStart.day + index);
                final earning = dailyEarnings[DateTime(date.year, date.month, date.day)] ?? 0.0;
                final heightFactor = maxEarning == 0 ? 0.0 : earning / maxEarning;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (120 * heightFactor).clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: earning > 0 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(100),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(date),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (days > maxBars)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing last 31 days in chart',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
