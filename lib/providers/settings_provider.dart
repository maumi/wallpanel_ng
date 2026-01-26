import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';

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

  void loadFromJson(Map<String, dynamic> json) {
    final loaded = SettingsModel.fromJson(json);
    state = loaded;
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier();
});