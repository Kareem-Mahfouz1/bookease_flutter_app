import 'package:flutter/material.dart';

/// Google sign-in button
class AuthGoogleSignInButton extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthGoogleSignInButton({
    super.key,
    required this.isLogin,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.asset('assets/google_icon.png', height: 20, width: 20),
        label: Text(
          isLogin ? 'Sign in with Google' : 'Sign up with Google',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
