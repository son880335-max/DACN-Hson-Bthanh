import 'package:flutter/material.dart';

import '../../requests/data/relief_request.dart';
import '../../requests/screens/request_wizard_screen.dart';

// Điểm vào tương thích cũ; luồng chính truyền toàn bộ RequestDraft trong một wizard.
class C03RequestWizardStep2LocationScreen extends StatelessWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;

  const C03RequestWizardStep2LocationScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
  });
  @override
  Widget build(BuildContext context) => RequestWizardScreen(
    initialStep: 1,
    initialData: RequestDraft()
      ..types = List.of(reliefTypes)
      ..people = totalPeople
      ..urgency = urgency,
  );
}
