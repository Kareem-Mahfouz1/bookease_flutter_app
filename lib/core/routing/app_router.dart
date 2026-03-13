import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/auth/presentation/screens/auth_screen.dart';
import 'package:appointment_booking/features/root/error_screen.dart';
import 'package:appointment_booking/features/root/main_screen.dart';
import 'package:appointment_booking/features/onboarding/screens/onboarding_screen.dart';
import 'package:appointment_booking/features/root/splash_screen.dart';
import 'package:appointment_booking/features/home/presentation/screens/service_details_screen.dart';
import 'package:appointment_booking/features/booking/presentation/screens/booking_calendar_screen.dart';
import 'package:appointment_booking/features/booking/presentation/screens/booking_details_screen.dart';
import 'package:appointment_booking/features/booking/presentation/screens/booking_success_screen.dart';
import 'package:appointment_booking/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:appointment_booking/features/booking/data/repositories/booking_repository.dart';
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
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const AuthScreen()),
      ),
      GoRoute(
        path: Routes.serviceDetails,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            key: state.pageKey,
            child: ServiceDetailsScreen(serviceData: extra),
          );
        },
      ),
      GoRoute(
        path: Routes.bookingCalendar,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            key: state.pageKey,
            // Provide Cubit at the router level so it persists across the booking flow
            child: BlocProvider(
              create: (context) => BookingCubit(BookingRepository()),
              child: BookingCalendarScreen(serviceData: extra),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.bookingDetails,
        pageBuilder: (context, state) {
          final cubit = state.extra as BookingCubit;
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider.value(
              value: cubit,
              child: const BookingDetailsScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.bookingSuccess,
        pageBuilder: (context, state) {
          final cubit = state.extra as BookingCubit;
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider.value(
              value: cubit,
              child: const BookingSuccessScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.editProfile,
        pageBuilder: (context, state) {
          final profileState = context.read<ProfileCubit>().state;
          final user = (profileState as ProfileSuccess).user;
          return MaterialPage(
            key: state.pageKey,
            child: EditProfileScreen(user: user),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(errorPath: state.uri.path),
    ),
  );
}
