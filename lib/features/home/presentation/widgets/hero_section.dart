import 'package:appointment_booking/core/widgets/search_field.dart';
import 'package:appointment_booking/features/home/logic/home_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:appointment_booking/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 190.h,
      floating: true,
      pinned: false,
      elevation: 0,
      backgroundColor: isDark
          ? Color.fromARGB(255, 71, 103, 129)
          : theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      theme.primaryColor.withValues(alpha: 0.7),
                      theme.primaryColor.withValues(alpha: 0.5),
                    ]
                  : [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroHeader(),
                const SizedBox(height: 10),
                const _HeroTitle(),
                const SizedBox(height: 10),
                SearchField(
                  onChanged: (value) =>
                      context.read<HomeCubit>().searchServices(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Welcome back ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileSuccess) {
                      return Text(
                        state.user.displayName ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text('');
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Book',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'Ease',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () async {
            // final firestore = FirestoreService();
            final services = [
              {
                "name": "General Checkup",
                "description":
                    "A comprehensive routine examination to assess your overall health and detect any potential issues early.",
                "imageUrl": "",
                "iconName": "medical_services",
                "durationMinutes": 30,
                "price": 50.0,
                "rating": 3.8,
                "isActive": true,
              },
              {
                "name": "Blood Test",
                "description":
                    "Full blood count and analysis to evaluate your general health and detect a wide range of conditions.",
                "imageUrl": "",
                "iconName": "biotech",
                "durationMinutes": 15,
                "price": 35.0,
                "rating": 2.5,
                "isActive": true,
              },
              {
                "name": "Heart Screening",
                "description":
                    "Electrocardiogram and cardiovascular assessment to monitor your heart health and detect irregularities.",
                "imageUrl": "",
                "iconName": "monitor_heart",
                "durationMinutes": 45,
                "price": 120.0,
                "rating": 4.9,
                "isActive": true,
              },
              {
                "name": "Vaccination",
                "description":
                    "Scheduled immunization services for adults and children covering a wide range of preventable diseases.",
                "imageUrl": "",
                "iconName": "vaccines",
                "durationMinutes": 15,
                "price": 25.0,
                "rating": 4.2,
                "isActive": true,
              },
              {
                "name": "Eye Examination",
                "description":
                    "Thorough vision and eye health assessment including pressure check and retinal evaluation.",
                "imageUrl": "",
                "iconName": "visibility",
                "durationMinutes": 30,
                "price": 60.0,
                "rating": 4.7,
                "isActive": true,
              },
              {
                "name": "Dental Cleaning",
                "description":
                    "Professional teeth cleaning and oral health examination to maintain hygiene and prevent dental issues.",
                "imageUrl": "",
                "iconName": "tooth",
                "durationMinutes": 45,
                "price": 80.0,
                "rating": 4.6,
                "isActive": true,
              },
              {
                "name": "Mental Health Consultation",
                "description":
                    "A private session with a licensed psychologist to discuss mental wellbeing, stress, and coping strategies.",
                "imageUrl": "",
                "iconName": "psychology",
                "durationMinutes": 60,
                "price": 100.0,
                "rating": 4.9,
                "isActive": true,
              },
              {
                "name": "Dermatology Consultation",
                "description":
                    "Skin assessment and treatment planning for conditions such as acne, eczema, and other dermatological concerns.",
                "imageUrl": "",
                "iconName": "medical_services",
                "durationMinutes": 30,
                "price": 90.0,
                "rating": 4.4,
                "isActive": true,
              },
            ];
            final clinicSchedule = [
              {
                'dayOfWeek': 1,
                'startTime': '09:00',
                'endTime': '17:00',
                'isWorkingDay': true,
              },
              {
                'dayOfWeek': 2,
                'startTime': '09:00',
                'endTime': '17:00',
                'isWorkingDay': true,
              },
              {
                'dayOfWeek': 3,
                'startTime': '09:00',
                'endTime': '17:00',
                'isWorkingDay': true,
              },
              {
                'dayOfWeek': 4,
                'startTime': '09:00',
                'endTime': '13:00',
                'isWorkingDay': true,
              },
              {
                'dayOfWeek': 5,
                'startTime': '00:00',
                'endTime': '00:00',
                'isWorkingDay': false,
              },
              {
                'dayOfWeek': 6,
                'startTime': '09:00',
                'endTime': '17:00',
                'isWorkingDay': true,
              },
              {
                'dayOfWeek': 7,
                'startTime': '09:00',
                'endTime': '17:00',
                'isWorkingDay': false,
              },
            ];

            final firestore = FirebaseFirestore.instance;

            for (final day in clinicSchedule) {
              await firestore
                  .collection('clinic_schedule')
                  .doc(day['dayOfWeek'].toString())
                  .set(day);
              print('Seeded schedule for day: ${day['dayOfWeek']}');
            }

            print('Clinic schedule seeding complete.');

            // for (var service in services) {
            //   await firestore.addDocument(
            //     collectionPath: 'services',
            //     data: service,
            //   );
            // }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Services seeded successfully! Pull to refresh.',
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: const Icon(Icons.code, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Find your perfect service',
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
