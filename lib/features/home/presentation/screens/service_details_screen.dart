import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:appointment_booking/core/routing/route_names.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const ServiceDetailsScreen({super.key, required this.serviceData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final serviceName = serviceData['serviceName'] as String? ?? 'Service';
    final description =
        serviceData['description'] as String? ?? 'Description not available.';
    final duration = serviceData['duration'] as String? ?? 'N/A';
    final price = serviceData['price'] as String? ?? 'N/A';
    final imageUrl = serviceData['imageUrl'] as String?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ServiceDetailsAppBar(
            serviceName: serviceName,
            imageUrl: imageUrl,
            theme: theme,
          ),
          _ServiceDetailsContent(
            serviceName: serviceName,
            price: price,
            description: description,
            duration: duration,
            theme: theme,
          ),
        ],
      ),
      floatingActionButton: _ServiceDetailsFloatingButton(
        serviceData: serviceData,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ServiceDetailsAppBar extends StatelessWidget {
  const _ServiceDetailsAppBar({
    required this.serviceName,
    required this.imageUrl,
    required this.theme,
  });

  final String serviceName;
  final String? imageUrl;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          serviceName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        background: Image.network(
          (imageUrl != null && imageUrl!.isNotEmpty)
              ? imageUrl!
              : 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?q=80&w=1470&auto=format&fit=crop', // default massage image
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: theme.primaryColor,
            child: const Center(
              child: Icon(Icons.spa, size: 80, color: Colors.white),
            ),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

class _ServiceDetailsContent extends StatelessWidget {
  const _ServiceDetailsContent({
    required this.serviceName,
    required this.price,
    required this.description,
    required this.duration,
    required this.theme,
  });

  final String serviceName;
  final String price;
  final String description;
  final String duration;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '4.9 (124 reviews)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.access_time, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text('Duration: $duration', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 120), // Bottom padding for fixed bottom area
          ],
        ),
      ),
    );
  }
}

class _ServiceDetailsFloatingButton extends StatelessWidget {
  const _ServiceDetailsFloatingButton({required this.serviceData});

  final Map<String, dynamic> serviceData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.push(Routes.bookingCalendar, extra: serviceData);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 8,
            shadowColor: theme.primaryColor.withValues(alpha: 0.5),
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
