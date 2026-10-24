import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'r06_my_team_screen.dart';
import 'r07_waiting_tasks_screen.dart';
import 'r12_assigned_task_detail_screen.dart';
import 'r17_offline_download_screen.dart';

class RescueShellScreen extends StatefulWidget {
  final int initialIndex;
  const RescueShellScreen({super.key, this.initialIndex = 0});

  @override
  State<RescueShellScreen> createState() => _RescueShellScreenState();
}

class _RescueShellScreenState extends State<RescueShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    R07WaitingTasksScreen(),
    R12AssignedTaskDetailScreen(taskId: 'TASK-8801'),
    R17OfflineDownloadScreen(),
    R06MyTeamScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
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
    );
  }
}
