import 'package:flutter/material.dart';

class SettingsModel {
  SettingsModel(
      {this.darkmode,
      this.transparentsettings,
      this.fabLocation,
      this.mqtthost,
      this.mqttport,
      this.mqttsensortopic,
      this.mqttclientidentifier,
      this.mqttsensorinterval,
      this.mqttsensorpublish,
      this.mqttautoreconnect,
      this.url});

  bool? darkmode;
  bool? transparentsettings;
  String? fabLocation;
  String? mqtthost;
  int? mqttport;
  String? mqttsensortopic;
  String? mqttclientidentifier;
  int? mqttsensorinterval;
  bool? mqttsensorpublish;
  bool? mqttautoreconnect;
  String? url;
  final ValueNotifier<String> notiUrl = ValueNotifier<String>("");
  final ValueNotifier<String> notiFabLocation = ValueNotifier<String>("");
  final ValueNotifier<bool> notiDarkmode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> notiTransparentSettings =
      ValueNotifier<bool>(false);
  // TODO: Add Listener for mqtt host to have an instant change
  final ValueNotifier<String> notiMqttHost = ValueNotifier<String>("");
  // TODO: Add Listener for mqtt Port to have an instant change
  final ValueNotifier<int> notiMqttPort = ValueNotifier<int>(1883);
  // TODO: Add Listener for mqtt Topic to have an instant change
  final ValueNotifier<String> notiMqttTopic = ValueNotifier<String>("");
  // TODO: Add Listener for mqtt Client Id to have an instant change
  final ValueNotifier<String> notiMqttClientIdentifier =
      ValueNotifier<String>("");
  final ValueNotifier<int> notiMqttInterval = ValueNotifier<int>(60);
  final ValueNotifier<bool> notiMqttPublish = ValueNotifier<bool>(false);

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      darkmode: json["darkmode"],
      transparentsettings: json["transparentsettings"],
      fabLocation: json["fabLocation"],
      mqtthost: json["mqtthost"],
      mqttport: json["mqttport"],
      mqttsensortopic: json["mqttsensortopic"],
      mqttclientidentifier: json["mqttclientidentifier"],
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
        "mqttsensortopic": mqttsensortopic,
        "mqttclientidentifier": mqttclientidentifier,
        "mqttsensorinterval": mqttsensorinterval,
        "mqttsensorpublish": mqttsensorpublish,
        "mqttautoreconnect": mqttautoreconnect,
        "url": url,
      };

  @override
  String toString() {
    return "$darkmode, $transparentsettings, $fabLocation, $mqtthost, $mqttport, $mqttsensortopic, $mqttclientidentifier, $mqttsensorinterval, $mqttsensorpublish, $mqttautoreconnect, $url, ";
  }
}
