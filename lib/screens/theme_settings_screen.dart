import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  final VoidCallback? onStartTour;
  const ThemeSettingsScreen({super.key, this.onStartTour});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
            children: [
              _HeaderSection(
                title: 'Personalization',
                subtitle: 'Adjust the app for your workflow',
                icon: Icons.tune_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Appearance', icon: Icons.palette_rounded),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      value: ThemeMode.light,
                      groupValue: settings.themeMode,
                      onChanged: (mode) => mode != null ? context.read<ThemeProvider>().setThemeMode(mode) : null,
                      title: const Text('Light mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Clean and bright'),
                      secondary: const Icon(Icons.light_mode_rounded),
                    ),
                    const Divider(height: 1, indent: 56),
                    RadioListTile<ThemeMode>(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      value: ThemeMode.dark,
                      groupValue: settings.themeMode,
                      onChanged: (mode) => mode != null ? context.read<ThemeProvider>().setThemeMode(mode) : null,
                      title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Easy on the eyes'),
                      secondary: const Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Backup & Restore', icon: Icons.backup_rounded),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Export Backup File', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Save registry data to a local file'),
                      leading: const Icon(Icons.download_rounded, color: Colors.green),
                      onTap: () => _exportBackup(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      title: const Text('Restore Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Restore registry data from file or JSON text'),
                      leading: const Icon(Icons.upload_rounded, color: Colors.orange),
                      onTap: () => _showRestoreDialog(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary.withAlpha(200),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'On Android 10+, uninstalling the app will prompt to "Keep app data" so you can reinstall without losing data. You can also turn on cloud backup to auto-restore from your Google account.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Data & Tour', icon: Icons.security_rounded),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Clear all data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Permanently erase everything'),
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      onTap: () => _showClearDataVerification(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      title: const Text('Start guided tour', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Interactive refresher of features'),
                      leading: const Icon(Icons.play_circle_filled_rounded, color: Colors.blue),
                      onTap: onStartTour,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      title: const Text('Show tour next launch', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Tour will show automatically next time'),
                      leading: const Icon(Icons.replay_rounded, color: Colors.grey),
                      onTap: () async {
                        await context.read<ThemeProvider>().resetTips();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tour scheduled for next launch')),
                          );
                        }
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDataVerification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will delete all your tasks, services, activities, and reports. This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalVerification(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Yes, delete'),
          ),
        ],
      ),
    );
  }

  void _showFinalVerification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'Last chance: all your data will be permanently erased. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<EmployeeProvider>().clearAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared.')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final defaultFolderPath = directory.path;
      final defaultFilename = 'Registry_Backup_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final folderController = TextEditingController(text: defaultFolderPath);
      final fileController = TextEditingController(text: defaultFilename);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.download_rounded, color: Colors.blue),
                SizedBox(width: 8),
                Text('Export Backup'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select destination folder:'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: folderController,
                          decoration: InputDecoration(
                            labelText: 'Destination Folder',
                            hintText: 'e.g. C:\\Users\\Desktop',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () async {
                            try {
                              final String? selectedDirectory = await FilePicker.getDirectoryPath();
                              if (selectedDirectory != null) {
                                folderController.text = selectedDirectory;
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open folder picker: $e. You can still type the path manually.'),
                                    duration: const Duration(seconds: 6),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Icon(Icons.folder_open_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Enter backup filename:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fileController,
                    decoration: InputDecoration(
                      labelText: 'Filename',
                      hintText: 'backup.json',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final folderPath = folderController.text.trim();
                  final filename = fileController.text.trim();
                  if (folderPath.isEmpty || filename.isEmpty) return;

                  try {
                    final dir = Directory(folderPath);
                    if (!await dir.exists()) {
                      await dir.create(recursive: true);
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final keys = prefs.getKeys();
                    final Map<String, dynamic> backupData = {};
                    
                    for (final key in keys) {
                      final val = prefs.get(key);
                      backupData[key] = val;
                    }
                    
                    final jsonString = json.encode(backupData);
                    final file = File('${dir.path}/$filename');
                    await file.writeAsString(jsonString);

                    if (context.mounted) {
                      Navigator.pop(context); // Close config dialog
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Backup Exported'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Registry data successfully written to:'),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(150),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)),
                                ),
                                child: SelectableText(
                                  file.path,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Courier'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Copy this file path or JSON text to restore later.'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save file: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Export'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context) {
    final pathController = TextEditingController();
    final jsonController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    int activeTab = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) => DefaultTabController(
            length: 2,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Restore Backup'),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      onTap: (idx) => setDlgState(() => activeTab = idx),
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      tabs: const [
                        Tab(text: 'File Path'),
                        Tab(text: 'Paste JSON'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // File Path Tab
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Enter absolute path of backup file:'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: pathController,
                                      decoration: InputDecoration(
                                        labelText: 'Backup File Path',
                                        hintText: 'e.g. C:\\Users\\...\\Registry_Backup_xxx.json',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 56,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final FilePickerResult? result = await FilePicker.pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: ['json'],
                                          );
                                          if (result != null && result.files.single.path != null) {
                                            pathController.text = result.files.single.path!;
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Could not open file picker: $e. You can still type the path manually.'),
                                                duration: const Duration(seconds: 6),
                                                action: SnackBarAction(
                                                  label: 'OK',
                                                  onPressed: () {},
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Icon(Icons.file_open_rounded),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                          // Paste JSON Tab
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Paste the JSON text content of your backup:'),
                              const SizedBox(height: 8),
                              Expanded(
                                child: TextField(
                                  controller: jsonController,
                                  maxLines: null,
                                  expands: true,
                                  decoration: InputDecoration(
                                    hintText: '{"employees": ...}',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    String data = '';
                    if (activeTab == 0) {
                      final path = pathController.text.trim();
                      if (path.isEmpty) return;
                      try {
                        final file = File(path);
                        if (!await file.exists()) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('File does not exist'), backgroundColor: Colors.red),
                            );
                          }
                          return;
                        }
                        data = await file.readAsString();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error reading file: $e'), backgroundColor: Colors.red),
                          );
                        }
                        return;
                      }
                    } else {
                      data = jsonController.text.trim();
                    }

                    if (data.isEmpty) return;

                    try {
                      final Map<String, dynamic> parsed = json.decode(data);
                      final prefs = await SharedPreferences.getInstance();
                      
                      for (final entry in parsed.entries) {
                        if (entry.value is List) {
                          final List<String> list = List<String>.from(entry.value);
                          await prefs.setStringList(entry.key, list);
                        } else if (entry.value is String) {
                          await prefs.setString(entry.key, entry.value);
                        } else if (entry.value is bool) {
                          await prefs.setBool(entry.key, entry.value);
                        } else if (entry.value is int) {
                          await prefs.setInt(entry.key, entry.value);
                        } else if (entry.value is double) {
                          await prefs.setDouble(entry.key, entry.value);
                        }
                      }

                      if (context.mounted) {
                        final empProvider = context.read<EmployeeProvider>();
                        final appProvider = context.read<ApplianceProvider>();
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        navigator.pop();
                        
                        await empProvider.refreshData();
                        await appProvider.loadAppliances();
                        
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Backup restored successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid backup content: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Restore'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HeaderSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 48, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;

  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: child,
    );
  }
}

