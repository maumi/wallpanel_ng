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
