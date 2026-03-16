import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/core/models/service_model.dart';
import 'package:appointment_booking/core/helpers/service_icon_mapper.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final serviceName = service.name;
    final description = service.description;
    final duration = '${service.durationMinutes} min';
    final price = '\$${service.price.toStringAsFixed(2)}';
    final imageUrl = service.imageUrl;
    final rating = service.rating;
    final iconData = getServiceIcon(service.iconName);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ServiceDetailsAppBar(
            imageUrl: imageUrl,
            iconData: iconData,
            theme: theme,
          ),
          _ServiceDetailsContent(
            serviceName: serviceName,
            price: price,
            description: description,
            duration: duration,
            rating: rating,
            theme: theme,
          ),
        ],
      ),
      floatingActionButton: _ServiceDetailsFloatingButton(serviceData: service),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ServiceDetailsAppBar extends StatelessWidget {
  const _ServiceDetailsAppBar({
    required this.imageUrl,
    required this.iconData,
    required this.theme,
  });

  final String? imageUrl;
  final IconData iconData;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.primaryColor,
                  child: Center(
                    child: Icon(iconData, size: 150, color: Colors.white),
                  ),
                ),
              )
            : Container(
                color: theme.primaryColor,
                child: Center(
                  child: Icon(iconData, size: 150, color: Colors.white),
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
    required this.rating,
    required this.theme,
  });

  final String serviceName;
  final String price;
  final String description;
  final String duration;
  final double rating;
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
            _StarRating(rating: rating, theme: theme),
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
            SizedBox(
              height: MediaQuery.of(context).padding.bottom + 100,
            ), // Dynamic bottom padding for floating button
          ],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.theme});

  final double rating;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            final icon = index < rating.floor()
                ? Icons.star
                : (index < rating ? Icons.star_half : Icons.star_border);
            return Icon(icon, color: Colors.amber, size: 20);
          }),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
          ),
        ),
      ],
    );
  }
}

class _ServiceDetailsFloatingButton extends StatelessWidget {
  const _ServiceDetailsFloatingButton({required this.serviceData});

  final ServiceModel serviceData;

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
          child: Text(
            'Book Now',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
