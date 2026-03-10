import 'package:appointment_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Card containing app settings: Appearance, Language and Sign Out.
class ProfileSettingsCard extends StatefulWidget {
  const ProfileSettingsCard({super.key});

  @override
  State<ProfileSettingsCard> createState() => _ProfileSettingsCardState();
}

class _ProfileSettingsCardState extends State<ProfileSettingsCard> {
  // UI-only for now; wired up when ThemeCubit is implemented
  String _selectedAppearance = 'system';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _AppearanceTile(
            selected: _selectedAppearance,
            onChanged: (value) => setState(() => _selectedAppearance = value),
          ),
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),
          const _LanguageTile(),
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),
          _SignOutTile(onTap: () => _showSignOutDialog(context)),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              authCubit.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Appearance ───────────────────────────────────────────────────────────────

class _AppearanceTile extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _AppearanceTile({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.contrast_rounded,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Appearance', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: theme.textTheme.labelSmall,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'light',
                      icon: Icon(Icons.light_mode_outlined, size: 15),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: 'system',
                      icon: Icon(Icons.brightness_auto_outlined, size: 15),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      icon: Icon(Icons.dark_mode_outlined, size: 15),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {selected},
                  onSelectionChanged: (value) {
                    onChanged(value.first);
                    // TODO: wire up to ThemeCubit
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language ─────────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.language_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: const Text('Language'),
        subtitle: const Text('Coming soon'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'English',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Out ─────────────────────────────────────────────────────────────────

class _SignOutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.logout_rounded,
          size: 20,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      title: Text(
        'Sign Out',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
