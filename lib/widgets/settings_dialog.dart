import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Dark Mode Theme Toggle
            const Text(
              'Appearance Theme',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {provider.themeMode},
              onSelectionChanged: (newSelection) {
                provider.setThemeMode(newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // Daily Evening Reminder Notifications
            const Text(
              'Daily Reminder Notification',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Daily Reminder'),
              subtitle: const Text('Notify in evening if habits remain uncompleted'),
              value: provider.reminderEnabled,
              onChanged: (val) {
                provider.setReminderSettings(val, provider.reminderTime);
              },
            ),

            if (provider.reminderEnabled) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder Time'),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.access_time_rounded),
                  label: Text(provider.reminderTime.format(context)),
                  onPressed: () async {
                    final newTime = await showTimePicker(
                      context: context,
                      initialTime: provider.reminderTime,
                    );
                    if (newTime != null) {
                      provider.setReminderSettings(true, newTime);
                    }
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
