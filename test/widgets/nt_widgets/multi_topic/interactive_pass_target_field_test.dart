import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elastic_dashboard/services/field_images.dart';
import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/services/nt4_type.dart';
import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/services/nt_widget_registry.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/multi_topic/interactive_pass_target_field.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';
import '../../../test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late NTConnection ntConnection;
  late Map<String, dynamic> virtualValues;

  final json = {
    'topic': '/SmartDashboard',
    'period': 0.1,
    'custom_schema_version': 1,
    'show_labels': true,
    'alliance_oriented': true,
    'target_a_key_id': LogicalKeyboardKey.digit1.keyId,
    'target_b_key_id': LogicalKeyboardKey.digit2.keyId,
  };

  setUpAll(() async {
    await FieldImages.loadFields('assets/fields/');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();

    virtualValues = {
      InteractivePassTargetFieldModel.targetAXMetersTopic: 1.0,
      InteractivePassTargetFieldModel.targetAYMetersTopic: 2.0,
      InteractivePassTargetFieldModel.targetAZMetersTopic: 0.3,
      InteractivePassTargetFieldModel.targetBXMetersTopic: 3.0,
      InteractivePassTargetFieldModel.targetBYMetersTopic: 4.0,
      InteractivePassTargetFieldModel.targetBZMetersTopic: 0.4,
      InteractivePassTargetFieldModel.targetBEnabledTopic: false,
      InteractivePassTargetFieldModel.targetAXInchesTopic: 39.3700787,
      InteractivePassTargetFieldModel.targetAYInchesTopic: 78.7401574,
      InteractivePassTargetFieldModel.targetBXInchesTopic: 118.110236,
      InteractivePassTargetFieldModel.targetBYInchesTopic: 157.480315,
      '/FMSInfo/IsRedAlliance': true,
    };

    ntConnection = createMockOnlineNT4(
      virtualTopics: [
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetAXMetersTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetAYMetersTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetAZMetersTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetBXMetersTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetBYMetersTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetBZMetersTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetBEnabledTopic,
          type: NT4Type.boolean(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetAXInchesTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetAYInchesTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetBXInchesTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: InteractivePassTargetFieldModel.targetBYInchesTopic,
          type: NT4Type.double(),
          properties: {},
        ),
        NT4Topic(
          name: '/FMSInfo/IsRedAlliance',
          type: NT4Type.boolean(),
          properties: {},
        ),
      ],
      virtualValues: virtualValues,
    );
  });

  test('Interactive pass target field from json', () {
    final model = NTWidgetRegistry.buildNTModelFromJson(
      ntConnection,
      preferences,
      InteractivePassTargetFieldModel.widgetType,
      json,
    );

    expect(model.runtimeType, InteractivePassTargetFieldModel);

    final passModel = model as InteractivePassTargetFieldModel;
    expect(passModel.showLabels, isTrue);
    expect(passModel.allianceOriented, isTrue);
    expect(passModel.targetAKeyId, LogicalKeyboardKey.digit1.keyId);
    expect(passModel.targetBKeyId, LogicalKeyboardKey.digit2.keyId);
  });

  test('Interactive pass target field to json', () {
    final model = InteractivePassTargetFieldModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: '/SmartDashboard',
      period: 0.1,
      showLabels: true,
      allianceOriented: true,
      targetAKeyId: LogicalKeyboardKey.digit1.keyId,
      targetBKeyId: LogicalKeyboardKey.digit2.keyId,
    );

    expect(model.toJson(), json);
  });

  test('Target placement updates meter and inch topics', () {
    final model = InteractivePassTargetFieldModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: '/SmartDashboard',
    );

    model.placeTarget(PassTargetSelection.targetA, const Offset(2.5, 1.25));

    expect(
      virtualValues[InteractivePassTargetFieldModel.targetAXMetersTopic],
      closeTo(2.5, 1e-8),
    );
    expect(
      virtualValues[InteractivePassTargetFieldModel.targetAYMetersTopic],
      closeTo(1.25, 1e-8),
    );
    expect(
      virtualValues[InteractivePassTargetFieldModel.targetAXInchesTopic],
      closeTo(98.42519685, 1e-6),
    );
    expect(
      virtualValues[InteractivePassTargetFieldModel.targetAYInchesTopic],
      closeTo(49.21259842, 1e-6),
    );

    model.placeTarget(PassTargetSelection.targetB, const Offset(100.0, -2.0));

    expect(
      virtualValues[InteractivePassTargetFieldModel.targetBXMetersTopic],
      lessThanOrEqualTo(model.field.fieldWidthMeters),
    );
    expect(
      virtualValues[InteractivePassTargetFieldModel.targetBYMetersTopic],
      greaterThanOrEqualTo(0.0),
    );
    expect(
      virtualValues[InteractivePassTargetFieldModel.targetBEnabledTopic],
      isTrue,
    );
  });
}
