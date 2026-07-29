import 'dart:io';
import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplianceProvider>();
    final appliances = provider.appliances;
    final colorScheme = Theme.of(context).colorScheme;

    final visualHeaderCard = SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0x1E009688), // Teal 12% alpha
              Color(0x0A009688), // Teal 4% alpha
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33009688), width: 1.5), // 20% alpha
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build_rounded, color: Color(0xFF009688), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Servicing Register',
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
                    'Track appliance servicing and maintenance logs',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: 'Add Appliance',
              onPressed: () => _showAddApplianceDialog(context),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          visualHeaderCard,
          Expanded(
            child: appliances.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build_circle_rounded, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          const Text(
                            'No Appliances Registered',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add an appliance to start logging servicing costs and history.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: appliances.length,
                    itemBuilder: (context, index) {
                      final appliance = appliances[index];
                      return FutureBuilder<List<ServiceRecord>>(
                        future: provider.getServiceRecords(appliance.id),
                        builder: (context, snapshot) {
                          final records = snapshot.data ?? [];
                          final totalCost = records.fold<double>(0.0, (sum, r) => sum + r.price);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 0,
                            color: colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0x1E009688),
                                child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF009688)),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      appliance.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${totalCost.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${appliance.brand} • ${appliance.type}',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withAlpha(180)),
                                    ),
                                    Text(
                                      '${records.length} service logs',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ApplianceServiceDetailScreen(appliance: appliance),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
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

  void _showAddApplianceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final brandController = TextEditingController();
    final serialController = TextEditingController();
    DateTime? warrantyStart;
    DateTime? warrantyEnd;
    String? invoicePath;

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
                        color: const Color(0x1E009688),
                        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0x33009688),
                            child: const Icon(Icons.add_to_photos_rounded, color: Color(0xFF009688), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'New Appliance',
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
                            label: 'Appliance Name',
                            prefixIcon: Icons.devices_other_rounded,
                            hintText: 'e.g. Iron Box A',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: typeController,
                            label: 'Appliance Type',
                            prefixIcon: Icons.category_rounded,
                            hintText: 'e.g. Iron, Vacuum Cleaner',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter type' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: brandController,
                            label: 'Brand',
                            prefixIcon: Icons.branding_watermark_rounded,
                            hintText: 'e.g. Philips, Dyson',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: serialController,
                            label: 'Serial Number',
                            prefixIcon: Icons.numbers_rounded,
                            hintText: 'e.g. PH1298X',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter serial number' : null,
                          ),
                          const SizedBox(height: 16),
                          // Date Pickers Row
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withAlpha(50),
                                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      warrantyStart == null
                                          ? 'Warranty Start'
                                          : '${warrantyStart!.day}/${warrantyStart!.month}/${warrantyStart!.year}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withAlpha(50),
                                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      warrantyEnd == null
                                          ? 'Warranty End'
                                          : '${warrantyEnd!.day}/${warrantyEnd!.month}/${warrantyEnd!.year}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Invoice photo Picker
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setDlgState(() => invoicePath = image.path);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: invoicePath == null ? Colors.transparent : Colors.green.withAlpha(20),
                                border: Border.all(color: invoicePath == null ? colorScheme.outlineVariant.withAlpha(80) : Colors.green),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    invoicePath == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
                                    color: invoicePath == null ? colorScheme.primary : Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    invoicePath == null ? 'Upload Invoice Image' : 'Invoice Selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: invoicePath == null ? colorScheme.primary : Colors.green,
                                      fontSize: 13,
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
                              backgroundColor: const Color(0xFF009688),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
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
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text('Add Appliance'),
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

class _ApplianceServiceDetailScreenState extends State<ApplianceServiceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplianceProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appliance.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
            tooltip: 'Remove Appliance',
            onPressed: () => _confirmDeleteAppliance(context),
          ),
        ],
      ),
      body: FutureBuilder<List<ServiceRecord>>(
        future: provider.getServiceRecords(widget.appliance.id),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          final totalCost = records.fold<double>(0.0, (sum, r) => sum + r.price);

          return Column(
            children: [
              // Top detail card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appliance Specs', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          const SizedBox(height: 6),
                          Text('Brand: ${widget.appliance.brand}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Serial: ${widget.appliance.serialNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Type: ${widget.appliance.type}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Total Serviced', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text('₹${totalCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service History Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddServiceLogDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          'No service history logged yet.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final log = records[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.teal,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.teal.withAlpha(60),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < records.length - 1)
                                      Container(
                                        width: 2,
                                        height: 80,
                                        color: Colors.teal.withAlpha(50),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    elevation: 0,
                                    color: colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100), width: 1.5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '₹${log.price.toStringAsFixed(0)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                                              ),
                                              Text(
                                                '${log.serviceDate.day}/${log.serviceDate.month}/${log.serviceDate.year}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          if (log.remarks.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              log.remarks,
                                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (log.billPath != null)
                                                InkWell(
                                                  onTap: () => _viewBillPhoto(context, log.billPath!),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.receipt_rounded, size: 14, color: Colors.teal),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'View Bill',
                                                          style: TextStyle(fontSize: 12, color: Colors.teal[700], fontWeight: FontWeight.bold),
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
                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteAppliance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appliance?'),
        content: const Text('This will delete the appliance specs and all logged service history permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<ApplianceProvider>().deleteAppliance(widget.appliance.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close details page
              }
            },
            child: const Text('Delete'),
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
                        color: const Color(0x1E009688),
                        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0x33009688),
                            child: const Icon(Icons.build_circle_rounded, color: Color(0xFF009688), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Add Service Log',
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
                          TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Enter valid service price' : null,
                            decoration: InputDecoration(
                              labelText: 'Service Price (₹)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Colors.teal),
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
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: remarksController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Remarks & Details',
                              prefixIcon: const Icon(Icons.description_rounded, color: Colors.teal),
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
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Date picker
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
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.teal),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Date: ${serviceDate.day}/${serviceDate.month}/${serviceDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bill photo upload picker
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setDlgState(() => billPath = image.path);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: billPath == null ? Colors.transparent : Colors.green.withAlpha(20),
                                border: Border.all(color: billPath == null ? colorScheme.outlineVariant.withAlpha(80) : Colors.green),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    billPath == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
                                    color: billPath == null ? colorScheme.primary : Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    billPath == null ? 'Upload Bill Image' : 'Bill Selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: billPath == null ? colorScheme.primary : Colors.green,
                                      fontSize: 13,
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
                              backgroundColor: const Color(0xFF009688),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
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
                              }
                            },
                            child: const Text('Save Record'),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bill Image Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
