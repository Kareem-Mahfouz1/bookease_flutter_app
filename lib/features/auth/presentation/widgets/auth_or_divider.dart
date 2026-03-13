import 'package:flutter/material.dart';

/// Divider with "Or continue with" text
class AuthOrDivider extends StatelessWidget {
  final bool isLogin;

  const AuthOrDivider({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            isLogin ? 'Or continue with' : 'Or sign up with',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }
}
