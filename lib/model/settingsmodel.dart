import 'package:flutter/material.dart';

class SettingsModel {
    SettingsModel({
        this.darkmode,
        this.mqtthost,
        this.mqttport,
        this.mqttsensortopic,
        this.mqttsensorinterval,
        this.mqttsensorpublish,
        this.url
    });

    bool? darkmode;
    String? mqtthost;
    int? mqttport;
    String? mqttsensortopic;
    int? mqttsensorinterval;
    bool? mqttsensorpublish;
    String? url;
    final ValueNotifier<String> notiUrl = ValueNotifier<String>("");
    final ValueNotifier<bool> notiDarkmode = ValueNotifier<bool>(false);
    final ValueNotifier<String> notiMqttHost = ValueNotifier<String>("");
    final ValueNotifier<int> notiMqttPort = ValueNotifier<int>(1883);
    final ValueNotifier<String> notiMqttTopic = ValueNotifier<String>("");
    final ValueNotifier<int> notiMqttInterval = ValueNotifier<int>(60);
    final ValueNotifier<bool> notiMqttPublish = ValueNotifier<bool>(false);


    factory SettingsModel.fromJson(Map<String, dynamic> json){ 
        return SettingsModel(
            darkmode: json["darkmode"],
            mqtthost: json["mqtthost"],
            mqttport: json["mqttport"],
            mqttsensortopic: json["mqttsensortopic"],
            mqttsensorinterval: json["mqttsensorinterval"],
            mqttsensorpublish: json["mqttsensorpublish"],
            url: json["url"],
        );
    }

    Map<String, dynamic> toJson() => {
        "darkmode": darkmode,
        "mqtthost": mqtthost,
        "mqttport": mqttport,
        "mqttsensortopic": mqttsensortopic,
        "mqttsensorinterval": mqttsensorinterval,
        "mqttsensorpublish": mqttsensorpublish,
        "url": url,
    };

    @override
    String toString(){
        return "$darkmode, $mqtthost, $mqttport, $mqttsensortopic, $mqttsensorinterval, $mqttsensorpublish, $url, ";
    }
}
