import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulus/services/nt4_client.dart';
import 'package:modulus/services/nt4_type.dart';
import 'package:modulus/services/nt_connection.dart';
import 'package:modulus/services/nt_widget_registry.dart';
import 'package:modulus/widgets/nt_widgets/single_topic/rebuilt_period_clock.dart';
import '../../../test_util.dart';

void main() {
  late SharedPreferences preferences;
  late NTConnection ntConnection;

  final json = {
    'topic': 'Test/MatchTime',
    'data_type': 'double',
    'period': 0.1,
    'custom_schema_version': 1,
    'auto_winner_red': false,
    'auto_winner_configured': true,
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();

    ntConnection = createMockOnlineNT4(
      virtualTopics: [
        NT4Topic(name: 'Test/MatchTime', type: NT4Type.double(), properties: {}),
      ],
      virtualValues: {'Test/MatchTime': 160.0},
    );
  });

  test('Rebuilt period clock from json', () {
    final model = NTWidgetRegistry.buildNTModelFromJson(
      ntConnection,
      preferences,
      RebuiltPeriodClockModel.widgetType,
      json,
    );

    expect(model.runtimeType, RebuiltPeriodClockModel);

    final clockModel = model as RebuiltPeriodClockModel;
    expect(clockModel.autoWinnerRed, isFalse);
    expect(clockModel.autoWinnerConfigured, isTrue);
  });

  test('Rebuilt period clock to json', () {
    final model = RebuiltPeriodClockModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/MatchTime',
      period: 0.1,
      autoWinnerRed: false,
      autoWinnerConfigured: true,
      dataType: NT4Type.double(),
    );

    expect(model.toJson(), json);
  });

  test('Rebuilt period timeline segmentation', () {
    final model = RebuiltPeriodClockModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/MatchTime',
      autoWinnerRed: true,
      autoWinnerConfigured: true,
      dataType: NT4Type.double(),
    );

    expect(model.segmentForSeconds(160)?.name, 'Auto');
    expect(model.segmentForSeconds(140)?.name, 'Transition');
    expect(model.segmentForSeconds(130)?.name, 'Alliance Shift 1');
    expect(model.segmentForSeconds(105)?.name, 'Alliance Shift 2');
    expect(model.segmentForSeconds(80)?.name, 'Alliance Shift 3');
    expect(model.segmentForSeconds(55)?.name, 'Alliance Shift 4');
    expect(model.segmentForSeconds(30)?.name, 'Endgame');

    expect(model.remainingSecondsInPeriod(128), 23);
    expect(model.remainingSecondsInPeriod(52), 22);
  });

  test('Shift ownership alternates from auto loser', () {
    final redAutoWinner = RebuiltPeriodClockModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/MatchTime',
      autoWinnerRed: true,
      autoWinnerConfigured: true,
      dataType: NT4Type.double(),
    );

    expect(redAutoWinner.ownerIsRed(130), isFalse);
    expect(redAutoWinner.ownerIsRed(100), isTrue);
    expect(redAutoWinner.ownerIsRed(70), isFalse);
    expect(redAutoWinner.ownerIsRed(40), isTrue);

    final blueAutoWinner = RebuiltPeriodClockModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/MatchTime',
      autoWinnerRed: false,
      autoWinnerConfigured: true,
      dataType: NT4Type.double(),
    );

    expect(blueAutoWinner.ownerIsRed(130), isTrue);
    expect(blueAutoWinner.ownerIsRed(100), isFalse);
    expect(blueAutoWinner.ownerIsRed(70), isTrue);
    expect(blueAutoWinner.ownerIsRed(40), isFalse);
  });
}
