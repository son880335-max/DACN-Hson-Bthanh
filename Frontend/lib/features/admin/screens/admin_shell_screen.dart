import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'm02_admin_dashboard_screen.dart';
import 'm03_admin_requests_lookup_screen.dart';
import 'm07_admin_pending_teams_screen.dart';
import 'm19_admin_statistics_screen.dart';

class AdminShellScreen extends StatefulWidget {
  final int initialIndex;
  const AdminShellScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _currentIndex;
  final Set<int> _visited = {};

  final List<Widget> _screens = const [
    M02AdminDashboardScreen(),
    M03AdminRequestsLookupScreen(),
    M07AdminPendingTeamsScreen(),
    M19AdminStatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited.add(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _visited.add(0);
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < _screens.length; i++)
              _visited.contains(i) ? _screens[i] : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _visited.add(index);
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Tổng quan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Yêu cầu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shield_outlined),
                activeIcon: Icon(Icons.shield),
                label: 'Đội cứu hộ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Thống kê',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
