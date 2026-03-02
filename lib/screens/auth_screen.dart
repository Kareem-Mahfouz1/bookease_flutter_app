import 'package:appointment_booking/core/helpers/validators.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/core/theme/themes.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_text_form_field.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _authMode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login
          ? AuthMode.signup
          : AuthMode.login;
    });
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final authCubit = context.read<AuthCubit>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: authCubit,
        child: AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                AppTextFormField(
                  controller: emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            context.read<AuthCubit>().sendPasswordResetEmail(
                              email: emailController.text.trim(),
                            );
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.go(Routes.main);
        }

        if (state is AuthFailure) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Authentication Failed'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        if (state is PasswordResetEmailSent) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Email Sent'),
              content: const Text(
                'A password reset link has been sent to your email. Please check your inbox and follow the instructions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: PopScope(
        canPop: isLogin,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !isLogin) {
            _toggleAuthMode();
          }
        },
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  _AuthHeader(isLogin: isLogin),
                  const SizedBox(height: 40),
                  _AuthForm(
                    formKey: _formKey,
                    isLogin: isLogin,
                    fullNameController: _fullNameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    agreeToTerms: _agreeToTerms,
                    onTogglePasswordVisibility: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    onToggleConfirmPasswordVisibility: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    onToggleTerms: (value) {
                      setState(() => _agreeToTerms = value ?? false);
                    },
                    onForgotPassword: () {
                      _showForgotPasswordDialog(context);
                    },
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return _SubmitButton(
                        isLogin: isLogin,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  // TODO: Add terms acceptance validation
                                  // before signup (if required).

                                  if (isLogin) {
                                    context.read<AuthCubit>().signIn(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                  } else {
                                    context.read<AuthCubit>().signUp(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      fullName: _fullNameController.text.trim(),
                                    );
                                  }
                                }
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _OrDivider(isLogin: isLogin),
                  const SizedBox(height: 24),
                  _GoogleSignInButton(
                    isLogin: isLogin,
                    onPressed: () {
                      // TODO: Implement Google sign in
                    },
                  ),
                  const SizedBox(height: 24),
                  _ToggleAuthModeLink(
                    isLogin: isLogin,
                    onToggle: _toggleAuthMode,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header widget displaying the app logo and welcome message
class _AuthHeader extends StatelessWidget {
  final bool isLogin;

  const _AuthHeader({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Book',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'Ease',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isLogin ? 'Welcome back' : 'Create your account',
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// Form widget containing all input fields and form-related UI
class _AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLogin;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreeToTerms;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final ValueChanged<bool?> onToggleTerms;
  final VoidCallback onForgotPassword;

  const _AuthForm({
    required this.formKey,
    required this.isLogin,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agreeToTerms,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.onToggleTerms,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(isLogin),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLogin) ...[
              AppTextFormField(
                controller: fullNameController,
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                keyboardType: TextInputType.name,
                prefixIcon: const Icon(Icons.person_outlined),
                validator: Validators.name,
              ),
              const SizedBox(height: 24),
            ],
            AppTextFormField(
              controller: emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: Validators.email,
            ),
            const SizedBox(height: 24),
            AppTextFormField(
              controller: passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              obscureText: obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              validator: Validators.password,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: onTogglePasswordVisibility,
              ),
            ),
            if (!isLogin) ...[
              const SizedBox(height: 24),
              AppTextFormField(
                controller: confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                obscureText: obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                validator: (value) =>
                    Validators.confirmPassword(value, passwordController.text),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: onToggleConfirmPasswordVisibility,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isLogin)
              _ForgotPasswordLink(onPressed: onForgotPassword)
            else
              _TermsCheckbox(
                agreeToTerms: agreeToTerms,
                onChanged: onToggleTerms,
              ),
          ],
        ),
      ),
    );
  }
}

/// Forgot password link for login mode
class _ForgotPasswordLink extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForgotPasswordLink({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Terms and conditions checkbox for signup mode
class _TermsCheckbox extends StatelessWidget {
  final bool agreeToTerms;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({required this.agreeToTerms, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Checkbox(value: agreeToTerms, onChanged: onChanged),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'I agree to the ',
                  style: theme.textTheme.bodySmall,
                ),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary submit button (Login/Create Account)
class _SubmitButton extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.isLogin,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isLogin ? 'Login' : 'Create Account',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Divider with "Or continue with" text
class _OrDivider extends StatelessWidget {
  final bool isLogin;

  const _OrDivider({required this.isLogin});

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

/// Google sign-in button
class _GoogleSignInButton extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.isLogin, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset('assets/google_icon.png', height: 20, width: 20),
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

/// Link to toggle between login and signup modes
class _ToggleAuthModeLink extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const _ToggleAuthModeLink({required this.isLogin, required this.onToggle});

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
