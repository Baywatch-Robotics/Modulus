import 'dart:async';

import 'package:flutter/material.dart';

class RepeatPressGesture extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool repeatEnabled;
  final Duration initialDelay;
  final Duration repeatInterval;

  const RepeatPressGesture({
    super.key,
    required this.child,
    required this.onPressed,
    this.repeatEnabled = false,
    this.initialDelay = const Duration(milliseconds: 300),
    this.repeatInterval = const Duration(milliseconds: 120),
  });

  @override
  State<RepeatPressGesture> createState() => _RepeatPressGestureState();
}

class _RepeatPressGestureState extends State<RepeatPressGesture> {
  Timer? _startRepeatTimer;
  Timer? _repeatTimer;

  @override
  void didUpdateWidget(covariant RepeatPressGesture oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.repeatEnabled && oldWidget.repeatEnabled) {
      _stopRepeat();
    }
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  void _onPressDown(TapDownDetails _) {
    if (!widget.repeatEnabled) {
      return;
    }

    widget.onPressed();
    _startRepeatTimer?.cancel();
    _repeatTimer?.cancel();

    _startRepeatTimer = Timer(widget.initialDelay, () {
      _repeatTimer = Timer.periodic(widget.repeatInterval, (_) {
        widget.onPressed();
      });
    });
  }

  void _stopRepeat() {
    _startRepeatTimer?.cancel();
    _startRepeatTimer = null;

    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.repeatEnabled ? null : widget.onPressed,
    onTapDown: widget.repeatEnabled ? _onPressDown : null,
    onTapUp: widget.repeatEnabled ? (_) => _stopRepeat() : null,
    onTapCancel: widget.repeatEnabled ? _stopRepeat : null,
    child: widget.child,
  );
}
