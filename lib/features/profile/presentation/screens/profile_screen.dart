import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_state.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:appointment_booking/features/profile/presentation/widgets/profile_account_card.dart';
import 'package:appointment_booking/features/profile/presentation/widgets/profile_error_view.dart';
import 'package:appointment_booking/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:appointment_booking/features/profile/presentation/widgets/profile_section_label.dart';
import 'package:appointment_booking/features/profile/presentation/widgets/profile_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile on first entry (e.g. app restart with persisted session).
    // When coming from the auth screen the state is already ProfileSuccess,
    // so this guard prevents a redundant network call.
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is ProfileInitial) {
      cubit.loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSignedOut) {
          context.read<ProfileCubit>().reset();
          context.go(Routes.auth);
        }
      },
      child: Scaffold(
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return switch (state) {
              ProfileInitial() || ProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              ProfileFailure(:final message) => ProfileErrorView(
                message: message,
              ),
              ProfileSuccess(:final user) => _ProfileBody(user: user),
            };
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final AppUser user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: SizedBox.shrink(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Text(
                  'Profile',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Center(child: ProfileHeaderCard(user: user)),

              SizedBox(height: 24),
              const ProfileSectionLabel(label: 'Account'),
              SizedBox(height: 8),
              ProfileAccountCard(user: user),

              SizedBox(height: 24),
              const ProfileSectionLabel(label: 'Settings'),
              const SizedBox(height: 8),
              const ProfileSettingsCard(),

              // nav bar clearance
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}
