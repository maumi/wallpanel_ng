import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';
import 'package:wallpanel_ng/globals.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(SettingsModel());

  void updateDarkmode(bool? value) {
    state = state.copyWith(darkmode: value);
  }

  void updateUrl(String value) {
    state = state.copyWith(url: value);
  }

  void updateFabLocation(String? value) {
    state = state.copyWith(fabLocation: value);
  }

  void updateTransparentSettings(bool? value) {
    state = state.copyWith(transparentsettings: value);
  }

  void updateMqttHost(String value) {
    state = state.copyWith(mqtthost: value);
  }

  void updateMqttPort(int? value) {
    state = state.copyWith(mqttport: value);
  }

  void updateMqttTopic(String value) {
    state = state.copyWith(mqttsensortopic: value);
  }

  void updateMqttUser(String value) {
    state = state.copyWith(mqttUser: value);
  }

  void updateMqttPassword(String value) {
    state = state.copyWith(mqttPassword: value);
  }

  void updateMqttSensorInterval(int? value) {
    state = state.copyWith(mqttsensorinterval: value);
  }

  void updateMqttSensorPublish(bool? value) {
    state = state.copyWith(mqttsensorpublish: value);
  }

  void updateMqttAutoReconnect(bool? value) {
    state = state.copyWith(mqttautoreconnect: value);
  }

  void updateScreensaverEnabled(bool? value) {
    state = state.copyWith(screensaverEnabled: value);
  }

  void updateScreensaverInactiveTime(int? value) {
    state = state.copyWith(screensaverInactiveTime: value);
  }

  void updateScreensaverMode(String? value) {
    state = state.copyWith(screensaverMode: value);
  }

  void updateClockType(String? value) {
    talker.debug("updateClockType called with value: $value");
    talker.debug("State BEFORE updateClockType: clockType=${state.clockType}");
    state = state.copyWith(clockType: value);
    talker.debug("State AFTER updateClockType: clockType=${state.clockType}");
  }

  void loadFromJson(Map<String, dynamic> json) {
    final loaded = SettingsModel.fromJson(json);
    state = loaded;
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier();
});