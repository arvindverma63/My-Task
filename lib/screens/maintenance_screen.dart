import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/appliance_model.dart';
import '../providers/appliance_provider.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  IconData _getApplianceIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('ac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('fridge') || lower.contains('refrigerator')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('wash') || lower.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    } else if (lower.contains('tv') || lower.contains('television')) {
      return Icons.tv_rounded;
    } else if (lower.contains('purifier') || lower.contains('water') || lower.contains('ro')) {
      return Icons.water_drop_rounded;
    } else if (lower.contains('microwave') || lower.contains('oven')) {
      return Icons.microwave_rounded;
    } else if (lower.contains('geyser') || lower.contains('heater')) {
      return Icons.hot_tub_rounded;
    } else if (lower.contains('iron')) {
      return Icons.iron_rounded;
    } else if (lower.contains('vacuum') || lower.contains('cleaner')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.devices_other_rounded;
  }

  Widget _buildWarrantyBadge(DateTime? start, DateTime? end, bool isDark) {
    if (end == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              'No Warranty',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final isExpired = now.isAfter(end);

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x28EF4444) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? const Color(0x55EF4444) : const Color(0x44EF4444), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, size: 11, color: Color(0xFFEF4444)),
            SizedBox(width: 4),
            Text(
              'Expired',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
          ],
        ),
      );
    }

    final daysRemaining = end.difference(now).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0x5510B981) : const Color(0x4410B981), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            'Active (${daysRemaining}d left)',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildServicingSummaryTag(int recordCount, double totalCost, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x280D9488) : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0x550D9488) : const Color(0x440D9488), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.handyman_rounded, size: 11, color: Color(0xFF0D9488)),
          const SizedBox(width: 4),
          Text(
            '$recordCount logs • ₹${totalCost.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 35 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStats(ApplianceProvider provider) async {
    final appliances = provider.appliances;
    int activeWarranty = 0;
    double totalCost = 0.0;

    final now = DateTime.now();
    for (final app in appliances) {
      if (app.warrantyEnd != null && app.warrantyEnd!.isAfter(now)) {
        activeWarranty++;
      }
      final records = await provider.getServiceRecords(app.id);
      totalCost += records.fold<double>(0.0, (sum, r) => sum + r.price);
    }

    return {
      'activeWarranty': activeWarranty,
      'totalCost': totalCost,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplianceProvider>();
    final appliances = provider.appliances;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStats(provider),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data ?? {
          'activeWarranty': 0,
          'totalCost': 0.0,
        };

        final int activeWarrantyCount = stats['activeWarranty'] as int;
        final double totalCostSum = stats['totalCost'] as double;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Header Banner
              SafeArea(
                bottom: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF042F2E), const Color(0xFF134E4A)]
                          : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0D9488) : const Color(0xFF99F6E4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 6),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withAlpha(80),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.devices_other_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Appliances Hub',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF042F2E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withAlpha(isDark ? 60 : 30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${appliances.length} items',
                                    style: const TextStyle(
                                      color: Color(0xFF0D9488),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Warranties, bills & service history',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _showAddApplianceDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withAlpha(50),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withAlpha(80),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 15, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Add Asset',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                    letterSpacing: 0.2,
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
              ),

              // 2. High-Fidelity Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    _buildStatCard('Total Assets', '${appliances.length}', Icons.devices_other_rounded, const Color(0xFF3B82F6), isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Active Warranty', '$activeWarrantyCount', Icons.shield_outlined, const Color(0xFF10B981), isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Service Expense', '₹${totalCostSum.toStringAsFixed(0)}', Icons.handyman_outlined, const Color(0xFFF59E0B), isDark),
                  ],
                ),
              ),

              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    child: LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // 3. List of Appliances
              Expanded(
                child: appliances.isEmpty
                    ? Center(
                        child: provider.isLoading
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 2.8,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Loading appliances from cloud...',
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
                                    Icon(Icons.devices_other_rounded, size: 54, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Appliances Registered',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add home appliances, warranties, and purchase bills to track repairs.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D9488),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                      ),
                                      onPressed: () => _showAddApplianceDialog(context),
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      label: const Text('Add First Appliance', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF0D9488),
                        onRefresh: () => provider.loadAppliances(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          itemCount: appliances.length,
                          itemBuilder: (context, index) {
                            final appliance = appliances[index];
                            return FutureBuilder<List<ServiceRecord>>(
                              future: provider.getServiceRecords(appliance.id),
                              builder: (context, snapshot) {
                                final records = snapshot.data ?? [];
                                final totalCost = records.fold<double>(0.0, (sum, r) => sum + r.price);

                                Color statusColor = const Color(0xFF94A3B8);
                                if (appliance.warrantyEnd != null) {
                                  statusColor = DateTime.now().isAfter(appliance.warrantyEnd!)
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981);
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
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
                                  clipBehavior: Clip.antiAlias,
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Colored Left Border Strip
                                        Container(
                                          width: 4,
                                          color: statusColor,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ApplianceServiceDetailScreen(appliance: appliance),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0D9488).withAlpha(isDark ? 40 : 20),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: const Color(0xFF0D9488).withAlpha(isDark ? 80 : 40)),
                                                    ),
                                                    child: Icon(
                                                      _getApplianceIcon(appliance.type.isNotEmpty ? appliance.type : appliance.name),
                                                      color: const Color(0xFF0D9488),
                                                      size: 19,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          appliance.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 1),
                                                        Text(
                                                          '${appliance.brand} • ${appliance.type}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Wrap(
                                                          spacing: 5,
                                                          runSpacing: 3,
                                                          children: [
                                                            _buildWarrantyBadge(appliance.warrantyStart, appliance.warrantyEnd, isDark),
                                                            _buildServicingSummaryTag(records.length, totalCost, isDark),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                    size: 18,
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
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hintText,
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

  void _showAddApplianceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final brandController = TextEditingController();
    final serialController = TextEditingController();
    DateTime? warrantyStart;
    DateTime? warrantyEnd;
    String? invoicePath;
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presetTypes = ['Air Conditioner', 'Refrigerator', 'Washing Machine', 'Water Purifier', 'Geyser', 'Microwave', 'TV'];

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
                              ? [const Color(0xFF042F2E), const Color(0xFF134E4A)]
                              : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                        ),
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF0D9488) : const Color(0xFF99F6E4))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF0D9488),
                            child: const Icon(Icons.add_to_photos_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Register New Appliance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF042F2E),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogInputField(
                            context: context,
                            controller: nameController,
                            label: 'Appliance Name',
                            prefixIcon: Icons.devices_other_rounded,
                            hintText: 'e.g. Living Room AC, Kitchen Fridge',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter appliance name' : null,
                          ),
                          const SizedBox(height: 10),
                          _buildDialogInputField(
                            context: context,
                            controller: typeController,
                            label: 'Appliance Type / Category',
                            prefixIcon: Icons.category_rounded,
                            hintText: 'e.g. Air Conditioner, Refrigerator',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter type' : null,
                          ),
                          const SizedBox(height: 6),
                          // Preset Type Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetTypes.map((type) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(type, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onPressed: () {
                                      typeController.text = type;
                                      if (nameController.text.trim().isEmpty) {
                                        nameController.text = type;
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInputField(
                                  context: context,
                                  controller: brandController,
                                  label: 'Brand',
                                  prefixIcon: Icons.branding_watermark_rounded,
                                  hintText: 'e.g. LG, Daikin',
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDialogInputField(
                                  context: context,
                                  controller: serialController,
                                  label: 'Serial Number',
                                  prefixIcon: Icons.numbers_rounded,
                                  hintText: 'Optional',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Warranty Date Pickers Row
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) setDlgState(() => warrantyStart = date);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF0D9488)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            warrantyStart == null
                                                ? 'Warranty Start'
                                                : DateFormat('dd/MM/yyyy').format(warrantyStart!),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) setDlgState(() => warrantyEnd = date);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF0D9488)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            warrantyEnd == null
                                                ? 'Warranty End'
                                                : DateFormat('dd/MM/yyyy').format(warrantyEnd!),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Invoice Photo Picker
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setDlgState(() => invoicePath = image.path);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: invoicePath == null
                                    ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                                    : (isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5)),
                                border: Border.all(
                                  color: invoicePath == null
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                      : const Color(0xFF10B981),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    invoicePath == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
                                    color: invoicePath == null ? const Color(0xFF0D9488) : const Color(0xFF10B981),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    invoicePath == null ? 'Attach Purchase Receipt / Bill' : 'Invoice Attached',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: invoicePath == null ? const Color(0xFF0D9488) : const Color(0xFF059669),
                                      fontSize: 12,
                                    ),
                                  ),
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
                            onPressed: () => Navigator.pop(context),
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
                                      final appliance = Appliance(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        name: nameController.text.trim(),
                                        type: typeController.text.trim(),
                                        brand: brandController.text.trim(),
                                        serialNumber: serialController.text.trim(),
                                        warrantyStart: warrantyStart,
                                        warrantyEnd: warrantyEnd,
                                        invoicePath: invoicePath,
                                        createdAt: DateTime.now(),
                                      );
                                      await context.read<ApplianceProvider>().addAppliance(appliance);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Appliance "${appliance.name}" registered!'),
                                            backgroundColor: const Color(0xFF059669),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to add appliance: $e'), backgroundColor: Colors.redAccent),
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
                                : const Text('Register Appliance', style: TextStyle(fontWeight: FontWeight.bold)),
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

