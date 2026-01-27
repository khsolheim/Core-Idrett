import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

// Notification settings stored locally
const _notifActivityKey = 'notif_activity';
const _notifReminderKey = 'notif_reminder';
const _notifFineKey = 'notif_fine';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Innstillinger'),
      ),
      body: ListView(
        children: [
          // Profile section
          _SectionHeader(title: 'Profil'),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.name.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            title: Text(user?.name ?? 'Bruker'),
            subtitle: Text(user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('profile'),
          ),

          const Divider(),

          // Appearance section
          _SectionHeader(title: 'Utseende'),
          ListTile(
            leading: Icon(themeMode.icon),
            title: const Text('Tema'),
            subtitle: Text(themeMode.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Sprak'),
            subtitle: Text(appLocale.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context),
          ),

          const Divider(),

          // Notifications section
          _SectionHeader(title: 'Varsler'),
          _NotificationToggle(
            title: 'Nye aktiviteter',
            subtitle: 'Varsle nar nye aktiviteter opprettes',
            prefKey: _notifActivityKey,
            icon: Icons.event,
          ),
          _NotificationToggle(
            title: 'Paminnelser',
            subtitle: 'Paminnelser for kommende aktiviteter',
            prefKey: _notifReminderKey,
            icon: Icons.notifications_active,
          ),
          _NotificationToggle(
            title: 'Boter',
            subtitle: 'Varsler om nye boter og godkjenninger',
            prefKey: _notifFineKey,
            icon: Icons.receipt_long,
          ),

          const Divider(),

          // Account section
          _SectionHeader(title: 'Konto'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Eksporter data'),
            subtitle: const Text('Last ned alle dine data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExportDataDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Personvern'),
            subtitle: const Text('Les var personvernerklaering'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyInfo(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Slett konto', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Slett din konto permanent'),
            onTap: () => _showDeleteAccountConfirmation(context),
          ),

          const Divider(),

          // About section
          _SectionHeader(title: 'Om'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versjon'),
            subtitle: const Text('1.0.0'),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logg ut', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutConfirmation(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final currentTheme = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Velg tema'),
        content: RadioGroup<ThemeMode>(
          groupValue: currentTheme,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeModeProvider.notifier).setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                value: mode,
                title: Text(mode.displayName),
                secondary: Icon(mode.icon),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logg ut'),
        content: const Text('Er du sikker pa at du vil logge ut?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logg ut'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final currentLocale = ref.read(localeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Velg sprak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocale.values.map((locale) {
            return RadioListTile<AppLocale>(
              value: locale,
              groupValue: currentLocale,
              title: Text(locale.displayName),
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksporter data'),
        content: const Text(
          'Dine data vil bli sendt til din e-postadresse som en nedlastbar fil. '
          'Dette kan ta noen minutter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Eksportforespørsel sendt. Du vil motta en e-post snart.'),
                ),
              );
            },
            child: const Text('Eksporter'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personvern'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Core Idrett tar personvernet ditt pa alvor.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Vi samler inn folgende data:'),
              SizedBox(height: 8),
              Text('• Navn og e-postadresse for kontoen din'),
              Text('• Oppmote og aktivitetshistorikk'),
              Text('• Statistikk og poeng'),
              SizedBox(height: 12),
              Text('Dine data brukes kun til:'),
              SizedBox(height: 8),
              Text('• A tilby tjenesten'),
              Text('• A sende deg varsler'),
              Text('• A generere statistikk for laget ditt'),
              SizedBox(height: 12),
              Text('Du kan nar som helst eksportere eller slette dine data.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett konto'),
        content: const Text(
          'Er du sikker pa at du vil slette kontoen din? '
          'Denne handlingen kan ikke angres, og alle dine data vil bli permanent slettet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Slett konto'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bekreft sletting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skriv "SLETT" for a bekrefte sletting av kontoen din:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'SLETT',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              if (confirmController.text == 'SLETT') {
                Navigator.pop(context);
                try {
                  await ref.read(authRepositoryProvider).deleteAccount();
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kunne ikke slette konto: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Slett permanent'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final String prefKey;
  final IconData icon;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.prefKey,
    required this.icon,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(widget.prefKey) ?? true;
    });
  }

  Future<void> _savePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, value);
    setState(() {
      _enabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: _enabled,
      onChanged: _savePreference,
    );
  }
}
