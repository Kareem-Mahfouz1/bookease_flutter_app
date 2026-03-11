import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildSlide(
                theme: theme,
                title: 'Find Services',
                description:
                    'Discover a wide range of professional services in your area.',
                imagePath: 'assets/onboarding1.png',
              ),
              _buildSlide(
                theme: theme,
                title: 'Easy Booking',
                description:
                    'Book appointments with just a few taps. Simple and convenient.',
                imagePath: 'assets/onboarding2.png',
              ),
              _buildSlide(
                theme: theme,
                title: 'Get Started',
                description:
                    'Join us today and enjoy seamless service booking experience.',
                imagePath: 'assets/onboarding3.png',
              ),
            ],
          ),
          // Bottom Navigation and Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(dotHeight: 10, dotWidth: 10),
                    onDotClicked: (index) {},
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (_currentPage < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              // Mark onboarding as completed and navigate to main screen
                              await SharedPrefHelper.setData(
                                SharedPrefKeys.keyOnboardingCompleted,
                                true,
                              );
                              if (context.mounted) {
                                context.go(Routes.auth);
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required ThemeData theme,
    required String title,
    required String description,
    required String imagePath,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.2),
            SizedBox(
              height: screenHeight * 0.35,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 60),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
                height: 1.5,
              ),
            ),
            SizedBox(height: 120.h),
          ],
        ),
      ),
    );
  }
}
