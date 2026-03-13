import 'package:appointment_booking/core/helpers/validators.dart';
import 'package:appointment_booking/core/widgets/app_text_form_field.dart';
import 'package:flutter/material.dart';

/// Form widget containing all input fields and form-related UI
class AuthForm extends StatelessWidget {
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

  const AuthForm({
    super.key,
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
              ForgotPasswordLink(onPressed: onForgotPassword)
            else
              TermsCheckbox(
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
class ForgotPasswordLink extends StatelessWidget {
  final VoidCallback onPressed;

  const ForgotPasswordLink({super.key, required this.onPressed});

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
class TermsCheckbox extends StatelessWidget {
  final bool agreeToTerms;
  final ValueChanged<bool?> onChanged;

  const TermsCheckbox({
    super.key,
    required this.agreeToTerms,
    required this.onChanged,
  });

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
