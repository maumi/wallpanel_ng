class SettingsModel {
  SettingsModel({
    this.darkmode,
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
    this.url,
    this.screensaverEnabled,
    this.screensaverInactiveTime,
    this.screensaverMode,
    this.clockType,
  });

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
  bool? screensaverEnabled;
  int? screensaverInactiveTime;
  String? screensaverMode; // 'clock' or 'black'
  String? clockType; // 'analog' or 'digital'

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
      screensaverEnabled: json["screensaverEnabled"],
      screensaverInactiveTime: json["screensaverInactiveTime"],
      screensaverMode: json["screensaverMode"],
      clockType: json["clockType"],
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
        "screensaverEnabled": screensaverEnabled,
        "screensaverInactiveTime": screensaverInactiveTime,
        "screensaverMode": screensaverMode,
        "clockType": clockType,
      };

  SettingsModel copyWith({
    bool? darkmode,
    bool? transparentsettings,
    String? fabLocation,
    String? mqtthost,
    int? mqttport,
    String? mqttUser,
    String? mqttPassword,
    String? mqttsensortopic,
    int? mqttsensorinterval,
    bool? mqttsensorpublish,
    bool? mqttautoreconnect,
    String? url,
    bool? screensaverEnabled,
    int? screensaverInactiveTime,
    String? screensaverMode,
    String? clockType,
  }) {
    return SettingsModel(
      darkmode: darkmode ?? this.darkmode,
      transparentsettings: transparentsettings ?? this.transparentsettings,
      fabLocation: fabLocation ?? this.fabLocation,
      mqtthost: mqtthost ?? this.mqtthost,
      mqttport: mqttport ?? this.mqttport,
      mqttUser: mqttUser ?? this.mqttUser,
      mqttPassword: mqttPassword ?? this.mqttPassword,
      mqttsensortopic: mqttsensortopic ?? this.mqttsensortopic,
      mqttsensorinterval: mqttsensorinterval ?? this.mqttsensorinterval,
      mqttsensorpublish: mqttsensorpublish ?? this.mqttsensorpublish,
      mqttautoreconnect: mqttautoreconnect ?? this.mqttautoreconnect,
      url: url ?? this.url,
      screensaverEnabled: screensaverEnabled ?? this.screensaverEnabled,
      screensaverInactiveTime: screensaverInactiveTime ?? this.screensaverInactiveTime,
      screensaverMode: screensaverMode ?? this.screensaverMode,
      clockType: clockType ?? this.clockType,
    );
  }

  @override
  String toString() {
    return "SettingsModel(darkmode: $darkmode, transparentsettings: $transparentsettings, fabLocation: $fabLocation, url: $url)";
  }
}