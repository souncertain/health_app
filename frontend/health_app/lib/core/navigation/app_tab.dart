import 'package:flutter/material.dart';

enum AppTab { dashboard, meds, metrics, visits, profile }

extension AppTabPresentation on AppTab {
  String get label {
    switch (this) {
      case AppTab.dashboard:
        return 'Dashboard';
      case AppTab.meds:
        return 'Meds';
      case AppTab.metrics:
        return 'Metrics';
      case AppTab.visits:
        return 'Visits';
      case AppTab.profile:
        return 'Profile';
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
