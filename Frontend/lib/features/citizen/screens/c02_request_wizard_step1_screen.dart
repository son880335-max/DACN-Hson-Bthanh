import 'package:flutter/material.dart';

import '../../requests/screens/request_wizard_screen.dart';

class C02RequestWizardStep1Screen extends StatelessWidget {
  final bool isDraft;
  const C02RequestWizardStep1Screen({super.key, this.isDraft = false});
  @override
  Widget build(BuildContext context) =>
      RequestWizardScreen(resumeDraft: isDraft);
}
