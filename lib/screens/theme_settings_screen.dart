import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';

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
              _SectionLabel(title: 'Currency', icon: Icons.payments_rounded),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: Currency.values.map((currency) {
                    final isLast = currency == Currency.values.last;
                    return Column(
                      children: [
                        RadioListTile<Currency>(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          value: currency,
                          groupValue: settings.currency,
                          onChanged: (value) => value != null ? context.read<ThemeProvider>().setCurrency(value) : null,
                          title: Text(currency.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Symbol: ${currency.symbol}'),
                          secondary: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              currency.symbol,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, indent: 56),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Task layout', icon: Icons.dashboard_customize_rounded),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: [
                    _SettingSwitch(
                      value: settings.compactMode,
                      onChanged: (v) => context.read<ThemeProvider>().setCompactMode(v),
                      title: 'Compact list',
                      subtitle: 'Show more tasks with tighter spacing',
                      icon: Icons.compress_rounded,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingSwitch(
                      value: settings.groupCompletedAtBottom,
                      onChanged: (v) => context.read<ThemeProvider>().setGroupCompletedAtBottom(v),
                      title: 'Keep completed tasks last',
                      subtitle: 'Keep active work at the top',
                      icon: Icons.align_vertical_bottom_rounded,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingSwitch(
                      value: settings.showDescriptions,
                      onChanged: (v) => context.read<ThemeProvider>().setShowDescriptions(v),
                      title: 'Show descriptions',
                      subtitle: 'Toggle visibility of task details',
                      icon: Icons.description_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'Custom fields', icon: Icons.add_circle_outline_rounded),
              const SizedBox(height: 12),
              _SettingCard(
                child: Column(
                  children: [
                    _SettingSwitch(
                      value: settings.allowTextFields,
                      onChanged: (v) => context.read<ThemeProvider>().setAllowTextFields(v),
                      title: 'Text fields',
                      subtitle: 'Add extra notes or structured text',
                      icon: Icons.notes_rounded,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingSwitch(
                      value: settings.allowImageFields,
                      onChanged: (v) => context.read<ThemeProvider>().setAllowImageFields(v),
                      title: 'Image fields',
                      subtitle: 'Attach camera or gallery images',
                      icon: Icons.image_rounded,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingSwitch(
                      value: settings.allowNumberFields,
                      onChanged: (v) => context.read<ThemeProvider>().setAllowNumberFields(v),
                      title: 'Number fields',
                      subtitle: 'Add prices, counts, or numeric values',
                      icon: Icons.numbers_rounded,
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
              await context.read<TodoProvider>().clearAllData();
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

class _SettingSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;

  const _SettingSwitch({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      value: value,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      secondary: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}
