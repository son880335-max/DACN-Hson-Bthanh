import 'package:flutter_test/flutter_test.dart';
import 'package:flood_relief_app/core/data/request_draft.dart';
import 'package:flood_relief_app/core/data/request_presentation.dart';
import 'package:flood_relief_app/core/widgets/status_chip.dart';

RequestDraft validDraft() => RequestDraft(
  values: {
    ...RequestDraft().values,
    'types': ['Nước uống'],
    'people': 4,
    'description': 'Cần nước uống tại điểm thử',
    'latitude': 0.0,
    'longitude': 0.0,
    'locationSource': 'pin',
    'locationConfirmedAt': '2026-11-08T10:00:00Z',
    'landmark': 'Cổng màu xanh',
  },
);

void main() {
  test('invalid restored drafts cannot bypass the request form', () {
    final invalid = <Json>[
      {'types': null},
      {'types': []},
      {
        'types': ['Nước uống', 'Nước uống'],
      },
      {
        'types': ['unknown'],
      },
      {'people': null},
      {'people': 0},
      {'people': -1},
      {'people': 1.5},
      for (final field in ['elderly', 'children', 'disabled', 'special']) ...[
        {field: -1},
        {field: 5},
        {field: '1'},
      ],
      {'description': '  '},
      {'description': 'a' * 4001},
      {'urgency': 'Trung'},
      {'address': '', 'landmark': ''},
      {'latitude': double.nan},
      {'longitude': double.infinity},
      {'latitude': -91},
      {'longitude': 181},
      {'locationConfirmedAt': 'invalid'},
      {'locationSource': 'unknown'},
    ];
    for (final override in invalid) {
      final draft = validDraft()..values.addAll(override);
      expect(draft.validate(), isNotNull, reason: override.toString());
    }
  });
  test(
    'zero coordinates, a landmark and overlapping care groups remain valid',
    () {
      final draft = validDraft()
        ..values.addAll({
          'elderly': 4,
          'children': 4,
          'disabled': 4,
          'special': 4,
        });
      expect(draft.validate(), isNull);
      draft.values.remove('latitude');
      expect(draft.validate(location: false), isNull);
      expect(draft.validate(), isNotNull);
    },
  );
  test(
    'acceptance does not claim the team is moving; history hides field codes',
    () {
      expect(stageStatus('accepted'), ReliefStatus.assigned);
      expect(requestFieldLabel('people'), 'Số người');
      expect(requestFieldLabel('unknownCode'), 'Thông tin khác');
      expect(formatTimestamp('invalid'), 'Chưa có dữ liệu');
    },
  );
}
