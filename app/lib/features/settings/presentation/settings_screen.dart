import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'widgets/section_header.dart';
import 'widgets/notification_toggle.dart';
import 'widgets/settings_dialogs.dart';

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
          SectionHeader(title: 'Profil'),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: user?.avatarUrl != null
                  ? CachedNetworkImageProvider(user!.avatarUrl!)
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
          SectionHeader(title: 'Utseende'),
          ListTile(
            leading: Icon(themeMode.icon),
            title: const Text('Tema'),
            subtitle: Text(themeMode.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showThemePicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Sprak'),
            subtitle: Text(appLocale.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLanguagePicker(context, ref),
          ),

          const Divider(),

          // Notifications section
          SectionHeader(title: 'Varsler'),
          NotificationToggle(
            title: 'Nye aktiviteter',
            subtitle: 'Varsle nar nye aktiviteter opprettes',
            prefKey: _notifActivityKey,
            icon: Icons.event,
          ),
          NotificationToggle(
            title: 'Paminnelser',
            subtitle: 'Paminnelser for kommende aktiviteter',
            prefKey: _notifReminderKey,
            icon: Icons.notifications_active,
          ),
          NotificationToggle(
            title: 'Boter',
            subtitle: 'Varsler om nye boter og godkjenninger',
            prefKey: _notifFineKey,
            icon: Icons.receipt_long,
          ),

          const Divider(),

          // Account section
          SectionHeader(title: 'Konto'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Eksporter data'),
            subtitle: const Text('Last ned alle dine data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showExportDataDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Personvern'),
            subtitle: const Text('Les var personvernerklaering'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showPrivacyInfo(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Slett konto', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Slett din konto permanent'),
            onTap: () => showDeleteAccountConfirmation(context, ref),
          ),

          const Divider(),

          // About section
          SectionHeader(title: 'Om'),
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
            onTap: () => showLogoutConfirmation(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
