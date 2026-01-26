import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

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
            onTap: () => _showEditProfileDialog(context),
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

  void _showEditProfileDialog(BuildContext context) {
    final user = ref.read(authStateProvider).value;
    final nameController = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rediger profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Navn',
                border: OutlineInputBorder(),
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
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(context);

              final result = await ref.read(authStateProvider.notifier).updateProfile(
                name: newName,
              );

              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil oppdatert')),
                );
              }
            },
            child: const Text('Lagre'),
          ),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              value: mode,
              groupValue: currentTheme,
              title: Text(mode.displayName),
              secondary: Icon(mode.icon),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
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
