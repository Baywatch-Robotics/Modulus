import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:modulus/widgets/dialog_widgets/dialog_toggle_switch.dart';
import 'package:modulus/widgets/gesture/repeat_press_gesture.dart';
import 'package:modulus/widgets/nt_widgets/nt_widget.dart';

class ToggleButtonModel extends SingleTopicNTWidgetModel {
  @override
  String type = ToggleButton.widgetType;

  bool _holdToRepeat = false;

  bool get holdToRepeat => _holdToRepeat;

  set holdToRepeat(bool value) {
    _holdToRepeat = value;
    refresh();
  }

  ToggleButtonModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    bool holdToRepeat = false,
    super.ntStructMeta,
    super.dataType,
    super.period,
  }) : _holdToRepeat = holdToRepeat,
       super();

  ToggleButtonModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _holdToRepeat = tryCast(jsonData['hold_to_repeat']) ?? _holdToRepeat;
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'hold_to_repeat': holdToRepeat,
  };

  @override
  List<Widget> getEditProperties(BuildContext context) => [
    DialogToggleSwitch(
      label: 'Hold To Repeat',
      initialValue: _holdToRepeat,
      onToggle: (value) {
        holdToRepeat = value;
      },
    ),
  ];

  void triggerToggle() {
    bool currentValue = tryCast<bool>(subscription?.value) ?? false;

    bool publishTopic =
        ntTopic == null || !ntConnection.isTopicPublished(ntTopic);

    createTopicIfNull();

    if (ntTopic == null) {
      return;
    }

    if (publishTopic) {
      ntConnection.publishTopic(ntTopic!);
    }

    ntConnection.updateDataFromTopic(ntTopic!, !currentValue);
  }
}

class ToggleButton extends NTWidget {
  static const String widgetType = 'Toggle Button';

  const ToggleButton({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    ToggleButtonModel model = cast(context.watch<NTWidgetModel>());

    return ValueListenableBuilder(
      valueListenable: model.subscription!,
      builder: (context, data, child) {
        bool value = tryCast(data) ?? false;

        String buttonText = model.topic.substring(
          model.topic.lastIndexOf('/') + 1,
        );

        Size buttonSize = MediaQuery.of(context).size;

        ThemeData theme = Theme.of(context);

        return RepeatPressGesture(
          onPressed: () {
            if (model.ntStructMeta != null) return;

            model.triggerToggle();
          },
          repeatEnabled: model.holdToRepeat,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSize.width * 0.01,
              vertical: buttonSize.height * 0.01,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 10),
              width: buttonSize.width,
              height: buttonSize.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 2),
                    blurRadius: 10.0,
                    spreadRadius: -5,
                    color: Colors.black,
                  ),
                ],
                color: (value)
                    ? theme.colorScheme.primaryContainer
                    : const Color.fromARGB(255, 50, 50, 50),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
