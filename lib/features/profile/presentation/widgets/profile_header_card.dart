import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Top card showing the user's avatar, display name, email and join date.
class ProfileHeaderCard extends StatelessWidget {
  final AppUser user;

  const ProfileHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            _ProfileAvatar(user: user),
            const SizedBox(height: 16),
            Text(
              user.displayName?.isNotEmpty == true
                  ? user.displayName!
                  : 'No name set',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Member since ${_formatDate(user.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final AppUser user;

  const _ProfileAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = user.photoUrl?.isNotEmpty == true;

    if (hasPhoto) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(user.photoUrl!),
        backgroundColor: theme.colorScheme.primaryContainer,
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(user),
          style: TextStyle(
            color: Colors.white,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  static String _getInitials(AppUser user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return user.email[0].toUpperCase();
  }
}
