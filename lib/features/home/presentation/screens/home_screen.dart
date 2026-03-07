import 'package:appointment_booking/features/home/presentation/widgets/hero_section.dart';
import 'package:appointment_booking/features/home/presentation/widgets/services_section.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: const [
          HeroSection(),
          ServicesSection(),
          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
