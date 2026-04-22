import 'package:flutter/material.dart';

import '../../../core/navigation/app_tab.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_speed_dial.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/meds/presentation/pages/meds_page.dart';
import '../../../features/metrics/presentation/pages/metrics_page.dart';
import '../../../features/visits/presentation/pages/visits_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  AppTab _selectedTab = AppTab.dashboard;
  bool _isFabExpanded = false;

  void _selectTab(AppTab tab) {
    setState(() {
      _selectedTab = tab;
      _isFabExpanded = false;
    });
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
  }

  void _handleQuickAction(AppQuickAction action) {
    switch (action.id) {
      case 'add_bp_reading':
        _selectTab(AppTab.dashboard);
      case 'add_medication':
        _selectTab(AppTab.meds);
      case 'log_metric':
        _selectTab(AppTab.metrics);
      case 'book_appointment':
        _selectTab(AppTab.visits);
      default:
        setState(() {
          _isFabExpanded = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab.index,
            children: [
              const DashboardPage(),
              const MedsPage(),
              const MetricsPage(),
              const VisitsPage(),
              const _FeaturePlaceholderPage(
                title: 'Profile',
                subtitle: 'Profile screen will be connected next.',
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 28,
            child: AppSpeedDial(
              expanded: _isFabExpanded,
              onToggle: _toggleFab,
              onActionSelected: _handleQuickAction,
              actions: const [
                AppQuickAction(
                  id: 'add_bp_reading',
                  label: 'Add BP Reading',
                  color: Color(0xFF1DB954),
                ),
                AppQuickAction(
                  id: 'add_medication',
                  label: 'Add Medication',
                  color: Color(0xFF1595C9),
                ),
                AppQuickAction(
                  id: 'log_metric',
                  label: 'Log Metric',
                  color: Color(0xFF7C3AED),
                ),
                AppQuickAction(
                  id: 'book_appointment',
                  label: 'Book Appointment',
                  color: Color(0xFFEB8A06),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentTab: _selectedTab,
        onTabSelected: _selectTab,
      ),
    );
  }
}

class _FeaturePlaceholderPage extends StatelessWidget {
  const _FeaturePlaceholderPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFFBF2), Color(0xFFF8FFFA)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C1C46),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6F86A9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
