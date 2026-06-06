import 'package:flutter/material.dart';

import '../../domain/entities/blood_pressure_reading.dart';

class BloodPressureCategoryStyle {
  const BloodPressureCategoryStyle({
    required this.label,
    required this.accent,
    required this.softBackground,
    required this.iconBackground,
    required this.icon,
  });

  final String label;
  final Color accent;
  final Color softBackground;
  final Color iconBackground;
  final IconData icon;
}

BloodPressureCategoryStyle resolveBloodPressureCategoryStyle(
  BloodPressureCategory category,
) {
  switch (category) {
    case BloodPressureCategory.normal:
      return const BloodPressureCategoryStyle(
        label: 'Норма',
        accent: Color(0xFF1DB954),
        softBackground: Color(0xFFE7FAED),
        iconBackground: Color(0xFFDDF8E5),
        icon: Icons.favorite_border_rounded,
      );
    case BloodPressureCategory.elevated:
      return const BloodPressureCategoryStyle(
        label: 'Повышено',
        accent: Color(0xFFF59E0B),
        softBackground: Color(0xFFFFF3DA),
        iconBackground: Color(0xFFFFEFD9),
        icon: Icons.north_rounded,
      );
    case BloodPressureCategory.highStage1:
      return const BloodPressureCategoryStyle(
        label: 'Гипертензия 1',
        accent: Color(0xFFF97316),
        softBackground: Color(0xFFFFE7D6),
        iconBackground: Color(0xFFFFEFD9),
        icon: Icons.warning_amber_rounded,
      );
    case BloodPressureCategory.highStage2:
      return const BloodPressureCategoryStyle(
        label: 'Гипертензия 2',
        accent: Color(0xFFEF4444),
        softBackground: Color(0xFFFFE3E3),
        iconBackground: Color(0xFFFFE4EA),
        icon: Icons.priority_high_rounded,
      );
    case BloodPressureCategory.hypertensiveCrisis:
      return const BloodPressureCategoryStyle(
        label: 'Критично',
        accent: Color(0xFFC81E1E),
        softBackground: Color(0xFFFFD7D7),
        iconBackground: Color(0xFFFFD6D6),
        icon: Icons.error_outline_rounded,
      );
  }
}

BloodPressureCategoryStyle resolveBloodPressureCategoryKeyStyle(
  String category,
) {
  switch (category) {
    case 'requiresPediatricAssessment':
      return const BloodPressureCategoryStyle(
        label: 'Детская оценка',
        accent: Color(0xFF2563EB),
        softBackground: Color(0xFFE8F0FF),
        iconBackground: Color(0xFFDDE9FF),
        icon: Icons.child_care_rounded,
      );
    case 'normal':
      return resolveBloodPressureCategoryStyle(BloodPressureCategory.normal);
    case 'elevated':
      return resolveBloodPressureCategoryStyle(BloodPressureCategory.elevated);
    case 'highStage1':
      return resolveBloodPressureCategoryStyle(
        BloodPressureCategory.highStage1,
      );
    case 'highStage2':
      return resolveBloodPressureCategoryStyle(
        BloodPressureCategory.highStage2,
      );
    case 'hypertensiveCrisis':
      return resolveBloodPressureCategoryStyle(
        BloodPressureCategory.hypertensiveCrisis,
      );
    default:
      return const BloodPressureCategoryStyle(
        label: 'Нет данных',
        accent: Color(0xFF7C8EA8),
        softBackground: Color(0xFFF0F4F8),
        iconBackground: Color(0xFFE8EEF5),
        icon: Icons.info_outline_rounded,
      );
  }
}