class ApplianceServiceDetailScreen extends StatefulWidget {
  final Appliance appliance;
  const ApplianceServiceDetailScreen({super.key, required this.appliance});

  @override
  State<ApplianceServiceDetailScreen> createState() => _ApplianceServiceDetailScreenState();
}

class _ApplianceServiceDetailScreenState extends State<ApplianceServiceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplianceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final applianceIndex = provider.appliances.indexWhere((a) => a.id == widget.appliance.id);
    final appliance = applianceIndex >= 0 ? provider.appliances[applianceIndex] : widget.appliance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          appliance.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            tooltip: 'Remove Appliance',
            onPressed: () => _confirmDeleteAppliance(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              height: 40,
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
                indicator: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withAlpha(80),
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
                        Icon(Icons.handyman_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Service Logs'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Warranty & Specs'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (provider.isLoading)
            const ClipRRect(
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<ServiceRecord>>(
              future: provider.getServiceRecords(appliance.id),
              builder: (context, snapshot) {
                final records = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildServiceLogsTab(records, isDark),
                    _buildOverviewTab(appliance, isDark),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Appliance appliance, bool isDark) {
    final now = DateTime.now();
    final bool hasWarranty = appliance.warrantyStart != null && appliance.warrantyEnd != null;
    final bool isExpired = hasWarranty && now.isAfter(appliance.warrantyEnd!);
    final daysRemaining = hasWarranty && !isExpired ? appliance.warrantyEnd!.difference(now).inDays : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Specifications Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withAlpha(isDark ? 40 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.devices_other_rounded, color: Color(0xFF0D9488), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Device Specifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Divider(height: 18, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildSpecRow('Brand Name', appliance.brand, isDark),
                _buildSpecRow('Model / Type', appliance.type, isDark),
                _buildSpecRow('Serial Number', appliance.serialNumber.isNotEmpty ? appliance.serialNumber : 'Not logged', isDark),
                _buildSpecRow('Registered On', DateFormat('dd MMM yyyy').format(appliance.createdAt), isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Warranty Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !hasWarranty
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                    : (isExpired ? const Color(0xFFEF4444).withAlpha(80) : const Color(0xFF10B981).withAlpha(80)),
                width: 1.2,
              ),
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
                            color: (!hasWarranty
                                    ? Colors.grey
                                    : (isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981)))
                                .withAlpha(isDark ? 40 : 20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shield_rounded,
                            color: !hasWarranty
                                ? Colors.grey
                                : (isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warranty Coverage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    _buildWarrantyStatusBadge(hasWarranty, isExpired, daysRemaining, isDark),
                  ],
                ),
                Divider(height: 18, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                if (hasWarranty) ...[
                  _buildSpecRow(
                    'Warranty Period',
                    '${DateFormat('dd MMM yyyy').format(appliance.warrantyStart!)} → ${DateFormat('dd MMM yyyy').format(appliance.warrantyEnd!)}',
                    isDark,
                  ),
                  _buildSpecRow(
                    'Coverage Status',
                    isExpired ? 'Expired' : '$daysRemaining Days remaining',
                    isDark,
                    isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        'No warranty period logged for this appliance.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Purchase Invoice Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Purchase Invoice / Receipt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Divider(height: 18, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                if (appliance.invoicePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        GestureDetector(
                          onTap: () => _viewInvoicePhoto(context, appliance.invoicePath!),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.black12,
                            child: appliance.invoicePath!.startsWith('uploads/')
                                ? Image.network(
                                    'https://slateblue-guanaco-751834.hostingersite.com/${appliance.invoicePath!}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                    ),
                                  )
                                : Image.file(
                                    File(appliance.invoicePath!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: Colors.black.withAlpha(160),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Tap to view full receipt image',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 38),
                    ),
                    onPressed: () => _pickInvoicePhoto(appliance),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Replace Receipt Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  InkWell(
                    onTap: () => _pickInvoicePhoto(appliance),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF0D9488).withAlpha(100),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? const Color(0x180D9488) : const Color(0xFFF0FDFA),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.upload_file_rounded, color: Color(0xFF0D9488), size: 28),
                          const SizedBox(height: 6),
                          const Text(
                            'Upload Purchase Bill / Warranty Slip',
                            style: TextStyle(
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Secure image for warranty claims and insurance',
                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyStatusBadge(bool hasWarranty, bool isExpired, int daysRemaining, bool isDark) {
    if (!hasWarranty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('No Warranty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      );
    }
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x28EF4444) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x55EF4444)),
        ),
        child: const Text('Expired', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x5510B981)),
      ),
      child: Text('Active ($daysRemaining d left)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
    );
  }

  Future<void> _pickInvoicePhoto(Appliance appliance) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      final updatedAppliance = Appliance(
        id: appliance.id,
        name: appliance.name,
        type: appliance.type,
        brand: appliance.brand,
        serialNumber: appliance.serialNumber,
        warrantyStart: appliance.warrantyStart,
        warrantyEnd: appliance.warrantyEnd,
        invoicePath: image.path,
        createdAt: appliance.createdAt,
      );
      final messenger = ScaffoldMessenger.of(context);
      await context.read<ApplianceProvider>().addAppliance(updatedAppliance);
      messenger.showSnackBar(
        const SnackBar(content: Text('Purchase receipt uploaded successfully'), backgroundColor: Color(0xFF059669)),
      );
    }
  }

  void _viewInvoicePhoto(BuildContext context, String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Purchase Receipt / Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: path.startsWith('uploads/')
                      ? Image.network(
                          'https://slateblue-guanaco-751834.hostingersite.com/$path',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                          ),
                        )
                      : Image.file(
                          File(path),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceLogsTab(List<ServiceRecord> records, bool isDark) {
    final totalCost = records.fold<double>(0.0, (sum, r) => sum + r.price);
    final provider = context.read<ApplianceProvider>();

    return Column(
      children: [
        // Servicing Summary Banner
        Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF042F2E), const Color(0xFF134E4A)]
                  : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF0D9488) : const Color(0xFF99F6E4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Servicing Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  const SizedBox(height: 2),
                  Text('${records.length} total visits logged', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Repair Expense', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(height: 1),
                  Text('₹${totalCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                ],
              ),
            ],
          ),
        ),
        // Add Log Button Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Logs Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(36, 32),
                ),
                onPressed: () => _showAddServiceLogDialog(context),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Add Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: records.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handyman_rounded, size: 36, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 8),
                        Text(
                          'No service logs registered yet.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add Log" to record maintenance or repairs.',
                          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final log = records[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                              if (index < records.length - 1)
                                Container(
                                  width: 1.5,
                                  height: 60,
                                  color: const Color(0xFF0D9488).withAlpha(50),
                                ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
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
                                      Text(
                                        '₹${log.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D9488)),
                                      ),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(log.serviceDate),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  if (log.remarks.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      log.remarks,
                                      style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (log.billPath != null)
                                        InkWell(
                                          onTap: () => _viewBillPhoto(context, log.billPath!),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488).withAlpha(isDark ? 30 : 15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.receipt_rounded, size: 12, color: Color(0xFF0D9488)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'View Bill',
                                                  style: TextStyle(fontSize: 10.5, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox.shrink(),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                        onPressed: () async {
                                          await provider.deleteServiceRecord(log.id);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteAppliance(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Appliance?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will delete the appliance and its full service log history permanently.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await context.read<ApplianceProvider>().deleteAppliance(widget.appliance.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceLogDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    final remarksController = TextEditingController();
    DateTime serviceDate = DateTime.now();
    String? billPath;
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presetPrices = [300, 500, 1000, 2000];
    final presetRemarks = ['Routine Servicing', 'Gas Refill', 'Filter Replacement', 'Motor Repair'];

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
                              ? [const Color(0xFF042F2E), const Color(0xFF134E4A)]
                              : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                        ),
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF0D9488) : const Color(0xFF99F6E4))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF0D9488),
                            child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Service Log',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF042F2E),
                                  ),
                                ),
                                Text(
                                  'Appliance: ${widget.appliance.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
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
                          TextFormField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Enter service cost' : null,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              labelText: 'Service / Repair Cost (₹)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF0D9488), size: 18),
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
                          // Preset Cost Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetPrices.map((amt) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text('+₹$amt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onPressed: () {
                                      final current = double.tryParse(priceController.text) ?? 0;
                                      priceController.text = (current + amt).toStringAsFixed(0);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: remarksController,
                            maxLines: 2,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              labelText: 'Work Description / Remarks',
                              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D9488), size: 18),
                              hintText: 'e.g. Filter cleaning, PCB replacement...',
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
                          // Preset Remark Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetRemarks.map((remark) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(remark, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onPressed: () {
                                      remarksController.text = remark;
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Service Date Picker
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: serviceDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setDlgState(() => serviceDate = date);
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
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D9488)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Date: ${DateFormat('dd MMMM yyyy').format(serviceDate)}',
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
                          const SizedBox(height: 12),
                          // Bill Photo Upload
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setDlgState(() => billPath = image.path);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: billPath == null
                                    ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                                    : (isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5)),
                                border: Border.all(
                                  color: billPath == null
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                      : const Color(0xFF10B981),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    billPath == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
                                    color: billPath == null ? const Color(0xFF0D9488) : const Color(0xFF10B981),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    billPath == null ? 'Attach Service Bill Receipt' : 'Service Bill Attached',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: billPath == null ? const Color(0xFF0D9488) : const Color(0xFF059669),
                                      fontSize: 12,
                                    ),
                                  ),
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
                            onPressed: () => Navigator.pop(context),
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
                                      final price = double.parse(priceController.text);
                                      final record = ServiceRecord(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        applianceId: widget.appliance.id,
                                        serviceDate: serviceDate,
                                        price: price,
                                        remarks: remarksController.text.trim(),
                                        billPath: billPath,
                                        createdAt: DateTime.now(),
                                      );
                                      await context.read<ApplianceProvider>().addServiceRecord(record);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                                const SizedBox(width: 8),
                                                Text('Service log of ₹${price.toStringAsFixed(0)} recorded', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                          SnackBar(content: Text('Failed to add service record: $e'), backgroundColor: Colors.redAccent),
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
                                : const Text('Save Service Log', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _viewBillPhoto(BuildContext context, String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Service Bill Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: path.startsWith('uploads/')
                      ? Image.network(
                          'https://slateblue-guanaco-751834.hostingersite.com/$path',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                          ),
                        )
                      : Image.file(
                          File(path),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
