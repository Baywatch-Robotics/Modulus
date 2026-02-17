import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_toggle_switch.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class RebuiltPeriodSegment {
  final String name;
  final int startSeconds;
  final int endSeconds;
  final int? shiftIndex;

  const RebuiltPeriodSegment({
    required this.name,
    required this.startSeconds,
    required this.endSeconds,
    this.shiftIndex,
  });

  bool contains(int seconds) {
    if (endSeconds == 0) {
      return seconds <= startSeconds && seconds >= endSeconds;
    }

    return seconds <= startSeconds && seconds > endSeconds;
  }
}

class RebuiltPeriodClockModel extends SingleTopicNTWidgetModel {
  static const String widgetType = 'Rebuilt Period Clock';
  static const int schemaVersion = 1;

  @override
  String type = widgetType;

  bool _autoWinnerRed = true;
  bool _autoWinnerConfigured = false;

  bool get autoWinnerRed => _autoWinnerRed;
  bool get autoWinnerConfigured => _autoWinnerConfigured;

  set autoWinnerRed(bool value) {
    _autoWinnerRed = value;
    _autoWinnerConfigured = true;
    refresh();
  }

  static const List<RebuiltPeriodSegment> timeline = [
    RebuiltPeriodSegment(name: 'Auto', startSeconds: 160, endSeconds: 140),
    RebuiltPeriodSegment(
      name: 'Transition',
      startSeconds: 140,
      endSeconds: 130,
    ),
    RebuiltPeriodSegment(
      name: 'Alliance Shift 1',
      startSeconds: 130,
      endSeconds: 105,
      shiftIndex: 0,
    ),
    RebuiltPeriodSegment(
      name: 'Alliance Shift 2',
      startSeconds: 105,
      endSeconds: 80,
      shiftIndex: 1,
    ),
    RebuiltPeriodSegment(
      name: 'Alliance Shift 3',
      startSeconds: 80,
      endSeconds: 55,
      shiftIndex: 2,
    ),
    RebuiltPeriodSegment(
      name: 'Alliance Shift 4',
      startSeconds: 55,
      endSeconds: 30,
      shiftIndex: 3,
    ),
    RebuiltPeriodSegment(name: 'Endgame', startSeconds: 30, endSeconds: 0),
  ];

  RebuiltPeriodClockModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    bool autoWinnerRed = true,
    bool autoWinnerConfigured = false,
    super.ntStructMeta,
    super.dataType,
    super.period,
  }) : _autoWinnerRed = autoWinnerRed,
       _autoWinnerConfigured = autoWinnerConfigured,
       super();

  RebuiltPeriodClockModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _autoWinnerRed = tryCast(jsonData['auto_winner_red']) ?? true;
    _autoWinnerConfigured =
        tryCast(jsonData['auto_winner_configured']) ?? false;
  }

  RebuiltPeriodSegment? segmentForSeconds(num seconds) {
    final rounded = seconds.floor();

    for (final segment in timeline) {
      if (segment.contains(rounded)) {
        return segment;
      }
    }

    return null;
  }

  int remainingSecondsInPeriod(num seconds) {
    final segment = segmentForSeconds(seconds);
    if (segment == null) {
      return 0;
    }

    return (seconds.floor() - segment.endSeconds).clamp(0, 9999);
  }

  bool? ownerIsRed(num seconds) {
    final segment = segmentForSeconds(seconds);
    if (segment == null) {
      return null;
    }

    if (segment.name == 'Auto' || segment.name == 'Transition') {
      return _autoWinnerRed;
    }

    if (segment.shiftIndex != null) {
      final firstShiftRed = !_autoWinnerRed;
      if (segment.shiftIndex!.isEven) {
        return firstShiftRed;
      }
      return !firstShiftRed;
    }

    if (segment.name == 'Endgame') {
      final firstShiftRed = !_autoWinnerRed;
      if (3.isEven) {
        return firstShiftRed;
      }
      return !firstShiftRed;
    }

    return null;
  }

  String formatClock(int seconds) =>
      '${(seconds / 60).floor()}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'custom_schema_version': schemaVersion,
    'auto_winner_red': _autoWinnerRed,
    'auto_winner_configured': _autoWinnerConfigured,
  };

  @override
  List<Widget> getEditProperties(BuildContext context) => [
    DialogToggleSwitch(
      label: 'Auto Winner is Red',
      initialValue: _autoWinnerRed,
      onToggle: (value) {
        autoWinnerRed = value;
      },
    ),
  ];
}

class RebuiltPeriodClockWidget extends NTWidget {
  const RebuiltPeriodClockWidget({super.key});

  Color _ownerColor(bool? ownerIsRed, BuildContext context) {
    if (ownerIsRed == null) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85);
    }

    return ownerIsRed ? Colors.red.shade900 : Colors.blue.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final model = cast<RebuiltPeriodClockModel>(context.watch<NTWidgetModel>());

    return ValueListenableBuilder(
      valueListenable: model.subscription!,
      builder: (context, data, child) {
        final raw = tryCast<num>(data);

        if (raw == null || raw < 0) {
          return Center(
            child: Text(
              'Paused/Unknown',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final segment = model.segmentForSeconds(raw);
        final ownerRed = model.ownerIsRed(raw);
        final color = _ownerColor(ownerRed, context);
        final remaining = model.remainingSecondsInPeriod(raw);

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    segment?.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!model.autoWinnerConfigured) ...[
                    const SizedBox(width: 6),
                    const Tooltip(
                      message: 'Auto winner toggle is using default value',
                      child: Icon(Icons.warning_amber_rounded, size: 16),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                model.formatClock(remaining),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
