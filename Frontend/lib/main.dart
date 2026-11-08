import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/data/relief_repository.dart';
import 'features/citizen/screens/citizen_shell_screen.dart';
import 'features/admin/screens/admin_shell_screen.dart';
import 'features/rescue/screens/rescue_shell_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/a01_role_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 32 * 1024 * 1024;
  await reliefRepository.initialize();
  if (reliefRepository.signedIn) {
    reliefRepository.synchronizeInBackground();
  }
  runApp(const FloodReliefApp());
}

class FloodReliefApp extends StatelessWidget {
  const FloodReliefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cứu trợ đồng bào lũ lụt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: switch (reliefRepository.account?['role']) {
        'citizen' => const CitizenShellScreen(),
        'rescue' => const RescueShellScreen(),
        'admin' => const AdminShellScreen(),
        _ => const A01RoleSelectionScreen(),
      },
    );
  }
}
