import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(SettingsModel());

  void updateDarkmode(bool? value) {
    state.darkmode = value;
    // keep legacy ValueNotifier in sync
    state.notiDarkmode.value = value ?? false;
    state = state;
  }

  void updateUrl(String value) {
    state.url = value;
    state.notiUrl.value = value;
    state = state;
  }

  void updateFabLocation(String? value) {
    state.fabLocation = value;
    state.notiFabLocation.value = value ?? "";
    state = state;
  }

  void updateTransparentSettings(bool? value) {
    state.transparentsettings = value;
    state.notiTransparentSettings.value = value ?? false;
    state = state;
  }

  void updateMqttHost(String value) {
    state.mqtthost = value;
    state.notiMqttHost.value = value;
    state = state;
  }

  void updateMqttPort(int? value) {
    state.mqttport = value;
    state.notiMqttPort.value = value ?? 1883;
    state = state;
  }

  void updateMqttTopic(String value) {
    state.mqttsensortopic = value;
    state.notiMqttTopic.value = value;
    state = state;
  }

  void updateMqttUser(String value) {
    state.mqttUser = value;
    state.notiMqttUser.value = value;
    state = state;
  }

  void updateMqttPassword(String value) {
    state.mqttPassword = value;
    state.notiMqttPassword.value = value;
    state = state;
  }

  void updateMqttSensorInterval(int? value) {
    state.mqttsensorinterval = value;
    state.notiMqttInterval.value = value ?? 60;
    state = state;
  }

  void updateMqttSensorPublish(bool? value) {
    state.mqttsensorpublish = value;
    state.notiMqttPublish.value = value ?? false;
    state = state;
  }

  void updateMqttAutoReconnect(bool? value) {
    state.mqttautoreconnect = value;
    state = state;
  }

  void loadFromJson(Map<String, dynamic> json) {
    final loaded = SettingsModel.fromJson(json);
    // copy fields
    state.darkmode = loaded.darkmode;
    state.transparentsettings = loaded.transparentsettings;
    state.fabLocation = loaded.fabLocation;
    state.mqtthost = loaded.mqtthost;
    state.mqttport = loaded.mqttport;
    state.mqttUser = loaded.mqttUser;
    state.mqttPassword = loaded.mqttPassword;
    state.mqttsensortopic = loaded.mqttsensortopic;
    state.mqttsensorinterval = loaded.mqttsensorinterval;
    state.mqttsensorpublish = loaded.mqttsensorpublish;
    state.mqttautoreconnect = loaded.mqttautoreconnect;
    state.url = loaded.url;

    // sync notifiers
    state.notiUrl.value = state.url ?? "";
    state.notiFabLocation.value = state.fabLocation ?? "";
    state.notiDarkmode.value = state.darkmode ?? false;
    state.notiTransparentSettings.value = state.transparentsettings ?? false;
    state.notiMqttHost.value = state.mqtthost ?? "";
    state.notiMqttPort.value = state.mqttport ?? 1883;
    state.notiMqttUser.value = state.mqttUser ?? "";
    state.notiMqttPassword.value = state.mqttPassword ?? "";
    state.notiMqttTopic.value = state.mqttsensortopic ?? "";
    state.notiMqttInterval.value = state.mqttsensorinterval ?? 60;
    state.notiMqttPublish.value = state.mqttsensorpublish ?? false;

    state = state;
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier();
});
