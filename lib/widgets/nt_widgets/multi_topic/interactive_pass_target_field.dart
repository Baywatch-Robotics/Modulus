import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/services/field_images.dart';
import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/services/nt4_type.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_text_input.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_toggle_switch.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

enum PassTargetSelection { targetA, targetB }

class InteractivePassTargetFieldModel extends MultiTopicNTWidgetModel {
  static const String widgetType = 'Interactive Pass Target Field';
  static const int schemaVersion = 1;

  static const String _defaultGame = 'Rebuilt';
  static const String _allianceTopic = '/FMSInfo/IsRedAlliance';

  static const String targetAXMetersTopic =
      'ShooterCalculator/Pass/TargetA/XMeters';
  static const String targetAYMetersTopic =
      'ShooterCalculator/Pass/TargetA/YMeters';
  static const String targetAZMetersTopic =
      'ShooterCalculator/Pass/TargetA/ZMeters';

  static const String targetBXMetersTopic =
      'ShooterCalculator/Pass/TargetB/XMeters';
  static const String targetBYMetersTopic =
      'ShooterCalculator/Pass/TargetB/YMeters';
  static const String targetBZMetersTopic =
      'ShooterCalculator/Pass/TargetB/ZMeters';
  static const String targetBEnabledTopic =
      'ShooterCalculator/Pass/TargetB/Enabled';

  static const String targetAXInchesTopic =
      'ShooterCalculator/Tuning/PassTargets/TargetA/XInches';
  static const String targetAYInchesTopic =
      'ShooterCalculator/Tuning/PassTargets/TargetA/YInches';
  static const String targetBXInchesTopic =
      'ShooterCalculator/Tuning/PassTargets/TargetB/XInches';
  static const String targetBYInchesTopic =
      'ShooterCalculator/Tuning/PassTargets/TargetB/YInches';

  static const double metersPerInch = 0.0254;

  @override
  String type = widgetType;

  bool _showLabels = true;
  bool _allianceOriented = true;
  int _targetAKeyId = LogicalKeyboardKey.digit1.keyId;
  int _targetBKeyId = LogicalKeyboardKey.digit2.keyId;

  bool _metersToInchesSyncSuppressed = false;
  bool _inchesToMetersSyncSuppressed = false;

  bool get showLabels => _showLabels;
  bool get allianceOriented => _allianceOriented;
  int get targetAKeyId => _targetAKeyId;
  int get targetBKeyId => _targetBKeyId;

  set showLabels(bool value) {
    _showLabels = value;
    refresh();
  }

  set allianceOriented(bool value) {
    _allianceOriented = value;
    refresh();
  }

  set targetAKeyId(int value) {
    _targetAKeyId = value;
    refresh();
  }

  set targetBKeyId(int value) {
    _targetBKeyId = value;
    refresh();
  }

  late NT4Subscription targetAXMetersSubscription;
  late NT4Subscription targetAYMetersSubscription;
  late NT4Subscription targetAZMetersSubscription;

  late NT4Subscription targetBXMetersSubscription;
  late NT4Subscription targetBYMetersSubscription;
  late NT4Subscription targetBZMetersSubscription;
  late NT4Subscription targetBEnabledSubscription;

  late NT4Subscription targetAXInchesSubscription;
  late NT4Subscription targetAYInchesSubscription;
  late NT4Subscription targetBXInchesSubscription;
  late NT4Subscription targetBYInchesSubscription;

  late NT4Subscription allianceSubscription;

  @override
  List<NT4Subscription> get subscriptions => [
    targetAXMetersSubscription,
    targetAYMetersSubscription,
    targetAZMetersSubscription,
    targetBXMetersSubscription,
    targetBYMetersSubscription,
    targetBZMetersSubscription,
    targetBEnabledSubscription,
    targetAXInchesSubscription,
    targetAYInchesSubscription,
    targetBXInchesSubscription,
    targetBYInchesSubscription,
    allianceSubscription,
  ];

  late Field _field;
  Field get field => _field;

  InteractivePassTargetFieldModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    bool showLabels = true,
    bool allianceOriented = true,
    int? targetAKeyId,
    int? targetBKeyId,
    super.period,
  }) : _showLabels = showLabels,
       _allianceOriented = allianceOriented,
       _targetAKeyId = targetAKeyId ?? LogicalKeyboardKey.digit1.keyId,
       _targetBKeyId = targetBKeyId ?? LogicalKeyboardKey.digit2.keyId,
       super() {
    _field = FieldImages.getFieldFromGame(_defaultGame)!;
  }

  InteractivePassTargetFieldModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _showLabels = tryCast(jsonData['show_labels']) ?? true;
    _allianceOriented = tryCast(jsonData['alliance_oriented']) ?? true;
    _targetAKeyId =
        tryCast<num>(jsonData['target_a_key_id'])?.toInt() ??
        LogicalKeyboardKey.digit1.keyId;
    _targetBKeyId =
        tryCast<num>(jsonData['target_b_key_id'])?.toInt() ??
        LogicalKeyboardKey.digit2.keyId;

    _field = FieldImages.getFieldFromGame(_defaultGame)!;
  }

  @override
  void initializeSubscriptions() {
    targetAXMetersSubscription = ntConnection.subscribe(targetAXMetersTopic);
    targetAYMetersSubscription = ntConnection.subscribe(targetAYMetersTopic);
    targetAZMetersSubscription = ntConnection.subscribe(targetAZMetersTopic);

    targetBXMetersSubscription = ntConnection.subscribe(targetBXMetersTopic);
    targetBYMetersSubscription = ntConnection.subscribe(targetBYMetersTopic);
    targetBZMetersSubscription = ntConnection.subscribe(targetBZMetersTopic);
    targetBEnabledSubscription = ntConnection.subscribe(targetBEnabledTopic);

    targetAXInchesSubscription = ntConnection.subscribe(targetAXInchesTopic);
    targetAYInchesSubscription = ntConnection.subscribe(targetAYInchesTopic);
    targetBXInchesSubscription = ntConnection.subscribe(targetBXInchesTopic);
    targetBYInchesSubscription = ntConnection.subscribe(targetBYInchesTopic);

    allianceSubscription = ntConnection.subscribe(_allianceTopic);
  }

  @override
  void init() {
    super.init();

    targetAXMetersSubscription.addListener(_syncMetersToInches);
    targetAYMetersSubscription.addListener(_syncMetersToInches);
    targetBXMetersSubscription.addListener(_syncMetersToInches);
    targetBYMetersSubscription.addListener(_syncMetersToInches);

    targetAXInchesSubscription.addListener(_syncInchesToMeters);
    targetAYInchesSubscription.addListener(_syncInchesToMeters);
    targetBXInchesSubscription.addListener(_syncInchesToMeters);
    targetBYInchesSubscription.addListener(_syncInchesToMeters);
  }

  @override
  void resetSubscription() {
    targetAXMetersSubscription.removeListener(_syncMetersToInches);
    targetAYMetersSubscription.removeListener(_syncMetersToInches);
    targetBXMetersSubscription.removeListener(_syncMetersToInches);
    targetBYMetersSubscription.removeListener(_syncMetersToInches);

    targetAXInchesSubscription.removeListener(_syncInchesToMeters);
    targetAYInchesSubscription.removeListener(_syncInchesToMeters);
    targetBXInchesSubscription.removeListener(_syncInchesToMeters);
    targetBYInchesSubscription.removeListener(_syncInchesToMeters);

    super.resetSubscription();

    targetAXMetersSubscription.addListener(_syncMetersToInches);
    targetAYMetersSubscription.addListener(_syncMetersToInches);
    targetBXMetersSubscription.addListener(_syncMetersToInches);
    targetBYMetersSubscription.addListener(_syncMetersToInches);

    targetAXInchesSubscription.addListener(_syncInchesToMeters);
    targetAYInchesSubscription.addListener(_syncInchesToMeters);
    targetBXInchesSubscription.addListener(_syncInchesToMeters);
    targetBYInchesSubscription.addListener(_syncInchesToMeters);
  }

  @override
  void softDispose({bool deleting = false}) async {
    targetAXMetersSubscription.removeListener(_syncMetersToInches);
    targetAYMetersSubscription.removeListener(_syncMetersToInches);
    targetBXMetersSubscription.removeListener(_syncMetersToInches);
    targetBYMetersSubscription.removeListener(_syncMetersToInches);

    targetAXInchesSubscription.removeListener(_syncInchesToMeters);
    targetAYInchesSubscription.removeListener(_syncInchesToMeters);
    targetBXInchesSubscription.removeListener(_syncInchesToMeters);
    targetBYInchesSubscription.removeListener(_syncInchesToMeters);

    if (deleting) {
      await _field.dispose();
    }
  }

  bool get isRedAlliance => tryCast(allianceSubscription.value) ?? true;

  bool get shouldRotate180 => allianceOriented && isRedAlliance;

  bool get fieldReady => field.fieldImageLoaded;

  bool get hasMarkerWarnings => !targetAAvailable || !targetBAvailable;

  bool get targetAAvailable =>
      _readAxisMeters(targetAXMetersSubscription, targetAXInchesSubscription) !=
          null &&
      _readAxisMeters(targetAYMetersSubscription, targetAYInchesSubscription) !=
          null;

  bool get targetBAvailable =>
      _readAxisMeters(targetBXMetersSubscription, targetBXInchesSubscription) !=
          null &&
      _readAxisMeters(targetBYMetersSubscription, targetBYInchesSubscription) !=
          null;

  Offset? get targetAMeters {
    final x = _readAxisMeters(targetAXMetersSubscription, targetAXInchesSubscription);
    final y = _readAxisMeters(targetAYMetersSubscription, targetAYInchesSubscription);
    if (x == null || y == null) {
      return null;
    }
    return Offset(x, y);
  }

  Offset? get targetBMeters {
    final x = _readAxisMeters(targetBXMetersSubscription, targetBXInchesSubscription);
    final y = _readAxisMeters(targetBYMetersSubscription, targetBYInchesSubscription);
    if (x == null || y == null) {
      return null;
    }
    return Offset(x, y);
  }

  double get targetAZMeters =>
      tryCast<num>(targetAZMetersSubscription.value)?.toDouble() ?? 0.0;

  double get targetBZMeters =>
      tryCast<num>(targetBZMetersSubscription.value)?.toDouble() ?? 0.0;

  set targetAZMeters(double value) {
    _publishDouble(targetAZMetersTopic, value);
  }

  set targetBZMeters(double value) {
    _publishDouble(targetBZMetersTopic, value);
  }

  double? _readAxisMeters(NT4Subscription meterSub, NT4Subscription inchSub) {
    final meters = tryCast<num>(meterSub.value)?.toDouble();
    if (meters != null) {
      return meters;
    }

    final inches = tryCast<num>(inchSub.value)?.toDouble();
    if (inches != null) {
      return inches * metersPerInch;
    }

    return null;
  }

  LogicalKeyboardKey targetAKey() =>
      LogicalKeyboardKey.findKeyByKeyId(_targetAKeyId) ??
      LogicalKeyboardKey.digit1;

  LogicalKeyboardKey targetBKey() =>
      LogicalKeyboardKey.findKeyByKeyId(_targetBKeyId) ??
      LogicalKeyboardKey.digit2;

  static double metersToInches(double meters) => meters / metersPerInch;

  static double inchesToMeters(double inches) => inches * metersPerInch;

  Offset clampToFieldMeters(Offset meters) {
    final clampedX = meters.dx.clamp(0.0, _field.fieldWidthMeters);
    final clampedY = meters.dy.clamp(0.0, _field.fieldHeightMeters);
    return Offset(clampedX, clampedY);
  }

  void placeTarget(PassTargetSelection target, Offset metersPoint) {
    final clamped = clampToFieldMeters(metersPoint);

    if (target == PassTargetSelection.targetA) {
      _publishTarget(
        xMetersTopic: targetAXMetersTopic,
        yMetersTopic: targetAYMetersTopic,
        xInchesTopic: targetAXInchesTopic,
        yInchesTopic: targetAYInchesTopic,
        metersPoint: clamped,
      );
      return;
    }

    _publishTarget(
      xMetersTopic: targetBXMetersTopic,
      yMetersTopic: targetBYMetersTopic,
      xInchesTopic: targetBXInchesTopic,
      yInchesTopic: targetBYInchesTopic,
      metersPoint: clamped,
    );

    _publishBool(targetBEnabledTopic, true);
  }

  void _publishTarget({
    required String xMetersTopic,
    required String yMetersTopic,
    required String xInchesTopic,
    required String yInchesTopic,
    required Offset metersPoint,
  }) {
    final xInches = metersToInches(metersPoint.dx);
    final yInches = metersToInches(metersPoint.dy);

    _metersToInchesSyncSuppressed = true;
    _inchesToMetersSyncSuppressed = true;

    _publishDouble(xMetersTopic, metersPoint.dx);
    _publishDouble(yMetersTopic, metersPoint.dy);
    _publishDouble(xInchesTopic, xInches);
    _publishDouble(yInchesTopic, yInches);

    _metersToInchesSyncSuppressed = false;
    _inchesToMetersSyncSuppressed = false;
  }

  void _syncMetersToInches() {
    if (_metersToInchesSyncSuppressed) {
      return;
    }

    final axMeters = tryCast<num>(targetAXMetersSubscription.value)?.toDouble();
    final ayMeters = tryCast<num>(targetAYMetersSubscription.value)?.toDouble();
    final bxMeters = tryCast<num>(targetBXMetersSubscription.value)?.toDouble();
    final byMeters = tryCast<num>(targetBYMetersSubscription.value)?.toDouble();

    if (axMeters == null && ayMeters == null && bxMeters == null && byMeters == null) {
      return;
    }

    _inchesToMetersSyncSuppressed = true;

    if (axMeters != null) {
      _publishDouble(targetAXInchesTopic, metersToInches(axMeters));
    }
    if (ayMeters != null) {
      _publishDouble(targetAYInchesTopic, metersToInches(ayMeters));
    }
    if (bxMeters != null) {
      _publishDouble(targetBXInchesTopic, metersToInches(bxMeters));
    }
    if (byMeters != null) {
      _publishDouble(targetBYInchesTopic, metersToInches(byMeters));
    }

    _inchesToMetersSyncSuppressed = false;
  }

  void _syncInchesToMeters() {
    if (_inchesToMetersSyncSuppressed) {
      return;
    }

    final axInches = tryCast<num>(targetAXInchesSubscription.value)?.toDouble();
    final ayInches = tryCast<num>(targetAYInchesSubscription.value)?.toDouble();
    final bxInches = tryCast<num>(targetBXInchesSubscription.value)?.toDouble();
    final byInches = tryCast<num>(targetBYInchesSubscription.value)?.toDouble();

    if (axInches == null && ayInches == null && bxInches == null && byInches == null) {
      return;
    }

    _metersToInchesSyncSuppressed = true;

    if (axInches != null) {
      _publishDouble(targetAXMetersTopic, inchesToMeters(axInches));
    }
    if (ayInches != null) {
      _publishDouble(targetAYMetersTopic, inchesToMeters(ayInches));
    }
    if (bxInches != null) {
      _publishDouble(targetBXMetersTopic, inchesToMeters(bxInches));
    }
    if (byInches != null) {
      _publishDouble(targetBYMetersTopic, inchesToMeters(byInches));
    }

    _metersToInchesSyncSuppressed = false;
  }

  NT4Topic _ensureTopic(String topicName, NT4Type type) {
    NT4Topic? topic = ntConnection.getTopicFromName(topicName);
    topic ??= ntConnection.publishNewTopic(topicName, type);

    if (!ntConnection.isTopicPublished(topic)) {
      ntConnection.publishTopic(topic);
    }

    return topic;
  }

  void _publishDouble(String topicName, double value) {
    final topic = _ensureTopic(topicName, NT4Type.double());
    ntConnection.updateDataFromTopic(topic, value);
  }

  void _publishBool(String topicName, bool value) {
    final topic = _ensureTopic(topicName, NT4Type.boolean());
    ntConnection.updateDataFromTopic(topic, value);
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'custom_schema_version': schemaVersion,
    'show_labels': _showLabels,
    'alliance_oriented': _allianceOriented,
    'target_a_key_id': _targetAKeyId,
    'target_b_key_id': _targetBKeyId,
  };

  @override
  List<Widget> getEditProperties(BuildContext context) => [
    DialogToggleSwitch(
      label: 'Show Marker Labels',
      initialValue: _showLabels,
      onToggle: (value) => showLabels = value,
    ),
    DialogToggleSwitch(
      label: 'Alliance-Oriented View',
      initialValue: _allianceOriented,
      onToggle: (value) => allianceOriented = value,
    ),
    const SizedBox(height: 5),
    Row(
      children: [
        Expanded(
          child: DialogTextInput(
            label: 'Target A Key',
            initialText: targetAKey().keyLabel,
            onSubmit: (value) {
              if (value.isEmpty) {
                return;
              }

              final key = _fromKeyLabel(value);
              if (key == null) {
                return;
              }

              targetAKeyId = key.keyId;
            },
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: DialogTextInput(
            label: 'Target B Key',
            initialText: targetBKey().keyLabel,
            onSubmit: (value) {
              if (value.isEmpty) {
                return;
              }

              final key = _fromKeyLabel(value);
              if (key == null) {
                return;
              }

              targetBKeyId = key.keyId;
            },
          ),
        ),
      ],
    ),
  ];

  LogicalKeyboardKey? _fromKeyLabel(String keyLabel) {
    final upper = keyLabel.toUpperCase();
    if (upper == '1') return LogicalKeyboardKey.digit1;
    if (upper == '2') return LogicalKeyboardKey.digit2;
    if (upper == '3') return LogicalKeyboardKey.digit3;
    if (upper == '4') return LogicalKeyboardKey.digit4;
    if (upper == '5') return LogicalKeyboardKey.digit5;
    if (upper == '6') return LogicalKeyboardKey.digit6;
    if (upper == '7') return LogicalKeyboardKey.digit7;
    if (upper == '8') return LogicalKeyboardKey.digit8;
    if (upper == '9') return LogicalKeyboardKey.digit9;
    if (upper == '0') return LogicalKeyboardKey.digit0;
    return null;
  }
}

