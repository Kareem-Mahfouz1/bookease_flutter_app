import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  Future<void> loadTheme({required String saved}) async {
    emit(
      ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  void changeTheme(ThemeMode mode) {
    emit(mode);
    SharedPrefHelper.setData(SharedPrefKeys.themeMode, mode.name);
  }
}
