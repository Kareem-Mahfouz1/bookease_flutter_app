import 'package:appointment_booking/features/favorites/presentation/screens/favourites_screen.dart';
import 'package:appointment_booking/features/home/presentation/screens/home_screen.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    MyBookingsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth > 600 ? 50.0 : 30.0;
    final bottomMargin = 20.h;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (!isKeyboardOpen)
            Positioned(
              bottom: bottomMargin,
              left: horizontalMargin,
              right: horizontalMargin,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: .1)
                          : Colors.black.withValues(alpha: .1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: GNav(
                    gap: 8,
                    activeColor: theme.primaryColor,
                    iconSize: 24,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12,
                    ),
                    duration: const Duration(milliseconds: 200),
                    tabBackgroundColor: theme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    color: theme.disabledColor,
                    tabs: const [
                      GButton(icon: Icons.home, text: 'Home'),
                      GButton(icon: Icons.event_available, text: 'My Bookings'),
                      GButton(icon: Icons.person, text: 'Profile'),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
