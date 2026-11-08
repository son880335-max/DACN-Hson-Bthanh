import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'r06_my_team_screen.dart';
import 'r07_waiting_tasks_screen.dart';
import 'r17_offline_download_screen.dart';

class RescueShellScreen extends StatefulWidget {
  final int initialIndex;
  const RescueShellScreen({super.key, this.initialIndex = 0});

  @override
  State<RescueShellScreen> createState() => _RescueShellScreenState();
}

class _RescueShellScreenState extends State<RescueShellScreen> {
  late int _currentIndex;
  final Set<int> _visited = {};

  final List<Widget> _screens = const [
    R07WaitingTasksScreen(),
    R07WaitingTasksScreen(),
    R17OfflineDownloadScreen(embedded: true),
    R06MyTeamScreen(),
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
                icon: Icon(Icons.emergency_outlined),
                activeIcon: Icon(Icons.emergency),
                label: 'Nhiệm vụ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task_alt_outlined),
                activeIcon: Icon(Icons.task_alt),
                label: 'Đang xử lý',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download_for_offline_outlined),
                activeIcon: Icon(Icons.download_for_offline),
                label: 'Ngoại tuyến',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'Đội cứu hộ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
