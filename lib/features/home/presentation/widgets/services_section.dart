import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/home/presentation/widgets/service_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesSection extends StatelessWidget {
  final int itemCount;
  const ServicesSection({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Popular Services',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: ServiceCard(
                icon: Icons.spa,
                serviceName: "Massage Therapy",
                description: "Relaxing body massage",
                duration: "60 min",
                price: "\$80",
                onTap: () {
                  context.push(
                    Routes.serviceDetails,
                    extra: {
                      'serviceName': "Massage Therapy",
                      'description':
                          "Experience ultimate relaxation with our signature body massage. Our expert therapists use a combination of techniques to relieve muscle tension, improve circulation, and promote overall well-being. This soothing treatment is tailored to address your specific needs, leaving you feeling refreshed and rejuvenated.",
                      'duration': "60 min",
                      'price': "\$80",
                    },
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
