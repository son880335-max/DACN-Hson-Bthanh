import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flood_relief_app/core/data/request_draft.dart';
import 'package:flood_relief_app/core/theme/app_theme.dart';
import 'package:flood_relief_app/core/widgets/location_picker.dart';
import 'package:flood_relief_app/features/citizen/screens/c03_request_wizard_step2_location_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final choice in ['adjust', 'gps', 'cancel']) {
    testWidgets('GPS map confirmation: $choice', (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        return switch (call.method) {
          'isLocationServiceEnabled' => true,
          'checkPermission' => 2,
          'getCurrentPosition' => {
            'latitude': 10.77,
            'longitude': 106.7,
            'accuracy': 12.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          _ => throw PlatformException(code: 'unexpected-test-call'),
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final draft = RequestDraft();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: C03RequestWizardStep2LocationScreen(
            reliefTypes: const ['Nước uống'],
            totalPeople: 1,
            urgency: 'Cao',
            draft: draft,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      await tester.tap(find.byTooltip('Lấy vị trí hiện tại'));
      await tester.pumpAndSettle();
      final picker = tester.widget<LocationPicker>(find.byType(LocationPicker));
      expect(picker.latitude, 10.77);
      expect(picker.longitude, 106.7);
      expect(picker.source, 'gps');
      expect(find.text('Kiểm tra vị trí GPS'), findsOneWidget);
      expect(draft.values['latitude'], isNull);
      if (choice == 'adjust') {
        await tester.enterText(find.byType(TextField).at(2), '10.78');
        await tester.enterText(find.byType(TextField).at(3), '106.71');
      }
      final confirm = find.text(
        choice == 'cancel' ? 'Quay lại' : 'Xác nhận vị trí',
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      if (choice == 'cancel') {
        expect(draft.values['latitude'], isNull);
        expect(draft.values['locationConfirmedAt'], isNull);
      } else {
        expect(draft.values['latitude'], choice == 'adjust' ? 10.78 : 10.77);
        expect(draft.values['longitude'], choice == 'adjust' ? 106.71 : 106.7);
        expect(
          draft.values['locationSource'],
          choice == 'adjust' ? 'pin' : 'gps',
        );
        expect(draft.values['locationConfirmedAt'], isNotNull);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'denying GPS explains the fallback without silently confirming a position',
    (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        return switch (call.method) {
          'isLocationServiceEnabled' => true,
          'checkPermission' => 0,
          'requestPermission' => 0,
          _ => throw PlatformException(code: 'unexpected-test-call'),
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final draft = RequestDraft();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: C03RequestWizardStep2LocationScreen(
            reliefTypes: const ['Nước uống'],
            totalPeople: 1,
            urgency: 'Cao',
            draft: draft,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Lấy vị trí hiện tại'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationPicker), findsNothing);
      expect(find.textContaining('Không lấy được GPS'), findsOneWidget);
      expect(draft.values['latitude'], isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
