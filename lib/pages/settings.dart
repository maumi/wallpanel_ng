import 'dart:convert';

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
  final TextEditingController _mqttTopicController = TextEditingController();
  final TextEditingController _mqttidentifierController = TextEditingController();
  final TextEditingController _mqttIntervalController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

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
            _mqttidentifierController.addListener(
        () => widget.settings.mqttclientidentifier = _mqttidentifierController.text);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("URL for Wallpanel to load"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.7,
                        child: TextField(
                          textAlign: TextAlign.right,
                          controller: _urlController,
                        ),
                      ),
                    ],
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
                  const Text(
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      "MQTT Settings"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Host"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.7,
                        child: TextField(
                          textAlign: TextAlign.right,
                          controller: _mqttHostController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Port"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.7,
                        child: TextField(
                          textAlign: TextAlign.right,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: _mqttPortController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Sensor Publish Topic"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.7,
                        child: TextField(
                          textAlign: TextAlign.right,
                          controller: _mqttTopicController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Client Identifier"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.7,
                        child: TextField(
                          textAlign: TextAlign.right,
                          controller: _mqttidentifierController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Sensor Publish Interval (s)"),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.7,
                        child: TextField(
                          textAlign: TextAlign.right,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: _mqttIntervalController,
                        ),
                      ),
                    ],
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
    setState(() {
      widget.settings.notiSaved.value = true;
    });
    if (widget.settings.url != null &&
        Uri.tryParse(widget.settings.url!) != null) {
      setState(() {
        widget.settings.notiUrl.value = widget.settings.url!;
      });
    }
    if (widget.settings.notiDarkmode.value != widget.settings.darkmode) {
      setState(() {
        widget.settings.notiDarkmode.value = widget.settings.darkmode ?? false;
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
    if (widget.settings.notiMqttInterval.value !=
        widget.settings.mqttsensorinterval) {
      setState(() {
        widget.settings.notiMqttInterval.value =
            widget.settings.mqttsensorinterval ?? 60;
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
        _mqttTopicController.text = settings.mqttsensortopic ?? "";
        _mqttidentifierController.text = settings.mqttclientidentifier ?? "";
        _mqttIntervalController.text =
            settings.mqttsensorinterval?.toString() ?? "60";
        _urlController.text = settings.url ?? "";
      });
    }
  }
}