class InteractivePassTargetFieldWidget extends NTWidget {
  const InteractivePassTargetFieldWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final model = cast<InteractivePassTargetFieldModel>(
      context.watch<NTWidgetModel>(),
    );

    return _InteractivePassTargetFieldView(model: model);
  }
}

class _InteractivePassTargetFieldView extends StatefulWidget {
  final InteractivePassTargetFieldModel model;

  const _InteractivePassTargetFieldView({required this.model});

  @override
  State<_InteractivePassTargetFieldView> createState() =>
      _InteractivePassTargetFieldViewState();
}

class _InteractivePassTargetFieldViewState
    extends State<_InteractivePassTargetFieldView> {
  final FocusNode _focusNode = FocusNode();
  Offset? _hoverMeters;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _matchesKey(LogicalKeyboardKey eventKey, LogicalKeyboardKey wantedKey) {
    return eventKey.keyId == wantedKey.keyId;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _hoverMeters == null) {
      return KeyEventResult.ignored;
    }

    if (_matchesKey(event.logicalKey, widget.model.targetAKey())) {
      widget.model.placeTarget(PassTargetSelection.targetA, _hoverMeters!);
      return KeyEventResult.handled;
    }

    if (_matchesKey(event.logicalKey, widget.model.targetBKey())) {
      widget.model.placeTarget(PassTargetSelection.targetB, _hoverMeters!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Rect _fieldRect(Size size) {
    final fitted = applyBoxFit(
      BoxFit.contain,
      widget.model.field.fieldImageSize ?? const Size(1, 1),
      size,
    );

    final destination = fitted.destination;
    final left = (size.width - destination.width) / 2;
    final top = (size.height - destination.height) / 2;

    return Rect.fromLTWH(left, top, destination.width, destination.height);
  }

  Offset? _localToMeters(Offset localPosition, Rect fieldRect) {
    if (!fieldRect.contains(localPosition) || !widget.model.fieldReady) {
      return null;
    }

    final imageScale = fieldRect.width / widget.model.field.fieldImageSize!.width;

    final imageX = (localPosition.dx - fieldRect.left) / imageScale;
    final imageY = (localPosition.dy - fieldRect.top) / imageScale;

    double transformedX = imageX;
    double transformedY = imageY;

    if (widget.model.shouldRotate180) {
      transformedX = widget.model.field.fieldImageSize!.width - imageX;
      transformedY = widget.model.field.fieldImageSize!.height - imageY;
    }

    final metersX =
        (transformedX - widget.model.field.topLeftCorner.dx) /
        widget.model.field.pixelsPerMeterHorizontal;

    final metersY =
        widget.model.field.fieldHeightMeters -
        ((transformedY - widget.model.field.topLeftCorner.dy) /
            widget.model.field.pixelsPerMeterVertical);

    return widget.model.clampToFieldMeters(Offset(metersX, metersY));
  }

  Offset? _metersToLocal(Offset meters, Rect fieldRect) {
    if (!widget.model.fieldReady) {
      return null;
    }

    final imageScale = fieldRect.width / widget.model.field.fieldImageSize!.width;

    double imageX =
        widget.model.field.topLeftCorner.dx +
        (meters.dx * widget.model.field.pixelsPerMeterHorizontal);
    double imageY =
        widget.model.field.topLeftCorner.dy +
        ((widget.model.field.fieldHeightMeters - meters.dy) *
            widget.model.field.pixelsPerMeterVertical);

    if (widget.model.shouldRotate180) {
      imageX = widget.model.field.fieldImageSize!.width - imageX;
      imageY = widget.model.field.fieldImageSize!.height - imageY;
    }

    return Offset(
      fieldRect.left + (imageX * imageScale),
      fieldRect.top + (imageY * imageScale),
    );
  }

  Widget _marker({
    required String label,
    required Color color,
    required Offset localPosition,
  }) {
    return Positioned(
      left: localPosition.dx - 10,
      top: localPosition.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: widget.model.showLabels
            ? Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              )
            : null,
      ),
    );
  }

  Widget _zInput({
    required String label,
    required double initial,
    required ValueChanged<double> onSubmitted,
  }) {
    final controller = TextEditingController(text: initial.toStringAsFixed(3));

    return SizedBox(
      width: 106,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          labelText: label,
          labelStyle: Theme.of(context).textTheme.labelSmall,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
        ],
        onSubmitted: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            onSubmitted(parsed);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rect = _fieldRect(size);
        final targetA = widget.model.targetAMeters;
        final targetB = widget.model.targetBMeters;

        final targetALocal = targetA == null ? null : _metersToLocal(targetA, rect);
        final targetBLocal = targetB == null ? null : _metersToLocal(targetB, rect);

        return Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKey,
          child: MouseRegion(
            onEnter: (_) => _focusNode.requestFocus(),
            onHover: (details) {
              final hoverMeters = _localToMeters(details.localPosition, rect);
              if (hoverMeters == null) {
                return;
              }

              setState(() {
                _hoverMeters = hoverMeters;
              });
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.rotate(
                    angle: widget.model.shouldRotate180 ? pi : 0,
                    child: Image(
                      image: widget.model.field.fieldImage.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (targetALocal != null)
                  _marker(
                    label: 'A',
                    color: Colors.orange,
                    localPosition: targetALocal,
                  ),
                if (targetBLocal != null)
                  _marker(
                    label: 'B',
                    color: Colors.purple,
                    localPosition: targetBLocal,
                  ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.model.targetAKey().keyLabel}: Target A   ${widget.model.targetBKey().keyLabel}: Target B',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      _zInput(
                        label: 'A Z (m)',
                        initial: widget.model.targetAZMeters,
                        onSubmitted: (value) {
                          widget.model.targetAZMeters = value;
                        },
                      ),
                      const SizedBox(width: 6),
                      _zInput(
                        label: 'B Z (m)',
                        initial: widget.model.targetBZMeters,
                        onSubmitted: (value) {
                          widget.model.targetBZMeters = value;
                        },
                      ),
                    ],
                  ),
                ),
                if (widget.model.hasMarkerWarnings)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'One or more target topics unavailable',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                if (!widget.model.fieldReady)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        'Field metadata unavailable',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
