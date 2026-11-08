import 'package:flutter/material.dart';

import '../data/relief_repository.dart';
import '../../features/auth/screens/a01_role_selection_screen.dart';
import 'sync_status.dart';

Future<void> signOut(BuildContext context) async {
  try {
    await reliefRepository.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const A01RoleSelectionScreen()),
      (_) => false,
    );
  } catch (_) {
    if (context.mounted) {
      showFailure(context, 'Chưa đăng xuất được. Hãy thử lại.');
    }
  }
}
