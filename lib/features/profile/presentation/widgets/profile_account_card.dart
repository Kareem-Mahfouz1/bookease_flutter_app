import 'package:appointment_booking/features/profile/presentation/widgets/profile_icon_tile.dart';
import 'package:flutter/material.dart';

/// Card containing account-level actions: Edit Profile and Change Password.
class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ProfileIconTile(
            iconData: Icons.edit_outlined,
            iconBg: theme.colorScheme.primaryContainer,
            iconFg: theme.colorScheme.onPrimaryContainer,
            title: 'Edit Profile',
            subtitle: 'Update your name and photo',
            onTap: () {
              // TODO: navigate to edit profile
            },
          ),
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant,
          ),
          ProfileIconTile(
            iconData: Icons.lock_outline_rounded,
            iconBg: theme.colorScheme.tertiaryContainer,
            iconFg: theme.colorScheme.onTertiaryContainer,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              // TODO: email users only
            },
          ),
        ],
      ),
    );
  }
}
