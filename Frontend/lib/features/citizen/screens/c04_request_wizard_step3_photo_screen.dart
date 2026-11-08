import 'package:flutter/material.dart';

import '../../requests/data/relief_request.dart';
import '../../requests/screens/request_wizard_screen.dart';

// Điểm vào tương thích cũ; luồng chính truyền toàn bộ RequestDraft trong một wizard.
class C04RequestWizardStep3PhotoScreen extends StatelessWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;
  final String address, landmark;

  const C04RequestWizardStep3PhotoScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    required this.address,
    required this.landmark,
  });
  @override
  Widget build(BuildContext context) => RequestWizardScreen(
    initialStep: 2,
    initialData: RequestDraft()
      ..types = List.of(reliefTypes)
      ..people = totalPeople
      ..urgency = urgency
      ..address = address
      ..landmark = landmark,
  );
}
