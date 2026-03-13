import 'package:appointment_booking/core/routing/app_router.dart';
import 'package:appointment_booking/core/theme/theme_cubit.dart';
import 'package:appointment_booking/core/theme/themes.dart';
import 'package:appointment_booking/features/auth/data/repositories/auth_repository.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:appointment_booking/features/profile/data/profile_repository.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(AuthRepository(), ProfileRepository()),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) =>
              ProfileCubit(ProfileRepository(), FirebaseAuth.instance),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              routerConfig: AppRouter.router,
              themeMode: themeMode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
            );
          },
        ),
      ),
    );
  }
}
