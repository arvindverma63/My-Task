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
  String _selectedFilter = 'all'; // 'all', 'appliance', 'service'

  bool _isServiceItem(Appliance item) {
    final text = '${item.type} ${item.name} ${item.brand}'.toLowerCase();
    return text.contains('gas') ||
        text.contains('cylinder') ||
        text.contains('lpg') ||
        text.contains('indane') ||
        text.contains('bharat') ||
        text.contains('hp gas') ||
        text.contains('water') ||
        text.contains('can') ||
        text.contains('delivery') ||
        text.contains('service') ||
        text.contains('utility') ||
        text.contains('refill') ||
        text.contains('booking') ||
        text.contains('pest') ||
        text.contains('wifi') ||
        text.contains('wi-fi') ||
        text.contains('internet') ||
        text.contains('broadband') ||
        text.contains('plumb') ||
        text.contains('electric') ||
        text.contains('maid') ||
        text.contains('vendor') ||
        text.contains('agency') ||
        text.contains('cleaning');
  }

  IconData _getApplianceIcon(String type, [String? name]) {
    final lower = '$type ${name ?? ''}'.toLowerCase();
    if (lower.contains('gas') || lower.contains('cylinder') || lower.contains('lpg') || lower.contains('indane') || lower.contains('bharat') || lower.contains('hp gas')) {
      return Icons.propane_tank_rounded;
    } else if (lower.contains('water') || lower.contains('purifier') || lower.contains('ro') || lower.contains('aquaguard') || lower.contains('bisleri')) {
      return Icons.water_drop_rounded;
    } else if (lower.contains('pest') || lower.contains('termite') || lower.contains('bedbug') || lower.contains('cockroach')) {
      return Icons.pest_control_rounded;
    } else if (lower.contains('wifi') || lower.contains('wi-fi') || lower.contains('internet') || lower.contains('broadband') || lower.contains('router')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('plumb') || lower.contains('pipe') || lower.contains('tap') || lower.contains('leak') || lower.contains('drain')) {
      return Icons.plumbing_rounded;
    } else if (lower.contains('electric') || lower.contains('wiring') || lower.contains('power') || lower.contains('switch')) {
      return Icons.electric_bolt_rounded;
    } else if (lower.contains('solar')) {
      return Icons.solar_power_rounded;
    } else if (lower.contains('battery') || lower.contains('inverter') || lower.contains('ups')) {
      return Icons.battery_charging_full_rounded;
    } else if (lower.contains('car') || lower.contains('bike') || lower.contains('vehicle')) {
      return Icons.directions_car_rounded;
    } else if (lower.contains('cctv') || lower.contains('camera') || lower.contains('security')) {
      return Icons.videocam_rounded;
    } else if (lower.contains('garden') || lower.contains('plant') || lower.contains('lawn')) {
      return Icons.yard_rounded;
    } else if (lower.contains('newspaper') || lower.contains('milk')) {
      return Icons.menu_book_rounded;
    } else if (lower.contains('garbage') || lower.contains('waste') || lower.contains('trash')) {
      return Icons.delete_sweep_rounded;
    } else if (lower.contains('carpenter') || lower.contains('furniture') || lower.contains('wood')) {
      return Icons.chair_rounded;
    } else if (lower.contains('paint') || lower.contains('wall')) {
      return Icons.format_paint_rounded;
    } else if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator_rounded;
    } else if (lower.contains('generator') || lower.contains('genset')) {
      return Icons.power_rounded;
    } else if (lower.contains('fan')) {
      return Icons.air_rounded;
    } else if (lower.contains('pump') || lower.contains('motor')) {
      return Icons.speed_rounded;
    } else if (lower.contains('dish')) {
      return Icons.countertops_rounded;
    } else if (lower.contains('sound') || lower.contains('theater') || lower.contains('audio')) {
      return Icons.speaker_rounded;
    } else if (lower.contains('ac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('fridge') || lower.contains('refrigerator')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('wash') || lower.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    } else if (lower.contains('tv') || lower.contains('television')) {
      return Icons.tv_rounded;
    } else if (lower.contains('microwave') || lower.contains('oven')) {
      return Icons.microwave_rounded;
    } else if (lower.contains('geyser') || lower.contains('heater')) {
      return Icons.hot_tub_rounded;
    } else if (lower.contains('iron')) {
      return Icons.iron_rounded;
    } else if (lower.contains('vacuum') || lower.contains('clean') || lower.contains('chimney')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.devices_other_rounded;
  }

  Widget _buildWarrantyBadge(DateTime? start, DateTime? end, bool isDark, {bool isService = false}) {
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
            Icon(isService ? Icons.check_circle_outline_rounded : Icons.shield_outlined, size: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              isService ? 'Active Service' : 'No Warranty',
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, size: 11, color: Color(0xFFEF4444)),
            const SizedBox(width: 4),
            Text(
              isService ? 'Refill Due / Expired' : 'Expired',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
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
            isService ? 'Valid (${daysRemaining}d left)' : 'Active (${daysRemaining}d left)',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildServicingSummaryTag(int recordCount, double totalCost, bool isDark, {bool isService = false}) {
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
          Icon(isService ? Icons.receipt_long_rounded : Icons.handyman_rounded, size: 11, color: const Color(0xFF0D9488)),
          const SizedBox(width: 4),
          Text(
            '$recordCount ${isService ? "orders" : "logs"} • ₹${totalCost.toStringAsFixed(0)}',
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

  Widget _buildFilterChip(String label, String value, IconData icon, bool isDark) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = value;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0D9488)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0D9488)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withAlpha(80),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    final int applianceCount = appliances.where((a) => !_isServiceItem(a)).length;
    final int serviceCount = appliances.where((a) => _isServiceItem(a)).length;

    final displayedAppliances = appliances.where((app) {
      if (_selectedFilter == 'appliance') {
        return !_isServiceItem(app);
      } else if (_selectedFilter == 'service') {
        return _isServiceItem(app);
      }
      return true;
    }).toList();

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
                        child: const Icon(Icons.propane_tank_rounded, color: Colors.white, size: 20),
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
                                    'Services & Assets',
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
                              'Gas, water, utilities & warranties',
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
                                  'Add Item',
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
                    _buildStatCard('Total Items', '${appliances.length}', Icons.devices_other_rounded, const Color(0xFF3B82F6), isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Active / Valid', '$activeWarrantyCount', Icons.shield_outlined, const Color(0xFF10B981), isDark),
                    const SizedBox(width: 8),
                    _buildStatCard('Total Expense', '₹${totalCostSum.toStringAsFixed(0)}', Icons.handyman_outlined, const Color(0xFFF59E0B), isDark),
                  ],
                ),
              ),

              // 3. Category Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('All (${appliances.length})', 'all', Icons.grid_view_rounded, isDark),
                    const SizedBox(width: 6),
                    _buildFilterChip('Appliances ($applianceCount)', 'appliance', Icons.devices_other_rounded, isDark),
                    const SizedBox(width: 6),
                    _buildFilterChip('Services ($serviceCount)', 'service', Icons.handyman_rounded, isDark),
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

              // 4. List of Appliances & Services
              Expanded(
                child: displayedAppliances.isEmpty
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
                                    'Loading data from cloud...',
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
                                    Icon(
                                      _selectedFilter == 'service'
                                          ? Icons.handyman_rounded
                                          : Icons.devices_other_rounded,
                                      size: 54,
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedFilter == 'service'
                                          ? 'No Services / Utilities Registered'
                                          : (_selectedFilter == 'appliance'
                                              ? 'No Appliances Registered'
                                              : 'No Items Registered'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add gas cylinder, water delivery, AC repairs, or home utilities to track refills and warranties.',
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
                                      label: const Text('Register Item', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          itemCount: displayedAppliances.length,
                          itemBuilder: (context, index) {
                            final appliance = displayedAppliances[index];
                            final isService = _isServiceItem(appliance);

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
                                } else if (isService) {
                                  statusColor = const Color(0xFF0D9488);
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
                                                      color: (isService ? const Color(0xFF0D9488) : const Color(0xFF3B82F6)).withAlpha(isDark ? 40 : 20),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: (isService ? const Color(0xFF0D9488) : const Color(0xFF3B82F6)).withAlpha(isDark ? 80 : 40)),
                                                    ),
                                                    child: Icon(
                                                      _getApplianceIcon(appliance.type.isNotEmpty ? appliance.type : appliance.name, appliance.name),
                                                      color: isService ? const Color(0xFF0D9488) : const Color(0xFF3B82F6),
                                                      size: 19,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                appliance.name,
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                              decoration: BoxDecoration(
                                                                color: (isService ? const Color(0xFF0D9488) : const Color(0xFF3B82F6)).withAlpha(isDark ? 35 : 18),
                                                                borderRadius: BorderRadius.circular(5),
                                                              ),
                                                              child: Text(
                                                                isService ? 'Service' : 'Appliance',
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: isService ? const Color(0xFF0D9488) : const Color(0xFF2563EB),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
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
                                                            _buildWarrantyBadge(appliance.warrantyStart, appliance.warrantyEnd, isDark, isService: isService),
                                                            _buildServicingSummaryTag(records.length, totalCost, isDark, isService: isService),
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

  void _showCategorySearchSheet(
    BuildContext context, {
    required bool isService,
    required String? selectedCategory,
    required void Function(String category, bool isCustom) onCategorySelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, String>> categories = isService
        ? [
            {'name': 'Gas Cylinder Refill', 'desc': 'LPG Refill (Indane, Bharat, HP Gas)', 'keywords': 'gas cylinder lpg fuel kitchen indane bharat hp'},
            {'name': 'Drinking Water Delivery', 'desc': '20L Water Cans, Bisleri, Kinley, RO Jar', 'keywords': 'water can jar bisleri mineral bottle 20l delivery'},
            {'name': 'RO Water Purifier Service', 'desc': 'Filter Replacement, Membrane, TDS Check', 'keywords': 'ro purifier aquaguard filter membrane service water kent'},
            {'name': 'Internet & Wi-Fi Broadband', 'desc': 'Fiber, Router, ISP Monthly Plan', 'keywords': 'wifi internet broadband router act airtel jio optic fiber isp'},
            {'name': 'Pest Control & Termite', 'desc': 'Cockroach, Termite, Bedbug, Mosquito', 'keywords': 'pest control termite bug spray mosquito cockroach fumigation'},
            {'name': 'Plumbing & Pipe Repair', 'desc': 'Tap Leak, Tank Cleaning, Pipe Fitting', 'keywords': 'plumbing plumber tap pipe leak drain water tank bathroom sink'},
            {'name': 'Electrician & Wiring', 'desc': 'Short Circuit, Switchboard, MCB, Wiring', 'keywords': 'electrician electrical wiring power switch light mcb repair fan'},
            {'name': 'Deep House Cleaning', 'desc': 'Full Home, Bathroom, Kitchen, Balcony', 'keywords': 'cleaning deep clean maid housekeeping sanitize wash house floor'},
            {'name': 'AC Servicing & Gas Refill', 'desc': 'Cooling Coil Clean, Gas Top-up, Filter', 'keywords': 'ac air conditioner cooling gas refill coil compressor service'},
            {'name': 'Car & Bike Wash Detailing', 'desc': 'Daily Wash, Foam Cleaning, Polishing', 'keywords': 'car bike vehicle wash cleaner detailing automobile vehicle'},
            {'name': 'Newspaper & Milk Delivery', 'desc': 'Daily Morning Essentials Subscription', 'keywords': 'newspaper milk diary daily morning subscription delivery'},
            {'name': 'Garbage & Waste Collection', 'desc': 'Doorstep Waste Management & Disposal', 'keywords': 'garbage trash waste disposal collection municipality pickup'},
            {'name': 'Gardener & Lawn Care', 'desc': 'Plant Trimming, Watering, Soil & Lawn', 'keywords': 'gardener lawn plant flower grass watering garden tree potting'},
            {'name': 'Chimney & Exhaust Cleaning', 'desc': 'Degreasing, Baffle Filter, Duct Clean', 'keywords': 'chimney exhaust kitchen oil duct degrease clean hood motor'},
            {'name': 'Solar Panel Cleaning & AMC', 'desc': 'Rooftop Solar Glass Wash & Inverter Check', 'keywords': 'solar panel rooftop electricity inverter sun clean plant amc'},
            {'name': 'Inverter & Battery Water', 'desc': 'Distilled Water, Backup Testing, Acid Check', 'keywords': 'inverter battery backup power acid distilled water ups tubular'},
            {'name': 'CCTV & Security System', 'desc': 'Camera Offline, DVR Storage, Wiring', 'keywords': 'cctv camera security surveillance dvr nvr guard video feed'},
            {'name': 'Carpentry & Furniture Repair', 'desc': 'Door Lock, Hinges, Bed, Wardrobe Repair', 'keywords': 'carpenter carpentry wood furniture door lock table cabinet drawer'},
            {'name': 'Painting & Wall Touchup', 'desc': 'Waterproofing, Damp Wall, Color Touch-up', 'keywords': 'painter paint wall damp waterproof color touchup brush plaster'},
            {'name': 'Elevator & Lift Maintenance', 'desc': 'Monthly Lift AMC, Safety Sensor Check', 'keywords': 'lift elevator amc maintenance safety building residential'},
            {'name': 'Generator / Genset Service', 'desc': 'Diesel Fuel Top-up, Engine Oil, Filter', 'keywords': 'generator genset diesel backup fuel engine dg set service'},
            {'name': 'DTH & Cable TV Subscription', 'desc': 'Tata Play, Airtel DTH, Cable TV Recharge', 'keywords': 'dth cable tv television subscription dish tata play airtel recharge'},
            {'name': 'Others', 'desc': 'Custom Utility or Unlisted Home Service', 'keywords': 'others custom miscellaneous general manual'},
          ]
        : [
            {'name': 'Air Conditioner', 'desc': 'Split, Window, Inverter AC, Cassette', 'keywords': 'ac air conditioner split window inverter cooling daikin lg voltas'},
            {'name': 'Refrigerator / Fridge', 'desc': 'Double Door, Side by Side, Mini Fridge', 'keywords': 'fridge refrigerator freezer double door cool compressor samsung lg whirlpool'},
            {'name': 'Washing Machine', 'desc': 'Front Load, Top Load, Semi Automatic', 'keywords': 'washing machine dryer laundry front load top load ifb bosch lg'},
            {'name': 'Water Purifier / RO', 'desc': 'RO + UV + UF, Mineralizer, Alkaliser', 'keywords': 'water purifier ro aquaguard filter kent mineralizer pureit livepure'},
            {'name': 'Geyser / Water Heater', 'desc': 'Instant Geyser, Storage Tank, Gas Geyser', 'keywords': 'geyser water heater instant storage heating boiler ao smith racold crompton'},
            {'name': 'Microwave & Oven', 'desc': 'Convection, Grill, Solo Microwave, OTG', 'keywords': 'microwave oven otg convection grill heating bake ifb panasonic'},
            {'name': 'Television / Smart TV', 'desc': 'OLED, QLED, 4K LED TV, Soundbar', 'keywords': 'tv television smart tv oled led display screen 4k sony samsung lg'},
            {'name': 'Kitchen Chimney', 'desc': 'Auto-Clean Chimney, Island, Wall Mounted', 'keywords': 'chimney kitchen exhaust suction baffle filter hood faber elica'},
            {'name': 'Inverter & Home UPS', 'desc': 'Pure Sine Wave, Tubular Battery, Solar UPS', 'keywords': 'inverter ups battery tubular power backup sine wave luminous microtek'},
            {'name': 'Solar Power System', 'desc': 'On-Grid, Off-Grid Solar Plant, Inverter', 'keywords': 'solar power rooftop panel grid photovoltaic green energy tata solar'},
            {'name': 'Dishwasher', 'desc': '12-14 Place Settings, Built-in Dishwasher', 'keywords': 'dishwasher utensils kitchen dish cleaner wash vessels bosch ifb'},
            {'name': 'Ceiling & Exhaust Fans', 'desc': 'BLDC Fan, High Speed, Wall Exhaust', 'keywords': 'fan ceiling fan bldc exhaust ventilation air atomberg havells'},
            {'name': 'Air Purifier', 'desc': 'HEPA Filter, Carbon Air Purifier, Ionizer', 'keywords': 'air purifier hepa filter pollution dust smoke clean dyson philips'},
            {'name': 'Induction & Gas Hob', 'desc': 'Glass Cooktop, Induction Stove, Burner Hob', 'keywords': 'induction stove cooktop gas hob burner glass kitchen prestige pigeon'},
            {'name': 'Food Processor / Mixer', 'desc': 'Mixer Grinder, Juicer, Blender, Chopper', 'keywords': 'mixer grinder juicer food processor blender jar motor sujata philips'},
            {'name': 'Vacuum Cleaner', 'desc': 'Robotic Vacuum, Wet & Dry, Cordless Stick', 'keywords': 'vacuum cleaner robotic mop cleaner dust suction suction dyson mi'},
            {'name': 'Water Motor / Pump', 'desc': 'Submersible Pump, Monoblock, Pressure Booster', 'keywords': 'pump motor water pump submersible monoblock pressure tank kirloskar crompton'},
            {'name': 'Room Heater / Blower', 'desc': 'Oil Filled Radiator, Halogen, Fan Heater', 'keywords': 'room heater blower radiator winter heating warm orpat morphy'},
            {'name': 'Home Theater & Audio', 'desc': '5.1 Surround, Soundbar, Amplifier', 'keywords': 'home theater audio soundbar speaker amplifier surround sony jbl'},
            {'name': 'CCTV DVR / NVR Unit', 'desc': 'Surveillance System, Hard Drive, Camera Unit', 'keywords': 'cctv camera security surveillance dvr nvr guard video cp plus hikvision'},
            {'name': 'Others', 'desc': 'Custom Home Appliance or Equipment', 'keywords': 'others custom gadget appliance machine'},
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filtered = categories.where((cat) {
              final query = searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              final name = cat['name']!.toLowerCase();
              final desc = cat['desc']!.toLowerCase();
              final keywords = (cat['keywords'] ?? '').toLowerCase();
              return name.contains(query) || desc.contains(query) || keywords.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      // Drag handle & Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF0D9488).withAlpha(isDark ? 40 : 25),
                              child: Icon(
                                isService ? Icons.handyman_rounded : Icons.devices_other_rounded,
                                color: const Color(0xFF0D9488),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isService ? 'Select Service Category' : 'Select Appliance Category',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${categories.length} categories available',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.all(6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),

                      // Search Input Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          autofocus: false,
                          style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          onChanged: (val) => setSheetState(() => searchQuery = val),
                          decoration: InputDecoration(
                            hintText: isService ? 'Search services (e.g. gas, water, cleaner, wifi)...' : 'Search appliances (e.g. ac, fridge, ro, tv)...',
                            hintStyle: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 19),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () => setSheetState(() => searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Category List View
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.category_outlined, size: 42, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No matching category found',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You can add "$searchQuery" as a custom category.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D9488),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                          onCategorySelected(searchQuery.trim(), true);
                                        },
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: Text('Use "$searchQuery"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final cat = filtered[index];
                                  final catName = cat['name']!;
                                  final catDesc = cat['desc']!;
                                  final isSelected = selectedCategory == catName;
                                  final isOthers = catName == 'Others';
                                  final icon = _getApplianceIcon(catName);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark ? const Color(0x280D9488) : const Color(0xFFF0FDFA))
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0D9488)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                      leading: CircleAvatar(
                                        radius: 19,
                                        backgroundColor: isSelected
                                            ? const Color(0xFF0D9488)
                                            : (const Color(0xFF0D9488).withAlpha(isDark ? 40 : 25)),
                                        child: Icon(
                                          isOthers ? Icons.add_circle_outline_rounded : icon,
                                          color: isSelected ? Colors.white : const Color(0xFF0D9488),
                                          size: 19,
                                        ),
                                      ),
                                      title: Text(
                                        catName,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 13.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      subtitle: Text(
                                        catDesc,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 20)
                                          : const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        onCategorySelected(catName, isOthers);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
    String selectedCategory = 'service'; // Default to 'service' first
    String? selectedPreset = 'Gas Cylinder Refill';
    bool isCustomCategory = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Initialize with default preset
    typeController.text = 'Gas Cylinder Refill';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isService = selectedCategory == 'service';

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dialog Header
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
                              child: Icon(isService ? Icons.handyman_rounded : Icons.devices_other_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isService ? 'Register Service / Utility' : 'Register New Appliance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF042F2E),
                                    ),
                                  ),
                                  Text(
                                    isService ? 'Gas, water delivery, Wi-Fi, pest control...' : 'AC, Fridge, TV, Washing Machine...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F766E),
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

                      // Segmented Type Selector (Service FIRST, then Appliance)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDlgState(() {
                                    selectedCategory = 'service';
                                    selectedPreset = 'Gas Cylinder Refill';
                                    isCustomCategory = false;
                                    typeController.text = 'Gas Cylinder Refill';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == 'service'
                                        ? const Color(0xFF0D9488)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: selectedCategory == 'service'
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF0D9488).withAlpha(80),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.handyman_rounded,
                                        size: 15,
                                        color: selectedCategory == 'service'
                                            ? Colors.white
                                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Service / Utility',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: selectedCategory == 'service'
                                              ? Colors.white
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDlgState(() {
                                    selectedCategory = 'appliance';
                                    selectedPreset = 'Air Conditioner';
                                    isCustomCategory = false;
                                    typeController.text = 'Air Conditioner';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == 'appliance'
                                        ? const Color(0xFF0D9488)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: selectedCategory == 'appliance'
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF0D9488).withAlpha(80),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.devices_other_rounded,
                                        size: 15,
                                        color: selectedCategory == 'appliance'
                                            ? Colors.white
                                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Appliance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: selectedCategory == 'appliance'
                                              ? Colors.white
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Name Field (ONLY REQUIRED FIELD)
                            _buildDialogInputField(
                              context: context,
                              controller: nameController,
                              label: isService ? 'Service / Utility Name *' : 'Appliance Name *',
                              prefixIcon: isService ? Icons.handyman_rounded : Icons.devices_other_rounded,
                              hintText: isService ? 'e.g. Indane Gas, Bisleri Water Can, Wi-Fi' : 'e.g. Living Room AC, Kitchen Fridge',
                              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 12),

                            // 2. Search Selective Category Field
                            InkWell(
                              onTap: () {
                                _showCategorySearchSheet(
                                  context,
                                  isService: isService,
                                  selectedCategory: selectedPreset,
                                  onCategorySelected: (cat, isCustom) {
                                    setDlgState(() {
                                      selectedPreset = cat;
                                      isCustomCategory = isCustom;
                                      if (isCustom) {
                                        typeController.clear();
                                      } else {
                                        typeController.text = cat;
                                        if (nameController.text.trim().isEmpty) {
                                          nameController.text = cat;
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF0D9488).withAlpha(isDark ? 40 : 25),
                                      child: Icon(
                                        _getApplianceIcon(selectedPreset ?? 'Others'),
                                        color: const Color(0xFF0D9488),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isService ? 'Service Category' : 'Appliance Category',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            (selectedPreset != null && selectedPreset!.isNotEmpty)
                                                ? selectedPreset!
                                                : (isService ? 'Select service category...' : 'Select appliance category...'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D9488).withAlpha(isDark ? 30 : 15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.search_rounded, size: 13, color: Color(0xFF0D9488)),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Search / Pick',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D9488),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // If 'Others' or custom category selected, show custom text field
                            if (isCustomCategory || selectedPreset == 'Others') ...[
                              const SizedBox(height: 10),
                              _buildDialogInputField(
                                context: context,
                                controller: typeController,
                                label: 'Custom Category / Type (Optional)',
                                prefixIcon: Icons.edit_note_rounded,
                                hintText: isService ? 'e.g. Solar Panel Maintenance, Car Wash' : 'e.g. Dishwasher, Coffee Machine',
                              ),
                            ],

                            const SizedBox(height: 10),
                            // Optional Brand / Provider & Serial / Account
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDialogInputField(
                                    context: context,
                                    controller: brandController,
                                    label: isService ? 'Provider / Agency' : 'Brand Name',
                                    prefixIcon: Icons.branding_watermark_rounded,
                                    hintText: isService ? 'e.g. Bharat Gas, ACT' : 'e.g. LG, Daikin',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDialogInputField(
                                    context: context,
                                    controller: serialController,
                                    label: isService ? 'Account / ID' : 'Serial Number',
                                    prefixIcon: Icons.numbers_rounded,
                                    hintText: 'Optional',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Date Pickers Row (Optional)
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
                                                  ? (isService ? 'Service Start' : 'Warranty Start')
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
                                          Icon(isService ? Icons.event_repeat_rounded : Icons.shield_outlined, size: 15, color: const Color(0xFF0D9488)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              warrantyEnd == null
                                                  ? (isService ? 'Next Due / Expiry' : 'Warranty End')
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

                            // Invoice / Receipt Photo Picker (Optional)
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
                                      invoicePath == null
                                          ? (isService ? 'Attach Booking Slip / Receipt (Optional)' : 'Attach Purchase Receipt (Optional)')
                                          : 'Receipt Attached',
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
                                        final categoryValue = typeController.text.trim().isNotEmpty
                                            ? typeController.text.trim()
                                            : (selectedPreset != null && selectedPreset != 'Others'
                                                ? selectedPreset!
                                                : (isService ? 'General Utility' : 'General Appliance'));

                                        final appliance = Appliance(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          name: nameController.text.trim(),
                                          type: categoryValue,
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
                                              content: Text('${isService ? "Service" : "Appliance"} "${appliance.name}" registered!'),
                                              backgroundColor: const Color(0xFF059669),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to add item: $e'), backgroundColor: Colors.redAccent),
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
                                  : Text(isService ? 'Register Service' : 'Register Appliance', style: const TextStyle(fontWeight: FontWeight.bold)),
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
}

class ApplianceServiceDetailScreen extends StatefulWidget {
  final Appliance appliance;
  const ApplianceServiceDetailScreen({super.key, required this.appliance});

  @override
  State<ApplianceServiceDetailScreen> createState() => _ApplianceServiceDetailScreenState();
}

class _ApplianceServiceDetailScreenState extends State<ApplianceServiceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isServiceItem(Appliance item) {
    final text = '${item.type} ${item.name} ${item.brand}'.toLowerCase();
    return text.contains('gas') ||
        text.contains('cylinder') ||
        text.contains('lpg') ||
        text.contains('indane') ||
        text.contains('bharat') ||
        text.contains('hp gas') ||
        text.contains('water') ||
        text.contains('can') ||
        text.contains('delivery') ||
        text.contains('service') ||
        text.contains('utility') ||
        text.contains('refill') ||
        text.contains('booking') ||
        text.contains('pest') ||
        text.contains('wifi') ||
        text.contains('wi-fi') ||
        text.contains('internet') ||
        text.contains('broadband') ||
        text.contains('plumb') ||
        text.contains('electric') ||
        text.contains('maid') ||
        text.contains('vendor') ||
        text.contains('agency') ||
        text.contains('cleaning');
  }

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
    final isService = _isServiceItem(appliance);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appliance.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              isService ? 'Home Service / Utility' : 'Appliance Asset',
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            tooltip: isService ? 'Remove Service' : 'Remove Appliance',
            onPressed: () => _confirmDeleteAppliance(context, appliance, isService),
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isService ? Icons.receipt_long_rounded : Icons.handyman_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(isService ? 'Refill & Logs' : 'Service Logs'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isService ? Icons.info_outline_rounded : Icons.shield_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(isService ? 'Details & Bills' : 'Warranty & Specs'),
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
                    _buildServiceLogsTab(appliance, records, isDark, isService),
                    _buildOverviewTab(appliance, isDark, isService),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Appliance appliance, bool isDark, bool isService) {
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
                      child: Icon(isService ? Icons.handyman_rounded : Icons.devices_other_rounded, color: const Color(0xFF0D9488), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isService ? 'Service & Provider Details' : 'Device Specifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Divider(height: 18, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildSpecRow(isService ? 'Provider / Agency' : 'Brand Name', appliance.brand, isDark),
                _buildSpecRow(isService ? 'Category' : 'Model / Type', appliance.type, isDark),
                _buildSpecRow(isService ? 'Account / Consumer ID' : 'Serial Number', appliance.serialNumber.isNotEmpty ? appliance.serialNumber : 'Not logged', isDark),
                _buildSpecRow('Registered On', DateFormat('dd MMM yyyy').format(appliance.createdAt), isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Warranty / Validity Card
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
                            isService ? Icons.event_repeat_rounded : Icons.shield_rounded,
                            color: !hasWarranty
                                ? Colors.grey
                                : (isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isService ? 'Service Validity & Cycle' : 'Warranty Coverage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    _buildWarrantyStatusBadge(hasWarranty, isExpired, daysRemaining, isDark, isService),
                  ],
                ),
                Divider(height: 18, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                if (hasWarranty) ...[
                  _buildSpecRow(
                    isService ? 'Refill / Service Cycle' : 'Warranty Period',
                    '${DateFormat('dd MMM yyyy').format(appliance.warrantyStart!)} → ${DateFormat('dd MMM yyyy').format(appliance.warrantyEnd!)}',
                    isDark,
                  ),
                  _buildSpecRow(
                    'Status',
                    isExpired ? (isService ? 'Refill Due / Expired' : 'Expired') : '$daysRemaining Days remaining',
                    isDark,
                    isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        isService
                            ? 'On-demand recurring utility (No specific expiry configured).'
                            : 'No warranty period logged for this appliance.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Purchase Invoice / Booking Receipt Card
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
                      isService ? 'Booking Slip / Bill Receipt' : 'Purchase Invoice / Receipt',
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
                          Text(
                            isService ? 'Upload Booking Slip / Receipt' : 'Upload Purchase Bill / Warranty Slip',
                            style: const TextStyle(
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Secure image for warranty claims and records',
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

  Widget _buildWarrantyStatusBadge(bool hasWarranty, bool isExpired, int daysRemaining, bool isDark, bool isService) {
    if (!hasWarranty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isService ? 'Active Service' : 'No Warranty',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
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
        child: Text(
          isService ? 'Refill Due / Expired' : 'Expired',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x2810B981) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x5510B981)),
      ),
      child: Text(
        isService ? 'Valid ($daysRemaining d left)' : 'Active ($daysRemaining d left)',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
      ),
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
        const SnackBar(content: Text('Receipt uploaded successfully'), backgroundColor: Color(0xFF059669)),
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

  Widget _buildServiceLogsTab(Appliance appliance, List<ServiceRecord> records, bool isDark, bool isService) {
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
                  Text(isService ? 'Refill & Service Summary' : 'Servicing Summary', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  const SizedBox(height: 2),
                  Text('${records.length} ${isService ? "refills/logs" : "visits"} recorded', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Expense', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
                isService ? 'Refills & Service Timeline' : 'Service Logs Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(36, 32),
                ),
                onPressed: () => _showAddServiceLogDialog(context, appliance, isService),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(isService ? 'Add Refill/Log' : 'Add Log', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
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
                        Icon(isService ? Icons.propane_tank_rounded : Icons.handyman_rounded, size: 36, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 8),
                        Text(
                          isService ? 'No refills or service logs recorded.' : 'No service logs registered yet.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isService ? 'Tap "Add Refill/Log" to record cylinder or water delivery.' : 'Tap "Add Log" to record maintenance or repairs.',
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

  void _confirmDeleteAppliance(BuildContext context, Appliance appliance, bool isService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isService ? 'Delete Service / Utility?' : 'Delete Appliance?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          isService
              ? 'This will delete "${appliance.name}" and its full refill and service history permanently.'
              : 'This will delete "${appliance.name}" and its full service log history permanently.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await context.read<ApplianceProvider>().deleteAppliance(appliance.id);
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

  void _showAddServiceLogDialog(BuildContext context, Appliance appliance, bool isService) {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    final remarksController = TextEditingController();
    DateTime serviceDate = DateTime.now();
    String? billPath;
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presetPrices = [300, 500, 1000, 2000];
    final presetRemarks = isService
        ? ['Gas Cylinder Refill', 'Water Bottle Delivery', 'RO Filter Replacement', 'Monthly Subscription', 'Emergency Fix']
        : ['Routine Servicing', 'Gas Refill', 'Filter Replacement', 'Motor Repair', 'PCB Replacement'];

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
                            child: Icon(isService ? Icons.propane_tank_rounded : Icons.build_circle_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isService ? 'Record Refill / Service Log' : 'Record Service Log',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF042F2E),
                                  ),
                                ),
                                Text(
                                  '${isService ? "Service" : "Appliance"}: ${appliance.name}',
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
                            validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Enter cost amount' : null,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              labelText: isService ? 'Refill / Service Cost (₹)' : 'Service / Repair Cost (₹)',
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
                              labelText: isService ? 'Refill Notes / Description' : 'Work Description / Remarks',
                              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D9488), size: 18),
                              hintText: isService ? 'e.g. 14.2kg LPG cylinder refill, 20L water can...' : 'e.g. Filter cleaning, PCB replacement...',
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
                                    billPath == null ? 'Attach Receipt / Bill Slip' : 'Receipt Attached',
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
                                        applianceId: appliance.id,
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
                                                Text('Log of ₹${price.toStringAsFixed(0)} recorded', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                          SnackBar(content: Text('Failed to add record: $e'), backgroundColor: Colors.redAccent),
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
                                : Text(isService ? 'Save Refill Log' : 'Save Service Log', style: const TextStyle(fontWeight: FontWeight.bold)),
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

