import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/home/presentation/widgets/service_card.dart';
import 'package:appointment_booking/features/home/logic/home_cubit.dart';
import 'package:appointment_booking/features/home/logic/home_state.dart';
import 'package:appointment_booking/core/helpers/service_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ServicesSection extends StatelessWidget {
  final int itemCount;
  const ServicesSection({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is HomeFailure) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(state.message)),
          );
        }

        if (state is HomeSuccess) {
          final services = state.services;

          if (services.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No services found.')),
            );
          }

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
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ServiceCard(
                      icon: getServiceIcon(service.iconName),
                      serviceName: service.name,
                      description: service.description,
                      duration: "${service.durationMinutes} min",
                      price: "\$${service.price.toStringAsFixed(2)}",
                      onTap: () {
                        context.push(Routes.serviceDetails, extra: service);
                      },
                    ),
                  ),
                ),
              ]),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}
