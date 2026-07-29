import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/appliance_model.dart';
import '../providers/appliance_provider.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
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
              Color(0x1EFFB300), // Amber 12% alpha
              Color(0x0AFFB300), // Amber 4% alpha
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFB300), width: 1.5), // 20% alpha
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: Color(0xFFFFB300), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Warranties Tracker',
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
                    'Monitor appliance warranties and purchase invoices',
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
                backgroundColor: const Color(0xFFFFB300),
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
                          Icon(Icons.shield_rounded, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          const Text(
                            'No Warranties Registered',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add an appliance with its warranty details to monitor expiration.',
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
                      final isExpired = _checkIsExpired(appliance.warrantyEnd);
                      final remainingText = _getRemainingDaysText(appliance.warrantyEnd);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 0,
                        color: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isExpired
                                ? Colors.red.withAlpha(80)
                                : colorScheme.outlineVariant.withAlpha(100),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      appliance.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildWarrantyStatusBadge(isExpired),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Brand: ${appliance.brand}  •  Serial: ${appliance.serialNumber}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withAlpha(180)),
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Warranty Period',
                                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getWarrantyPeriodRange(appliance.warrantyStart, appliance.warrantyEnd),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    remainingText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isExpired ? Colors.red : Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              if (appliance.invoicePath != null) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => _viewInvoicePhoto(context, appliance.invoicePath!),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text(
                                        'View Purchase Invoice / Bill',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _checkIsExpired(DateTime? end) {
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }

  String _getRemainingDaysText(DateTime? end) {
    if (end == null) return 'No Date Logged';
    final now = DateTime.now();
    if (end.isBefore(now)) return 'Expired!';
    final diff = end.difference(now).inDays;
    if (diff == 0) return 'Expires Today!';
    return '$diff days remaining';
  }

  String _getWarrantyPeriodRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'N/A';
    final f = DateFormat('d MMM yyyy');
    return '${f.format(start)} - ${f.format(end)}';
  }

  Widget _buildWarrantyStatusBadge(bool isExpired) {
    final bg = isExpired ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20);
    final border = isExpired ? Colors.red.withAlpha(100) : Colors.green.withAlpha(100);
    final text = isExpired ? Colors.red : Colors.green[700];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        isExpired ? 'EXPIRED' : 'ACTIVE',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
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
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
                        color: const Color(0x1EFFB300),
                        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0x33FFB300),
                            child: const Icon(Icons.add_to_photos_rounded, color: Color(0xFFFFB300), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'New Warranty Lock',
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
                            hintText: 'e.g. Washing Machine 1',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: typeController,
                            label: 'Appliance Type',
                            prefixIcon: Icons.category_rounded,
                            hintText: 'e.g. Washer, Dryer',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter type' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: brandController,
                            label: 'Brand',
                            prefixIcon: Icons.branding_watermark_rounded,
                            hintText: 'e.g. LG, Samsung',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: serialController,
                            label: 'Serial Number',
                            prefixIcon: Icons.numbers_rounded,
                            hintText: 'e.g. LG9981S',
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
                          // Invoice Photo Picker
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
                              backgroundColor: const Color(0xFFFFB300),
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

  void _viewInvoicePhoto(BuildContext context, String path) {
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
                  const Text('Invoice Invoice Document', style: TextStyle(fontWeight: FontWeight.bold)),
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
