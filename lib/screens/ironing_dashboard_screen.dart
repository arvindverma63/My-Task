import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final workers = employeeProvider.ironingWorkers;
    final colorScheme = Theme.of(context).colorScheme;

    if (_selectedWorkerId == null || !workers.any((w) => w.id == _selectedWorkerId)) {
      if (workers.isNotEmpty) {
        _selectedWorkerId = workers.first.id;
      }
    }

    final selectedWorker = workers.isNotEmpty
        ? workers.firstWhere((w) => w.id == _selectedWorkerId)
        : null;

    final mainHeaderCard = SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0x1E3F51B5), // Indigo 12% alpha
              Color(0x0A3F51B5), // Indigo 4% alpha
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x333F51B5), width: 1.5), // 20% alpha border
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.iron_rounded, color: Color(0xFF3F51B5), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Ironing Registry',
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
                    'Track clothes count, rates, and payments',
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
                if (selectedWorker != null) ...[
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x11FF0000),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_remove_rounded, size: 20),
                    tooltip: 'Delete Selected Worker',
                    onPressed: () => _confirmDeleteWorker(context, selectedWorker),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  tooltip: 'Add Worker',
                  onPressed: () => _showAddWorkerDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: null,
      body: selectedWorker == null
          ? Column(
              children: [
                mainHeaderCard,
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.iron_rounded, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          const Text(
                            'No Ironing Workers Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please add a worker to manage clothes and payments.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _buildWorkerSelector(workers, selectedWorker, colorScheme),
                      const SizedBox(height: 16),
                      _buildWorkerSummaryHeader(selectedWorker, colorScheme),
                      const SizedBox(height: 16),
                      _buildRateCardSection(selectedWorker, colorScheme),
                      const SizedBox(height: 16),
                      _buildActionRow(selectedWorker, colorScheme),
                      const SizedBox(height: 20),
                      TabBar(
                        controller: _tabController,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: colorScheme.primary,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(icon: Icon(Icons.iron_rounded), text: 'Clothes Logs'),
                          Tab(icon: Icon(Icons.payments_rounded), text: 'Payment Logs'),
                        ],
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _ClothesLogsTab(workerId: selectedWorker.id),
                            _PaymentLogsTab(workerId: selectedWorker.id),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWorkerSelector(List<IroningWorker> workers, IroningWorker selected, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            selected.name[0].toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: const Text('Active Ironing Worker', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        subtitle: Text(
          selected.name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        trailing: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
        onTap: () => _showWorkerSelectionSheet(context, workers, selected),
      ),
    );
  }

  void _showWorkerSelectionSheet(BuildContext context, List<IroningWorker> workers, IroningWorker selected) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      color: colorScheme.outlineVariant.withAlpha(120),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Select Ironing Worker',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final w = workers[index];
                      final isSelected = w.id == selected.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          child: Text(
                            w.name[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          w.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: w.contact.isNotEmpty ? Text(w.contact) : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedWorkerId = w.id;
                          });
                          Navigator.pop(context);
                        },
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
  }

  Widget _buildWorkerSummaryHeader(IroningWorker worker, ColorScheme colorScheme) {
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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, Colors.deepPurple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'EARNED',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$totalClothes pcs',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'PAID',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalPaid.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${payments.length} payments',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'BALANCE',
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: balance >= 0 ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      balance >= 0 ? 'Pending' : 'Overpaid',
                      style: TextStyle(
                        color: balance >= 0 ? const Color(0xFFA5D6A7).withAlpha(200) : const Color(0xFFEF9A9A).withAlpha(200),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildRateCardSection(IroningWorker worker, ColorScheme colorScheme) {
    return FutureBuilder<List<IronRate>>(
      future: context.read<EmployeeProvider>().getIronRates(worker.id),
      builder: (context, snapshot) {
        final ratesList = snapshot.data ?? [];
        final Map<String, double> ratesMap = {
          'Shirt': 5.0,
          'Pant': 5.0,
          'Saree': 10.0,
          'Others': 5.0,
        };
        for (final rate in ratesList) {
          final typeRates = ratesList.where((r) => r.clothingType == rate.clothingType).toList();
          typeRates.sort((a, b) => b.date.compareTo(a.date));
          ratesMap[rate.clothingType] = typeRates.first.rate;
        }

        return Card(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ironing Rates Card',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Edit Rates', style: TextStyle(fontSize: 12)),
                      onPressed: () => _showEditRatesDialog(
                        context,
                        worker,
                        ratesMap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ratesMap.entries.map((e) => _buildRateIndicator(e.key, e.value, colorScheme)).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateIndicator(String label, double rate, ColorScheme colorScheme) {
    final color = _getClothTypeColor(label);
    final icon = _getClothTypeIcon(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withAlpha(25),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${rate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IroningWorker worker, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showAddClothesDialog(context, worker),
              icon: const Icon(Icons.iron_rounded, size: 20),
              label: const Text('Add Clothes Given', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showAddPaymentDialog(context, worker),
              icon: const Icon(Icons.payments_rounded, size: 20),
              label: const Text('Pay for Ironing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      color: colorScheme.primary.withAlpha(20),
                      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: colorScheme.primary.withAlpha(30),
                          child: Icon(Icons.person_add_alt_1_rounded, color: colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add Ironing Worker',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                          controller: nameController,
                          label: 'Name',
                          prefixIcon: Icons.badge_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildDialogInputField(
                          context: context,
                          controller: contactController,
                          label: 'Contact Phone (Optional)',
                          prefixIcon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: null, // Optional, can be any length or empty
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
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
                            }
                          },
                          child: const Text('Add Worker'),
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

  void _confirmDeleteWorker(BuildContext context, IroningWorker worker) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remove Worker?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Are you sure you want to remove ${worker.name}? This will delete all their ironing logs.'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await context.read<EmployeeProvider>().deleteIroningWorker(worker.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _selectedWorkerId = null;
                        });
                      }
                    },
                    child: const Text('Remove'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showEditRatesDialog(BuildContext context, IroningWorker worker, Map<String, double> current) {
    final formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> controllers = {};
    current.forEach((key, val) {
      controllers[key] = TextEditingController(text: val.toStringAsFixed(0));
    });
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        bool showAddForm = false;
        final nameController = TextEditingController();
        final rateController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDlgState) => Dialog(
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
                          color: colorScheme.primary.withAlpha(20),
                          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.primary.withAlpha(30),
                              child: Icon(Icons.edit_rounded, color: colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Edit Ironing Rates',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            ...controllers.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildDialogInputField(
                                context: context,
                                controller: entry.value,
                                label: '${entry.key} Rate (₹)',
                                prefixIcon: Icons.currency_rupee_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) < 0 ? 'Enter valid rate' : null,
                              ),
                            )),
                            
                            const SizedBox(height: 8),
                            if (!showAddForm)
                              OutlinedButton.icon(
                                onPressed: () => setDlgState(() => showAddForm = true),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Custom Rate Type'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withAlpha(40),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('New Rate Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              labelText: 'Cloth Name',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller: rateController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              labelText: 'Rate',
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => setDlgState(() {
                                            nameController.clear();
                                            rateController.clear();
                                            showAddForm = false;
                                          }),
                                          child: const Text('Cancel'),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton(
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
                                          child: const Text('Add'),
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
                                }
                              },
                              child: const Text('Save Rates'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
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
                          const Expanded(
                            child: Text(
                              'Pay for Ironing',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            label: 'Amount Paid (₹)',
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Enter valid positive amount' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildDialogInputField(
                            context: context,
                            controller: descController,
                            label: 'Remarks / Notes',
                            prefixIcon: Icons.description_rounded,
                            hintText: 'e.g. Paid weekly wage',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
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
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                                border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Date: ${paymentDate.day}/${paymentDate.month}/${paymentDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
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
                              final payment = IroningPayment(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                workerId: worker.id,
                                date: paymentDate,
                                amount: amount,
                                description: descController.text.trim(),
                                createdAt: DateTime.now(),
                              );
                              await context.read<EmployeeProvider>().saveIroningPayment(worker.id, payment);
                              if (context.mounted) {
                                Navigator.pop(context);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Paid ₹$amount to ${worker.name}'),
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
          'Shirt': 0,
          'Pant': 0,
          'Saree': 0,
          'Others': 0,
        };
        _rates = {
          'Shirt': 5.0,
          'Pant': 5.0,
          'Saree': 10.0,
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



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green.withAlpha(30),
                  child: const Icon(Icons.iron_rounded, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Record Clothes Given',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(80),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dynamic counter list
                ..._counts.keys.map((type) => Column(
                  children: [
                    _buildCounterRow(type, _counts[type] ?? 0, (val) {
                      setState(() => _counts[type] = val);
                    }, colorScheme),
                    const SizedBox(height: 8),
                  ],
                )),
                
                const SizedBox(height: 8),
                
                // Add custom form or button
                if (!_showAddCustomForm)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showAddCustomForm = true),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Custom Cloth Type'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: BorderSide(color: colorScheme.primary.withAlpha(120)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Cloth Type',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _customNameController,
                                decoration: InputDecoration(
                                  labelText: 'Cloth Name',
                                  hintText: 'e.g. Kurta',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _customRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Rate (₹)',
                                  hintText: 'e.g. 8',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Wage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '₹${_totalEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green),
                      ),
                    ],
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _totalEarnings <= 0
                      ? null
                      : () async {
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
                              const SnackBar(
                                content: Text('Recorded clothes successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: const Text('Save Record'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String type, int current, ValueChanged<int> onChanged, ColorScheme colorScheme) {
    final rate = _rates[type] ?? 0.0;
    final color = _getClothTypeColor(type);
    final icon = _getClothTypeIcon(type);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(20),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Rate: ₹${rate.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: current > 0 ? () => onChanged(current - 1) : null,
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '$current',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
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
  const _ClothesLogsTab({required this.workerId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<IroningRecord>>(
      future: context.watch<EmployeeProvider>().getIroningRecords(workerId),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(
            child: Text(
              'No clothes records found.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        records.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final rec = records[index];

            final chips = rec.clothesCount.entries.map((e) {
              final color = _getClothTypeColor(e.key);
              final icon = _getClothTypeIcon(e.key);
              return Container(
                margin: const EdgeInsets.only(right: 6, top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(60), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      '${e.value} ${e.key}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withAlpha(20),
                  child: const Icon(Icons.iron_rounded, color: Colors.green),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${rec.totalWage.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      '${rec.date.day}/${rec.date.month}/${rec.date.year}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant.withAlpha(180)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    children: chips,
                  ),
                ),
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
  const _PaymentLogsTab({required this.workerId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<IroningPayment>>(
      future: context.watch<EmployeeProvider>().getIroningPayments(workerId),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return const Center(
            child: Text(
              'No ironing payments recorded.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        payments.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final pay = payments[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.withAlpha(20),
                  child: Icon(Icons.currency_rupee_rounded, color: Colors.amber[800]),
                ),
                title: Text(
                  '₹${pay.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${pay.date.day}/${pay.date.month}/${pay.date.year}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (pay.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        pay.description,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

IconData _getClothTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'shirt':
      return Icons.checkroom_rounded;
    case 'pant':
      return Icons.dry_cleaning_rounded;
    case 'saree':
      return Icons.texture_rounded;
    case 'others':
      return Icons.local_laundry_service_rounded;
    default:
      return Icons.shopping_bag_rounded;
  }
}

Color _getClothTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'shirt':
      return Colors.blue;
    case 'pant':
      return Colors.indigo;
    case 'saree':
      return Colors.pink;
    case 'others':
      return Colors.purple;
    default:
      return Colors.teal;
  }
}
