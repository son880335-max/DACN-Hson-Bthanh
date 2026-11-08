import 'package:flutter/material.dart';

import '../../requests/data/relief_request.dart';
import '../../requests/screens/request_wizard_screen.dart';

// Điểm vào tương thích cũ; luồng chính truyền toàn bộ RequestDraft trong một wizard.
class C06RequestWizardStep4ReviewSubmitScreen extends StatelessWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;
  final String address, landmark;
  final int photosCount;
  final String photoNote;
  const C06RequestWizardStep4ReviewSubmitScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    required this.address,
    required this.landmark,
    required this.photosCount,
    required this.photoNote,
  });
  @override
  Widget build(BuildContext context) => RequestWizardScreen(
    initialStep: 3,
    initialData: RequestDraft()
      ..types = List.of(reliefTypes)
      ..people = totalPeople
      ..urgency = urgency
      ..address = address
      ..landmark = landmark
      ..description = photoNote,
  );
}
