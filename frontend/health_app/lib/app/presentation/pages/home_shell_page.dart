import 'package:flutter/material.dart';

import '../../../core/navigation/app_tab.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_speed_dial.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/meds/presentation/pages/meds_page.dart';
import '../../../features/metrics/presentation/pages/metrics_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../../features/visits/presentation/pages/visits_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final _dashboardPageKey = GlobalKey<DashboardPageState>();
  final _medsPageKey = GlobalKey<MedsPageState>();
  final _metricsPageKey = GlobalKey<MetricsPageState>();
  final _visitsPageKey = GlobalKey<VisitsPageState>();
  final _profilePageKey = GlobalKey<ProfilePageState>();
  AppTab _selectedTab = AppTab.dashboard;
  bool _isFabExpanded = false;

  void _selectTab(AppTab tab) {
    setState(() {
      _selectedTab = tab;
      _isFabExpanded = false;
    });

    if (tab == AppTab.profile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profilePageKey.currentState?.refreshProfile();
      });
    }
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _dashboardPageKey.currentState?.openCreateReadingSheet();
        });
        return;
      case 'add_medication':
        _selectTab(AppTab.meds);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _medsPageKey.currentState?.openCreateMedicationSheet();
        });
        return;
      case 'log_metric':
        _selectTab(AppTab.metrics);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _metricsPageKey.currentState?.openQuickLogMetricSheet();
        });
        return;
      case 'book_appointment':
        _selectTab(AppTab.visits);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _visitsPageKey.currentState?.openCreateAppointmentSheet();
        });
        return;
      default:
        setState(() {
          _isFabExpanded = false;
        });
        return;
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
              DashboardPage(key: _dashboardPageKey),
              MedsPage(key: _medsPageKey),
              MetricsPage(key: _metricsPageKey),
              VisitsPage(key: _visitsPageKey),
              ProfilePage(key: _profilePageKey),
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
                  label: 'Добавить давление',
                  color: Color(0xFF1DB954),
                ),
                AppQuickAction(
                  id: 'add_medication',
                  label: 'Добавить препарат',
                  color: Color(0xFF1595C9),
                ),
                AppQuickAction(
                  id: 'log_metric',
                  label: 'Записать метрику',
                  color: Color(0xFF7C3AED),
                ),
                AppQuickAction(
                  id: 'book_appointment',
                  label: 'Записать на прием',
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
