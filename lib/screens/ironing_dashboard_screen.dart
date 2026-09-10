import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/employee_provider.dart';
import '../models/ironing_model.dart';

class IroningDashboardScreen extends StatefulWidget {
  const IroningDashboardScreen({super.key});

  @override
  State<IroningDashboardScreen> createState() => _IroningDashboardScreenState();
}

class _IroningDashboardScreenState extends State<IroningDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedWorkerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Color> _getAvatarGradient(String name) {
    final palettes = [
      [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
      [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFE11D48), const Color(0xFFFB7185)],
      [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
    ];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return palettes[hash % palettes.length];
  }

  Future<void> _makeCall(String contact) async {
    final Uri url = Uri.parse('tel:$contact');
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
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF0D9488), size: 18),
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
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final workers = employeeProvider.ironingWorkers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_selectedWorkerId == null || !workers.any((w) => w.id == _selectedWorkerId)) {
      if (workers.isNotEmpty) {
        _selectedWorkerId = workers.first.id;
      }
    }

    final selectedWorker = workers.isNotEmpty
        ? workers.firstWhere((w) => w.id == _selectedWorkerId, orElse: () => workers.first)
        : null;

    final mainHeaderCard = SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF134E4A), const Color(0xFF1E293B)]
                : [const Color(0xFF0F766E), const Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withAlpha(isDark ? 30 : 25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(isDark ? 25 : 35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.iron_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Ironing Registry',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(isDark ? 30 : 40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${workers.length} ${workers.length == 1 ? "worker" : "workers"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Clothes count, rates & payments (इस्त्री का हिसाब)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(220),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _showAddWorkerDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isDark ? 30 : 40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withAlpha(60),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add Worker',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: null,
      body: selectedWorker == null
          ? Column(
              children: [
                mainHeaderCard,
                if (employeeProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      child: LinearProgressIndicator(
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: employeeProvider.isLoading && workers.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 2.8,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Syncing ironing data...',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.iron_rounded, size: 54, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  'No Ironing Workers Found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add your dhobi or ironing helper to start tracking clothes and payments.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D9488),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                  ),
                                  onPressed: () => _showAddWorkerDialog(context),
                                  icon: const Icon(Icons.person_add_rounded, size: 17),
                                  label: const Text('Add First Worker', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                mainHeaderCard,
                if (employeeProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      child: LinearProgressIndicator(
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF0D9488),
                    onRefresh: () => context.read<EmployeeProvider>().refreshData(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      children: [
                        _buildWorkerSelectorCard(workers, selectedWorker, isDark),
                        const SizedBox(height: 8),
                        _buildWorkerSummaryHeader(selectedWorker, isDark),
                        const SizedBox(height: 8),
                        _buildRateCardSection(selectedWorker, isDark),
                        const SizedBox(height: 10),
                        _buildActionRow(selectedWorker, isDark),
                        const SizedBox(height: 12),
                        // Custom Pill Segmented TabBar
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCCFBF1),
                              width: 1,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            onTap: (idx) => setState(() {}),
                            indicator: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withAlpha(70),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            tabs: const [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.checkroom_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Clothes Given Logs'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payments_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Payment History'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            return _tabController.index == 0
                                ? _ClothesLogsTab(workerId: selectedWorker.id, shrinkWrap: true, physics: const NeverScrollableScrollPhysics())
                                : _PaymentLogsTab(workerId: selectedWorker.id, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWorkerSelectorCard(List<IroningWorker> workers, IroningWorker selected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getAvatarGradient(selected.name),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                selected.name.isNotEmpty ? selected.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _showWorkerSelectionSheet(context, workers, selected),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        selected.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                    ],
                  ),
                  Text(
                    selected.contact.isNotEmpty ? selected.contact : 'Tap to switch worker',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected.contact.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.call_rounded, size: 18, color: Color(0xFF10B981)),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5),
                padding: const EdgeInsets.all(6),
                minimumSize: Size.zero,
              ),
              tooltip: 'Call Worker',
              onPressed: () => _makeCall(selected.contact),
            ),
            const SizedBox(width: 6),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0x28EF4444) : const Color(0xFFFEF2F2),
              padding: const EdgeInsets.all(6),
              minimumSize: Size.zero,
            ),
            tooltip: 'Remove Worker',
            onPressed: () => _confirmDeleteWorker(context, selected),
          ),
        ],
      ),
    );
  }

  void _showWorkerSelectionSheet(BuildContext context, List<IroningWorker> workers, IroningWorker selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String query = '';
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = workers.where((w) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return w.name.toLowerCase().contains(q) || w.contact.contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Ironing Worker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.all(6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search box
                    TextField(
                      controller: ctrl,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Search worker by name or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  ctrl.clear();
                                  setModalState(() => query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setModalState(() => query = val),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final w = filtered[index];
                          final isSelected = w.id == selected.id;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0x280D9488) : const Color(0xFFF0FDFA))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: _getAvatarGradient(w.name)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              title: Text(
                                w.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: w.contact.isNotEmpty
                                  ? Text(w.contact, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))
                                  : null,
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 20)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedWorkerId = w.id;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkerSummaryHeader(IroningWorker worker, bool isDark) {
    final provider = context.read<EmployeeProvider>();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        provider.getIroningRecords(worker.id),
        provider.getIroningPayments(worker.id),
      ]),
      builder: (context, snapshot) {
        final records = snapshot.hasData ? (snapshot.data![0] as List<IroningRecord>) : <IroningRecord>[];
        final payments = snapshot.hasData ? (snapshot.data![1] as List<IroningPayment>) : <IroningPayment>[];

        double totalEarnings = 0;
        int totalClothes = 0;
        for (var rec in records) {
          totalEarnings += rec.totalWage;
          for (var qty in rec.clothesCount.values) {
            totalClothes += qty;
          }
        }

        double totalPaid = 0;
        for (var pay in payments) {
          totalPaid += pay.amount;
        }

        final balance = totalEarnings - totalPaid;
        final settledPercentage = totalEarnings > 0 ? (totalPaid / totalEarnings).clamp(0.0, 1.0) : 0.0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'TOTAL EARNED',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${totalEarnings.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalClothes pcs',
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'TOTAL PAID',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${totalPaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${payments.length} payments',
                          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 36, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'BALANCE',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${balance.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          balance >= 0 ? 'Due to helper' : 'Advance surplus',
                          style: TextStyle(
                            color: balance >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payout Settlement',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      Text(
                        '${(settledPercentage * 100).toStringAsFixed(0)}% paid',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: settledPercentage,
                      minHeight: 5,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateCardSection(IroningWorker worker, bool isDark) {
    return FutureBuilder<List<IronRate>>(
      future: context.read<EmployeeProvider>().getIronRates(worker.id),
      builder: (context, snapshot) {
        final ratesList = snapshot.data ?? [];
        final Map<String, double> ratesMap = {
          'Small Clothes': 4.0,
          'Medium Clothes': 5.0,
          'Large Clothes': 7.0,
          'XL Clothes': 10.0,
          'Others': 5.0,
        };
        for (final rate in ratesList) {
          final typeRates = ratesList.where((r) => r.clothingType == rate.clothingType).toList();
          typeRates.sort((a, b) => b.date.compareTo(a.date));
          ratesMap[rate.clothingType] = typeRates.first.rate;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ironing Rate Chart',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showEditRatesDialog(context, worker, ratesMap),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: Color(0xFF0D9488)),
                          SizedBox(width: 4),
                          Text('Edit Rates', style: TextStyle(fontSize: 11.5, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ratesMap.entries.map((e) => _buildRateIndicator(e.key, e.value, isDark)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateIndicator(String label, double rate, bool isDark) {
    final color = _getClothTypeColor(label);
    final icon = _getClothTypeIcon(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 30 : 18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(isDark ? 80 : 50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color.withAlpha(isDark ? 50 : 30),
            child: Icon(icon, color: color, size: 11),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '₹${rate.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IroningWorker worker, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
              ),
              onPressed: () => _showAddClothesDialog(context, worker),
              icon: const Icon(Icons.checkroom_rounded, size: 17),
              label: const Text('Add Clothes Given', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 42,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
              ),
              onPressed: () => _showAddPaymentDialog(context, worker),
              icon: const Icon(Icons.payments_rounded, size: 17),
              label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWorkerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

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
                              ? [const Color(0xFF134E4A), const Color(0xFF0F766E)]
                              : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                        ),
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF0F766E) : const Color(0xFF99F6E4))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF0D9488),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add Ironing Worker / Dhobi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF134E4A),
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
                      child: Column(
                        children: [
                          _buildDialogInputField(
                            context: context,
                            controller: nameController,
                            label: 'Worker Name',
                            prefixIcon: Icons.badge_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter worker name' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: contactController,
                            label: 'Contact Phone (Optional)',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
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
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDlgState(() => isSaving = true);
                                    try {
                                      final worker = IroningWorker(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        name: nameController.text.trim(),
                                        contact: contactController.text.trim(),
                                        joiningDate: DateTime.now(),
                                      );
                                      await context.read<EmployeeProvider>().addIroningWorker(worker);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        setState(() {
                                          _selectedWorkerId = worker.id;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Ironing worker "${worker.name}" added'),
                                            backgroundColor: const Color(0xFF059669),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to add worker: $e'), backgroundColor: Colors.redAccent),
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
                                : const Text('Add Worker', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _confirmDeleteWorker(BuildContext context, IroningWorker worker) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Worker?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove ${worker.name}? This will delete all their recorded ironing and payment logs.',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await context.read<EmployeeProvider>().deleteIroningWorker(worker.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _selectedWorkerId = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Worker removed'), backgroundColor: Color(0xFFDC2626)),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditRatesDialog(BuildContext context, IroningWorker worker, Map<String, double> current) {
    final formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> controllers = {};
    current.forEach((key, val) {
      controllers[key] = TextEditingController(text: val.toStringAsFixed(0));
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        bool showAddForm = false;
        bool isSaving = false;
        final nameController = TextEditingController();
        final rateController = TextEditingController();

        return StatefulBuilder(
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
                                ? [const Color(0xFF134E4A), const Color(0xFF0F766E)]
                                : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                          ),
                          border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF0F766E) : const Color(0xFF99F6E4))),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF0D9488),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Edit Ironing Rates',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF134E4A),
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
                        child: Column(
                          children: [
                            ...controllers.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: _buildDialogInputField(
                                    context: context,
                                    controller: entry.value,
                                    label: '${entry.key} Rate (₹)',
                                    prefixIcon: Icons.currency_rupee_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) < 0 ? 'Enter valid rate' : null,
                                  ),
                                )),
                            const SizedBox(height: 4),
                            if (!showAddForm)
                              OutlinedButton.icon(
                                onPressed: () => setDlgState(() => showAddForm = true),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Custom Cloth Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D9488),
                                  side: const BorderSide(color: Color(0xFF0D9488)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('New Cloth Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488))),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: nameController,
                                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                            decoration: InputDecoration(
                                              labelText: 'Cloth Name',
                                              hintText: 'e.g. Kurta',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller: rateController,
                                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              labelText: 'Rate (₹)',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => setDlgState(() {
                                            nameController.clear();
                                            rateController.clear();
                                            showAddForm = false;
                                          }),
                                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 6),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D9488),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () {
                                            final name = nameController.text.trim();
                                            final val = double.tryParse(rateController.text) ?? 0.0;
                                            if (name.isEmpty || val <= 0) return;
                                            setDlgState(() {
                                              controllers[name] = TextEditingController(text: val.toStringAsFixed(0));
                                              nameController.clear();
                                              rateController.clear();
                                              showAddForm = false;
                                            });
                                          },
                                          child: const Text('Add', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    )
                                  ],
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
                                backgroundColor: const Color(0xFF0D9488),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDlgState(() => isSaving = true);
                                      try {
                                        final provider = context.read<EmployeeProvider>();
                                        final now = DateTime.now();

                                        for (final entry in controllers.entries) {
                                          final type = entry.key;
                                          final val = double.parse(entry.value.text);
                                          final original = current[type] ?? -1.0;
                                          if (val != original) {
                                            final rate = IronRate(
                                              id: '${type}_${now.millisecondsSinceEpoch}',
                                              clothingType: type,
                                              rate: val,
                                              date: now,
                                            );
                                            await provider.saveIronRate(worker.id, rate);
                                          }
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Rates updated'), backgroundColor: Color(0xFF059669)),
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
                                  : const Text('Save Rates', style: TextStyle(fontWeight: FontWeight.bold)),
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
      },
    );
  }

  void _showAddClothesDialog(BuildContext context, IroningWorker worker) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          child: _AddClothesDialog(worker: worker, onSaved: () => setState(() {})),
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, IroningWorker worker) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime paymentDate = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    final presetAmounts = [200, 500, 1000, 2000];
    final presetReasons = ['Weekly Settlement', 'Advance', 'Full Payment'];

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
                                  'Pay for Ironing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF78350F),
                                  ),
                                ),
                                Text(
                                  'Payee: ${worker.name}',
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
                            label: 'Amount Paid (₹)',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Enter valid amount' : null,
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
                          _buildDialogInputField(
                            context: context,
                            controller: descController,
                            label: 'Remarks / Notes (Optional)',
                            prefixIcon: Icons.edit_note_rounded,
                            hintText: 'e.g. Weekly settlement...',
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
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: paymentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setDlgState(() => paymentDate = date);
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
                                    'Date: ${DateFormat('dd MMMM yyyy').format(paymentDate)}',
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
                                      final payment = IroningPayment(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        workerId: worker.id,
                                        date: paymentDate,
                                        amount: amount,
                                        description: descController.text.trim().isNotEmpty
                                            ? descController.text.trim()
                                            : 'Weekly Payment',
                                        createdAt: DateTime.now(),
                                      );
                                      await context.read<EmployeeProvider>().saveIroningPayment(worker.id, payment);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                Text('Paid ₹${amount.toStringAsFixed(0)} to ${worker.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _AddClothesDialog extends StatefulWidget {
  final IroningWorker worker;
  final VoidCallback onSaved;
  const _AddClothesDialog({required this.worker, required this.onSaved});

  @override
  State<_AddClothesDialog> createState() => _AddClothesDialogState();
}

class _AddClothesDialogState extends State<_AddClothesDialog> {
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _counts = {};
  Map<String, double> _rates = {};
  bool _ratesLoaded = false;
  bool _isSaving = false;

  bool _showAddCustomForm = false;
  final _customNameController = TextEditingController();
  final _customRateController = TextEditingController();

  @override
  void dispose() {
    _customNameController.dispose();
    _customRateController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ratesLoaded) {
      _loadRates();
    }
  }

  Future<void> _loadRates() async {
    final list = await context.read<EmployeeProvider>().getIronRates(widget.worker.id);
    if (mounted) {
      setState(() {
        _counts = {
          'Small Clothes': 0,
          'Medium Clothes': 0,
          'Large Clothes': 0,
          'XL Clothes': 0,
          'Others': 0,
        };
        _rates = {
          'Small Clothes': 4.0,
          'Medium Clothes': 5.0,
          'Large Clothes': 7.0,
          'XL Clothes': 10.0,
          'Others': 5.0,
        };
        for (final rate in list) {
          if (!_rates.containsKey(rate.clothingType)) {
            _counts[rate.clothingType] = 0;
          }
          final typeRates = list.where((r) => r.clothingType == rate.clothingType).toList();
          typeRates.sort((a, b) => b.date.compareTo(a.date));
          _rates[rate.clothingType] = typeRates.first.rate;
        }
        _ratesLoaded = true;
      });
    }
  }

  double get _totalEarnings {
    double total = 0.0;
    _counts.forEach((type, count) {
      final rate = _rates[type] ?? 0.0;
      total += count * rate;
    });
    return total;
  }

  int get _totalPieces {
    int count = 0;
    _counts.forEach((_, c) => count += c);
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                      : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                ),
                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF10B981),
                    child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Clothes Given',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF064E3B),
                          ),
                        ),
                        Text(
                          'Worker: ${widget.worker.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
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
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _selectedDate = date);
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
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Text(
                            'Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
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
                  const SizedBox(height: 14),

                  // Dynamic counter list
                  ..._counts.keys.map((type) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildCounterRow(type, _counts[type] ?? 0, (val) {
                          setState(() => _counts[type] = val);
                        }, isDark),
                      )),

                  const SizedBox(height: 6),

                  // Add custom cloth type form
                  if (!_showAddCustomForm)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showAddCustomForm = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Custom Cloth Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New Cloth Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _customNameController,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                  decoration: InputDecoration(
                                    labelText: 'Cloth Name',
                                    hintText: 'e.g. Kurta',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _customRateController,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Rate (₹)',
                                    hintText: 'e.g. 8',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _customNameController.clear();
                                    _customRateController.clear();
                                    _showAddCustomForm = false;
                                  });
                                },
                                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final name = _customNameController.text.trim();
                                  final rateVal = double.tryParse(_customRateController.text) ?? 0.0;
                                  if (name.isEmpty || rateVal <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter valid name and rate')),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _counts[name] = 0;
                                    _rates[name] = rateVal;
                                    _showAddCustomForm = false;
                                    _customNameController.clear();
                                    _customRateController.clear();
                                  });

                                  final provider = context.read<EmployeeProvider>();
                                  final now = DateTime.now();
                                  final rate = IronRate(
                                    id: '${name}_${now.millisecondsSinceEpoch}',
                                    clothingType: name,
                                    rate: rateVal,
                                    date: now,
                                  );
                                  await provider.saveIronRate(widget.worker.id, rate);
                                },
                                child: const Text('Add', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),
                  // Total Wage Live Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                            : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Ironing Wage',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF064E3B),
                              ),
                            ),
                            Text(
                              '$_totalPieces pieces selected',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${_totalEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF10B981)),
                        ),
                      ],
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
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: (_totalEarnings <= 0 || _isSaving)
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            try {
                              final record = IroningRecord(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                workerId: widget.worker.id,
                                date: _selectedDate,
                                clothesCount: Map.fromEntries(
                                  _counts.entries.where((e) => e.value > 0),
                                ),
                                totalWage: _totalEarnings,
                                createdAt: DateTime.now(),
                              );

                              await context.read<EmployeeProvider>().saveIroningRecord(widget.worker.id, record);

                              if (context.mounted) {
                                Navigator.pop(context);
                                widget.onSaved();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Recorded $_totalPieces clothes (₹${_totalEarnings.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  SnackBar(content: Text('Failed to save record: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Clothes Record', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String type, int current, ValueChanged<int> onChanged, bool isDark) {
    final rate = _rates[type] ?? 0.0;
    final color = _getClothTypeColor(type);
    final icon = _getClothTypeIcon(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: current > 0 ? color.withAlpha(isDark ? 100 : 70) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: current > 0 ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withAlpha(isDark ? 40 : 25),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Rate: ₹${rate.toStringAsFixed(0)} / pc',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                ),
                icon: Icon(Icons.remove_rounded, size: 16, color: current > 0 ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.grey),
                onPressed: current > 0 ? () => onChanged(current - 1) : null,
              ),
              Container(
                width: 34,
                alignment: Alignment.center,
                child: Text(
                  '$current',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: current > 0 ? const Color(0xFF10B981) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                onPressed: () => onChanged(current + 1),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ClothesLogsTab extends StatelessWidget {
  final String workerId;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  const _ClothesLogsTab({
    required this.workerId,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<IroningRecord>>(
      future: context.watch<EmployeeProvider>().getIroningRecords(workerId),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.checkroom_rounded, size: 36, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  const SizedBox(height: 8),
                  Text(
                    'No clothes records found.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add Clothes Given" above to log laundry.',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        }

        records.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final rec = records[index];

            int totalPcs = 0;
            rec.clothesCount.forEach((_, c) => totalPcs += c);

            final chips = rec.clothesCount.entries.map((e) {
              final color = _getClothTypeColor(e.key);
              final icon = _getClothTypeIcon(e.key);
              return Container(
                margin: const EdgeInsets.only(right: 5, top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 30 : 18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withAlpha(isDark ? 70 : 45), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      '${e.value} ${e.key}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
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
                              color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.checkroom_rounded, color: Color(0xFF10B981), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${rec.totalWage.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$totalPcs pcs',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('EEE, d MMM yyyy').format(rec.date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(children: chips),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentLogsTab extends StatelessWidget {
  final String workerId;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  const _PaymentLogsTab({
    required this.workerId,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<IroningPayment>>(
      future: context.watch<EmployeeProvider>().getIroningPayments(workerId),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.payments_rounded, size: 36, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  const SizedBox(height: 8),
                  Text(
                    'No ironing payments recorded.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Record Payment" to log paid money.',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        }

        payments.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final pay = payments[index];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
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
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${pay.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (pay.description.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pay.description,
                                  style: const TextStyle(
                                    color: Color(0xFFD97706),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, d MMM yyyy').format(pay.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

IconData _getClothTypeIcon(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('small')) {
    return Icons.style_rounded;
  } else if (lower.contains('medium')) {
    return Icons.checkroom_rounded;
  } else if (lower.contains('large') && !lower.contains('extra') && !lower.contains('xl')) {
    return Icons.dry_cleaning_rounded;
  } else if (lower.contains('xl') || lower.contains('extra')) {
    return Icons.layers_rounded;
  } else if (lower.contains('shirt')) {
    return Icons.checkroom_rounded;
  } else if (lower.contains('pant')) {
    return Icons.dry_cleaning_rounded;
  } else if (lower.contains('saree')) {
    return Icons.texture_rounded;
  } else if (lower.contains('others')) {
    return Icons.local_laundry_service_rounded;
  }
  return Icons.shopping_bag_rounded;
}

Color _getClothTypeColor(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('small')) {
    return const Color(0xFF0D9488); // Teal
  } else if (lower.contains('medium')) {
    return const Color(0xFF0284C7); // Sky Blue
  } else if (lower.contains('large') && !lower.contains('extra') && !lower.contains('xl')) {
    return const Color(0xFFD97706); // Warm Sunset Amber
  } else if (lower.contains('xl') || lower.contains('extra')) {
    return const Color(0xFFE11D48); // Rose / Coral
  } else if (lower.contains('shirt')) {
    return const Color(0xFF0284C7); // Sky Blue
  } else if (lower.contains('pant')) {
    return const Color(0xFF475569); // Slate
  } else if (lower.contains('saree')) {
    return const Color(0xFFDB2777); // Pink
  } else if (lower.contains('others')) {
    return const Color(0xFF10B981); // Emerald
  }
  return const Color(0xFFF59E0B);
}
