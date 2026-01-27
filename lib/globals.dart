import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talker = Talker(
    logger:
        TalkerLogger(settings: TalkerLoggerSettings(level: LogLevel.debug)));

final mapFabLocations = {
  'topLeft': FloatingActionButtonLocation.startTop,
  'topRight': FloatingActionButtonLocation.endTop,
  'bottomLeft': FloatingActionButtonLocation.startDocked,
  'bottomRight': FloatingActionButtonLocation.endDocked
};

// Global screensaver timer control
void Function()? _startScreensaverTimerCallback;
void Function()? _stopScreensaverTimerCallback;

void setScreensaverTimerCallbacks({
  required void Function() startCallback,
  required void Function() stopCallback,
}) {
  _startScreensaverTimerCallback = startCallback;
  _stopScreensaverTimerCallback = stopCallback;
}

void pauseScreensaverTimer() {
  _stopScreensaverTimerCallback?.call();
  talker.debug("Screensaver timer paused");
}

void resumeScreensaverTimer() {
  _startScreensaverTimerCallback?.call();
  talker.debug("Screensaver timer resumed");
}
