import 'package:appointment_booking/app.dart';
import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/theme/theme_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appointment_booking/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeMode = await SharedPrefHelper.getString(SharedPrefKeys.themeMode);
  final themeCubit = ThemeCubit();
  await themeCubit.loadTheme(saved: themeMode);

  runApp(BlocProvider.value(value: themeCubit, child: const MyApp()));
}
