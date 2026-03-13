import 'package:appointment_booking/core/helpers/validators.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_state.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/auth/presentation/widgets/auth_form.dart';
import 'package:appointment_booking/features/auth/presentation/widgets/auth_google_sign_in_button.dart';
import 'package:appointment_booking/features/auth/presentation/widgets/auth_header.dart';
import 'package:appointment_booking/features/auth/presentation/widgets/auth_or_divider.dart';
import 'package:appointment_booking/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:appointment_booking/features/auth/presentation/widgets/auth_toggle_mode_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking/core/widgets/app_text_form_field.dart';

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
          context.read<ProfileCubit>().loadProfile();
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
                  AuthHeader(isLogin: isLogin),
                  const SizedBox(height: 40),
                  AuthForm(
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

                      return AuthSubmitButton(
                        isLogin: isLogin,
                        isLoading: isLoading,
                        onPressed: state.isLoading
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
                  AuthOrDivider(isLogin: isLogin),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is GoogleSignInLoading;

                      return AuthGoogleSignInButton(
                        isLogin: isLogin,
                        isLoading: isLoading,
                        onPressed: state.isLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().signInWithGoogle();
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AuthToggleModeLink(
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
