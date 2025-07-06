import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:wallpanel_ng/globals.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});
  final SettingsModel settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _mqttHostController = TextEditingController();
  final TextEditingController _mqttPortController = TextEditingController();
  final TextEditingController _mqttUserController = TextEditingController();
  final TextEditingController _mqttPasswordController = TextEditingController();
  final TextEditingController _mqttTopicController = TextEditingController();
  final TextEditingController _mqttidentifierController =
      TextEditingController();
  final TextEditingController _mqttIntervalController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String? _selFabLocation;

  @override
  void initState() {
    fetchSettings();
    _mqttHostController
        .addListener(() => widget.settings.mqtthost = _mqttHostController.text);
    _mqttPortController.addListener(() {
      var iPort = int.tryParse(_mqttPortController.text);
      widget.settings.mqttport = iPort;
    });
    _mqttTopicController.addListener(
        () => widget.settings.mqttsensortopic = _mqttTopicController.text);
    _mqttidentifierController.addListener(() =>
        widget.settings.mqttclientidentifier = _mqttidentifierController.text);
    _mqttIntervalController.addListener(() {
      var iInterval = int.tryParse(_mqttIntervalController.text);
      widget.settings.mqttsensorinterval = iInterval;
    });
    _urlController.addListener(() {
      setState(() {
        widget.settings.url = _urlController.text;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Text(
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      "General Settings"),
                  TextField(
                    textAlign: TextAlign.right,
                    controller: _urlController,
                    decoration: InputDecoration(label: Text("URL")),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("DarkMode"),
                      Checkbox(
                          value: widget.settings.darkmode ?? false,
                          onChanged: (value) {
                            setState(() {
                              widget.settings.darkmode = value;
                              widget.settings.notiDarkmode.value =
                                  widget.settings.darkmode ?? false;
                            });
                          }),
                    ],
                  ),
                  DropdownSearch<String>(
                    items: (filter, loadProps) {
                      return [
                        "topLeft",
                        "topRight",
                        "bottomLeft",
                        "bottomRight"
                      ];
                    },
                    onChanged: (value) {
                      widget.settings.fabLocation = value;
                    },
                    compareFn: (item1, item2) =>
                        item1.toString() == item2.toString(),
                    selectedItem: _selFabLocation,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Transparent Settings Button"),
                      Checkbox(
                          value: widget.settings.transparentsettings ?? false,
                          onChanged: (value) {
                            setState(() {
                              widget.settings.transparentsettings = value;
                              widget.settings.notiTransparentSettings.value =
                                  widget.settings.transparentsettings ?? false;
                            });
                          }),
                    ],
                  ),
                  const Text(
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      "MQTT Settings"),
                  TextField(
                    textAlign: TextAlign.right,
                    controller: _mqttHostController,
                    decoration: InputDecoration(label: const Text("MQTT Host")),
                  ),
                  TextField(
                    textAlign: TextAlign.right,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: _mqttPortController,
                    decoration: InputDecoration(label: const Text("MQTT Port")),
                  ),
                  TextField(
                    textAlign: TextAlign.right,
                    controller: _mqttUserController,
                    decoration: InputDecoration(label: const Text("MQTT Username")),
                  ),
                  TextField(
                    textAlign: TextAlign.right,
                    controller: _mqttPasswordController,
                    decoration: InputDecoration(label: const Text("MQTT Password")),
                  ),
                  TextField(
                    textAlign: TextAlign.right,
                    controller: _mqttTopicController,
                    decoration: InputDecoration(
                        label: const Text("MQTT Sensor Publish Topic")),
                  ),
                  TextField(
                    textAlign: TextAlign.right,
                    controller: _mqttidentifierController,
                    decoration: InputDecoration(
                        label: const Text("MQTT Client Identifier")),
                  ),
                  TextField(
                    textAlign: TextAlign.right,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: _mqttIntervalController,
                    decoration: InputDecoration(
                        label: const Text("MQTT Sensor Publish Interval (s)")),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Enable Sensor Publish"),
                      Checkbox(
                          value: widget.settings.mqttsensorpublish ?? false,
                          onChanged: (value) {
                            setState(() {
                              widget.settings.mqttsensorpublish = value;
                            });
                          }),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Auto Reconnect"),
                      Checkbox(
                          value: widget.settings.mqttautoreconnect ?? true,
                          onChanged: (value) {
                            setState(() {
                              widget.settings.mqttautoreconnect = value;
                            });
                          }),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await saveSettings();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Save")),
                const Gap(10),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TalkerScreen(talker: talker)),
                      );
                    },
                    child: const Text("Talker")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveSettings() async {
    var prefs = SharedPreferencesAsync();
    var sSettings = jsonEncode(widget.settings.toJson());
    await prefs.setString("settings", sSettings);

    if (widget.settings.url != null &&
        Uri.tryParse(widget.settings.url!) != null) {
      setState(() {
        widget.settings.notiUrl.value = widget.settings.url!;
      });
    }
    if (widget.settings.fabLocation != null) {
      setState(() {
        widget.settings.notiFabLocation.value = widget.settings.fabLocation!;
      });
    }
    if (widget.settings.notiDarkmode.value != widget.settings.darkmode) {
      setState(() {
        widget.settings.notiDarkmode.value = widget.settings.darkmode ?? false;
      });
    }
    if (widget.settings.notiTransparentSettings.value !=
        widget.settings.transparentsettings) {
      setState(() {
        widget.settings.notiTransparentSettings.value =
            widget.settings.transparentsettings ?? false;
      });
    }
    if (widget.settings.notiMqttHost.value != widget.settings.mqtthost) {
      setState(() {
        widget.settings.notiMqttHost.value =
            widget.settings.mqtthost ?? "localhost";
      });
    }
    if (widget.settings.notiMqttPort.value != widget.settings.mqttport) {
      setState(() {
        widget.settings.notiMqttPort.value = widget.settings.mqttport ?? 1883;
      });
    }
    if (widget.settings.notiMqttPort.value != widget.settings.mqttport) {
      setState(() {
        widget.settings.notiMqttPort.value = widget.settings.mqttport ?? 1883;
      });
    }
    if (widget.settings.notiMqttUser.value !=
        widget.settings.mqttUser) {
      setState(() {
        widget.settings.notiMqttUser.value =
            widget.settings.mqttUser ?? "";
      });
    }
    if (widget.settings.notiMqttPassword.value !=
        widget.settings.mqttPassword) {
      setState(() {
        widget.settings.notiMqttPassword.value =
            widget.settings.mqttPassword ?? "";
      });
    }
    if (widget.settings.notiMqttTopic.value !=
        widget.settings.mqttsensortopic) {
      setState(() {
        widget.settings.notiMqttTopic.value =
            widget.settings.mqttsensortopic ?? "";
      });
    }
    if (widget.settings.notiMqttClientIdentifier.value !=
        widget.settings.mqttclientidentifier) {
      setState(() {
        widget.settings.notiMqttClientIdentifier.value =
            widget.settings.mqttclientidentifier ?? "";
      });
    }
    if (widget.settings.notiMqttPublish.value !=
        widget.settings.mqttsensorpublish) {
      setState(() {
        widget.settings.notiMqttPublish.value =
            widget.settings.mqttsensorpublish ?? false;
      });
    }
  }

  Future<void> fetchSettings() async {
    var prefs = SharedPreferencesAsync();
    var sSettings = await prefs.getString('settings');
    if (sSettings != null) {
      var jSettings = jsonDecode(sSettings);
      var settings = SettingsModel.fromJson(jSettings);
      setState(() {
        _mqttHostController.text = settings.mqtthost ?? "";
        _mqttPortController.text = settings.mqttport?.toString() ?? "1883";
        _mqttUserController.text = settings.mqttUser?.toString() ?? "";
        _mqttPasswordController.text = settings.mqttPassword?.toString() ?? "";
        _mqttTopicController.text = settings.mqttsensortopic ?? "";
        _mqttidentifierController.text = settings.mqttclientidentifier ?? "";
        _mqttIntervalController.text =
            settings.mqttsensorinterval?.toString() ?? "60";
        _urlController.text = settings.url ?? "";
        _selFabLocation = settings.fabLocation;
      });
    }
  }
}
