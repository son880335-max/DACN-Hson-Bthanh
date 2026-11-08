import 'package:flutter/material.dart';

import '../../requests/data/relief_request.dart';
import '../../requests/screens/request_list_screen.dart';

class M03AdminRequestsLookupScreen extends StatelessWidget {
  const M03AdminRequestsLookupScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const RequestListScreen(role: DemoRole.admin);
}
