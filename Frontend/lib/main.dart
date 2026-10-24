import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/a01_role_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const A01RoleSelectionScreen(),
    );
  }
}
