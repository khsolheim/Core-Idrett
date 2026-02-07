import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

void showThemePicker(BuildContext context, WidgetRef ref) {
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

void showLogoutConfirmation(BuildContext context, WidgetRef ref) {
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

void showLanguagePicker(BuildContext context, WidgetRef ref) {
  final currentLocale = ref.read(localeProvider);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Velg sprak'),
      content: RadioGroup<AppLocale>(
        groupValue: currentLocale,
        onChanged: (value) {
          if (value != null) {
            ref.read(localeProvider.notifier).setLocale(value);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocale.values.map((locale) {
            return RadioListTile<AppLocale>(
              value: locale,
              title: Text(locale.displayName),
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

void showExportDataDialog(BuildContext context) {
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

void showPrivacyInfo(BuildContext context) {
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

void showDeleteAccountConfirmation(BuildContext context, WidgetRef ref) {
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
            showFinalDeleteConfirmation(context, ref);
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

void showFinalDeleteConfirmation(BuildContext context, WidgetRef ref) {
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
