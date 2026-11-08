import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/widgets/sync_status.dart';
import '../../../core/theme/app_colors.dart';
import 'c01_home_screen.dart';
import 'c07_my_requests_screen.dart';
import 'c13_flood_map_screen.dart';
import 'c20_profile_screen.dart';
import 'c04_request_wizard_step3_photo_screen.dart';

class CitizenShellScreen extends StatefulWidget {
  final int initialIndex;
  const CitizenShellScreen({super.key, this.initialIndex = 0});

  @override
  State<CitizenShellScreen> createState() => _CitizenShellScreenState();
}

class _CitizenShellScreenState extends State<CitizenShellScreen> {
  late int _currentIndex;
  final Set<int> _visited = {};

  final List<Widget> _screens = const [
    C01HomeScreen(),
    C07MyRequestsScreen(),
    C13FloodMapScreen(),
    C20ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited.add(_currentIndex);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreCamera());
    }
  }

  Future<void> _restoreCamera() async {
    final owner = reliefRepository.account?['id'];
    try {
      final pending = await reliefRepository.hasPendingCamera();
      final draft = reliefRepository.draft;
      if (!mounted ||
          !pending ||
          draft == null ||
          owner != reliefRepository.account?['id']) {
        return;
      }
      final values = draft.values;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => C04RequestWizardStep3PhotoScreen(
            reliefTypes: List<String>.from(values['types']),
            totalPeople: values['people'],
            urgency: values['urgency'],
            address: values['address'],
            landmark: values['landmark'],
            draft: draft,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          'Chưa mở lại được ảnh. Bạn có thể tiếp tục từ bản nháp.',
        );
      }
    }
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
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.format_list_bulleted_outlined),
                activeIcon: Icon(Icons.format_list_bulleted),
                label: 'Yêu cầu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Bản đồ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
