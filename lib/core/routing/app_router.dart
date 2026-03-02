import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/data/repositories/auth_repository.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:appointment_booking/screens/auth_screen.dart';
import 'package:appointment_booking/screens/error_screen.dart';
import 'package:appointment_booking/screens/main_screen.dart';
import 'package:appointment_booking/screens/onboarding_screen.dart';
import 'package:appointment_booking/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// The application router configuration using GoRouter
class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isOnboardingCompleted = await SharedPrefHelper.getBool(
        SharedPrefKeys.keyOnboardingCompleted,
      );
      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;

      if (!isOnboardingCompleted) {
        return location == Routes.onboarding ? null : Routes.onboarding;
      }

      if (!isAuthenticated) {
        return location == Routes.auth ? null : Routes.auth;
      }

      if (location == Routes.splash || location == Routes.auth) {
        return Routes.main;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.main,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MainScreen()),
      ),

      GoRoute(
        path: Routes.auth,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => AuthCubit(AuthRepository()),
            child: const AuthScreen(),
          ),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(errorPath: state.uri.path),
    ),
  );
}
