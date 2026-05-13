import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        children: [
          Text(
            'Adjust the app for your workflow',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'Appearance'),
          const SizedBox(height: 8),
          _SettingCard(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      context.read<ThemeProvider>().setThemeMode(mode);
                    }
                  },
                  title: const Text('Light mode'),
                  subtitle: const Text('Clean and bright'),
                  secondary: const Icon(Icons.light_mode_rounded),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      context.read<ThemeProvider>().setThemeMode(mode);
                    }
                  },
                  title: const Text('Dark mode'),
                  subtitle: const Text('Easy on the eyes'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'Task layout'),
          const SizedBox(height: 8),
          _SettingCard(
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.compactMode,
                  onChanged: (value) => context.read<ThemeProvider>().setCompactMode(value),
                  title: const Text('Compact list'),
                  subtitle: const Text('Show more tasks with tighter spacing'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.groupCompletedAtBottom,
                  onChanged: (value) =>
                      context.read<ThemeProvider>().setGroupCompletedAtBottom(value),
                  title: const Text('Keep completed tasks last'),
                  subtitle: const Text('Keep active work at the top'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.showDescriptions,
                  onChanged: (value) => context.read<ThemeProvider>().setShowDescriptions(value),
                  title: const Text('Show descriptions'),
                  subtitle: const Text('Hide task details when you want a cleaner list'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.showTimestamps,
                  onChanged: (value) => context.read<ThemeProvider>().setShowTimestamps(value),
                  title: const Text('Show timestamps'),
                  subtitle: const Text('Display when each task was created'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.importantReminders,
                  onChanged: (value) async {
                    await context.read<ThemeProvider>().setImportantReminders(value);
                    await context.read<TodoProvider>().rescheduleAllReminders();
                  },
                  title: const Text('Important reminders'),
                  subtitle: const Text(
                    'Android only: use a louder alarm-style reminder channel',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'Custom fields'),
          const SizedBox(height: 8),
          _SettingCard(
            child: Column(
              children: [
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.allowTextFields,
                  onChanged: (value) => context.read<ThemeProvider>().setAllowTextFields(value),
                  title: const Text('Text fields'),
                  subtitle: const Text('Add extra notes or structured text'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.allowImageFields,
                  onChanged: (value) => context.read<ThemeProvider>().setAllowImageFields(value),
                  title: const Text('Image fields'),
                  subtitle: const Text('Attach camera or gallery images to a task'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.allowVideoFields,
                  onChanged: (value) => context.read<ThemeProvider>().setAllowVideoFields(value),
                  title: const Text('Video fields'),
                  subtitle: const Text('Attach video links to a task'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: settings.allowNumberFields,
                  onChanged: (value) => context.read<ThemeProvider>().setAllowNumberFields(value),
                  title: const Text('Number fields'),
                  subtitle: const Text('Add prices, counts, or other numeric values'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: 'Tips'),
          const SizedBox(height: 8),
          _SettingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.hasSeenTips
                      ? 'You can show the onboarding tips again if you want a quick refresher.'
                      : 'Tips are shown on first launch to help you get started quickly.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await context.read<ThemeProvider>().resetTips();
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Show tips next launch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: child,
      ),
    );
  }
}
