import 'package:flutter/material.dart';

/// Link to toggle between login and signup modes
class AuthToggleModeLink extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const AuthToggleModeLink({
    super.key,
    required this.isLogin,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isLogin ? "Don't have an account? " : 'Already have an account? ',
            style: theme.textTheme.bodySmall,
          ),
          TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isLogin ? 'Sign Up' : 'Login',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
