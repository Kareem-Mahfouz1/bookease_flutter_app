import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

IconData getServiceIcon(String iconName) {
  const icons = {
    'medical_services': Icons.medical_services,
    'spa': Icons.spa,
    'dentist': Symbols.dentistry,
    'biotech': Icons.biotech,
    'monitor_heart': Icons.monitor_heart,
    'vaccines': Icons.vaccines,
    'visibility': Icons.visibility,
    'psychology': Icons.psychology,
  };

  return icons[iconName] ?? Icons.spa; // fallback icon
}
