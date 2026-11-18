import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flood_relief_app/core/widgets/app_button.dart';
import 'package:flood_relief_app/features/citizen/screens/c06_request_wizard_step4_review_submit_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c21_data_privacy_screen.dart';

void main() {
  testWidgets('C21DataPrivacyScreen displays data usage categories and legal basis', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: C21DataPrivacyScreen(),
    ));

    expect(find.text('Thông tin sử dụng dữ liệu'), findsOneWidget);
    expect(find.text('Chính sách bảo vệ dữ liệu cá nhân'), findsOneWidget);
    expect(find.textContaining('Số điện thoại & Họ tên'), findsOneWidget);
    expect(find.textContaining('Dữ liệu Vị trí GPS & Địa chỉ'), findsOneWidget);
    expect(find.textContaining('Nghị định 13/2023/NĐ-CP'), findsWidgets);
  });

  testWidgets('C06 ReviewSubmit shows consent checkbox but does NOT block submission when unticked', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: C06RequestWizardStep4ReviewSubmitScreen(
        reliefTypes: ['Thực phẩm'],
        totalPeople: 3,
        urgency: 'Cao',
        address: 'Thôn 1, Xã Lũ',
        landmark: 'Gần cây đa',
        photosCount: 0,
        photoNote: '',
      ),
    ));

    // Scroll down to make checkbox visible
    final checkboxFinder = find.byType(Checkbox);
    await tester.scrollUntilVisible(checkboxFinder, 200);
    await tester.pumpAndSettle();

    // Verify checkbox and notice exist
    expect(checkboxFinder, findsOneWidget);
    expect(
      find.textContaining('Tôi đồng ý cung cấp số điện thoại và vị trí'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Ưu tiên cứu trợ tính mạng'),
      findsOneWidget,
    );

    // Initial state: unticked
    final checkbox = tester.widget<Checkbox>(checkboxFinder);
    expect(checkbox.value, isFalse);

    // Verify submit button is STILL clickable and not disabled
    final submitButton = find.widgetWithText(AppButton, 'Gửi yêu cầu cứu trợ');
    expect(submitButton, findsOneWidget);
    final buttonWidget = tester.widget<AppButton>(submitButton);
    expect(buttonWidget.onPressed, isNotNull, reason: 'Must NOT block submission when consent is unticked');

    // Tap checkbox to tick
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    final tickedCheckbox = tester.widget<Checkbox>(checkboxFinder);
    expect(tickedCheckbox.value, isTrue);
  });
}
