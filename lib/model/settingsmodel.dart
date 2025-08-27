import 'package:flutter/material.dart';

class SettingsModel {
  SettingsModel(
      {this.darkmode,
      this.transparentsettings,
      this.fabLocation,
      this.mqtthost,
      this.mqttport,
      this.mqttUser,
      this.mqttPassword,
      this.mqttsensortopic,
      this.mqttsensorinterval,
      this.mqttsensorpublish,
      this.mqttautoreconnect,
      this.url});

  bool? darkmode;
  bool? transparentsettings;
  String? fabLocation;
  String? mqtthost;
  int? mqttport;
  String? mqttUser;
  String? mqttPassword;
  String? mqttsensortopic;
  int? mqttsensorinterval;
  bool? mqttsensorpublish;
  bool? mqttautoreconnect;
  String? url;
  final ValueNotifier<String> notiUrl = ValueNotifier<String>("");
  final ValueNotifier<String> notiFabLocation = ValueNotifier<String>("");
  final ValueNotifier<bool> notiDarkmode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> notiTransparentSettings =
      ValueNotifier<bool>(false);
  final ValueNotifier<String> notiMqttHost = ValueNotifier<String>("");
  final ValueNotifier<int> notiMqttPort = ValueNotifier<int>(1883);
  final ValueNotifier<String> notiMqttUser = ValueNotifier<String>("");
  final ValueNotifier<String> notiMqttPassword = ValueNotifier<String>("");
  final ValueNotifier<String> notiMqttTopic = ValueNotifier<String>("");
  final ValueNotifier<int> notiMqttInterval = ValueNotifier<int>(60);
  final ValueNotifier<bool> notiMqttPublish = ValueNotifier<bool>(false);

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      darkmode: json["darkmode"],
      transparentsettings: json["transparentsettings"],
      fabLocation: json["fabLocation"],
      mqtthost: json["mqtthost"],
      mqttport: json["mqttport"],
      mqttUser: json["mqttUser"],
      mqttPassword: json["mqttPassword"],
      mqttsensortopic: json["mqttsensortopic"],
      mqttsensorinterval: json["mqttsensorinterval"],
      mqttsensorpublish: json["mqttsensorpublish"],
      mqttautoreconnect: json["mqttautoreconnect"],
      url: json["url"],
    );
  }

  Map<String, dynamic> toJson() => {
        "darkmode": darkmode,
        "transparentsettings": transparentsettings,
        "fabLocation": fabLocation,
        "mqtthost": mqtthost,
        "mqttport": mqttport,
        "mqttUser": mqttUser,
        "mqttPassword": mqttPassword,
        "mqttsensortopic": mqttsensortopic,
        "mqttsensorinterval": mqttsensorinterval,
        "mqttsensorpublish": mqttsensorpublish,
        "mqttautoreconnect": mqttautoreconnect,
        "url": url,
      };

  @override
  String toString() {
    return "$darkmode, $transparentsettings, $fabLocation, $mqtthost, $mqttport, $mqttUser, $mqttPassword, $mqttsensortopic, $mqttsensorinterval, $mqttsensorpublish, $mqttautoreconnect, $url, ";
  }
}
