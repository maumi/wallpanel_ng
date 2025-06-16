import 'package:flutter/material.dart';

class SettingsModel {
    SettingsModel({
        this.darkmode,
        this.transparentsettings,
        this.mqtthost,
        this.mqttport,
        this.mqttsensortopic,
        this.mqttclientidentifier,
        this.mqttsensorinterval,
        this.mqttsensorpublish,
        this.mqttautoreconnect,
        this.url
    });

    bool? darkmode;
    bool? transparentsettings;
    String? mqtthost;
    int? mqttport;
    String? mqttsensortopic;
    String? mqttclientidentifier;
    int? mqttsensorinterval;
    bool? mqttsensorpublish;
    bool? mqttautoreconnect;
    String? url;
    final ValueNotifier<String> notiUrl = ValueNotifier<String>("");
    final ValueNotifier<bool> notiDarkmode = ValueNotifier<bool>(false);
    final ValueNotifier<bool> notiTransparentSettings = ValueNotifier<bool>(false);
    final ValueNotifier<String> notiMqttHost = ValueNotifier<String>("");
    final ValueNotifier<int> notiMqttPort = ValueNotifier<int>(1883);
    final ValueNotifier<String> notiMqttTopic = ValueNotifier<String>("");
    final ValueNotifier<String> notiMqttClientIdentifier = ValueNotifier<String>("");
    final ValueNotifier<int> notiMqttInterval = ValueNotifier<int>(60);
    final ValueNotifier<bool> notiMqttPublish = ValueNotifier<bool>(false);
    final ValueNotifier<bool?> notiSaved = ValueNotifier<bool?>(null);

    factory SettingsModel.fromJson(Map<String, dynamic> json){ 
        return SettingsModel(
            darkmode: json["darkmode"],
            transparentsettings: json["transparentsettings"],
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
    String toString(){
        return "$darkmode, $transparentsettings, $mqtthost, $mqttport, $mqttsensortopic, $mqttclientidentifier, $mqttsensorinterval, $mqttsensorpublish, $mqttautoreconnect, $url, ";
    }
}
