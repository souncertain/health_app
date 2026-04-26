import 'package:flutter/material.dart';

enum AppTab { dashboard, meds, metrics, visits, profile }

extension AppTabPresentation on AppTab {
  String get label {
    switch (this) {
      case AppTab.dashboard:
        return 'Главная';
      case AppTab.meds:
        return 'Препараты';
      case AppTab.metrics:
        return 'Метрики';
      case AppTab.visits:
        return 'Визиты';
      case AppTab.profile:
        return 'Профиль';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.dashboard:
        return Icons.monitor_heart_outlined;
      case AppTab.meds:
        return Icons.medication_outlined;
      case AppTab.metrics:
        return Icons.bar_chart_rounded;
      case AppTab.visits:
        return Icons.calendar_month_rounded;
      case AppTab.profile:
        return Icons.person_outline_rounded;
    }
  }
}
