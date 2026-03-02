import 'package:appointment_booking/widgets/service_card.dart';
import 'package:flutter/material.dart';

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
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
