import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:wallpanel_ng/globals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallpanel_ng/providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _mqttHostController = TextEditingController();
  final TextEditingController _mqttPortController = TextEditingController();
  final TextEditingController _mqttUserController = TextEditingController();
  final TextEditingController _mqttPasswordController = TextEditingController();
  final TextEditingController _mqttTopicController = TextEditingController();
  final TextEditingController _mqttIntervalController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String? _selFabLocation;

  @override
  void initState() {
    super.initState();
    fetchSettings();
    final notifier = ref.read(settingsNotifierProvider.notifier);
    _mqttHostController
        .addListener(() => notifier.updateMqttHost(_mqttHostController.text));
    _mqttPortController.addListener(() {
      var iPort = int.tryParse(_mqttPortController.text);
      notifier.updateMqttPort(iPort);
    });
    _mqttUserController
        .addListener(() => notifier.updateMqttUser(_mqttUserController.text));
    _mqttPasswordController.addListener(
        () => notifier.updateMqttPassword(_mqttPasswordController.text));
    _mqttTopicController.addListener(
        () => notifier.updateMqttTopic(_mqttTopicController.text));
    _mqttIntervalController.addListener(() {
      var iInterval = int.tryParse(_mqttIntervalController.text);
      notifier.updateMqttSensorInterval(iInterval);
    });
    _urlController.addListener(() {
      notifier.updateUrl(_urlController.text);
    });
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
                          value: ref.watch(settingsNotifierProvider).darkmode ?? false,
                          onChanged: (value) {
                            final notifier = ref.read(settingsNotifierProvider.notifier);
                            notifier.updateDarkmode(value);
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
                      final notifier = ref.read(settingsNotifierProvider.notifier);
                      notifier.updateFabLocation(value);
                      setState(() {
                        _selFabLocation = value;
                      });
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
                          value: ref.watch(settingsNotifierProvider).transparentsettings ?? false,
                          onChanged: (value) {
                            final notifier = ref.read(settingsNotifierProvider.notifier);
                            notifier.updateTransparentSettings(value);
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
                    obscureText: true,
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
                          value: ref.watch(settingsNotifierProvider).mqttsensorpublish ?? false,
                          onChanged: (value) {
                            final notifier = ref.read(settingsNotifierProvider.notifier);
                            notifier.updateMqttSensorPublish(value);
                          }),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MQTT Auto Reconnect"),
                      Checkbox(
                          value: ref.watch(settingsNotifierProvider).mqttautoreconnect ?? true,
                          onChanged: (value) {
                            final notifier = ref.read(settingsNotifierProvider.notifier);
                            notifier.updateMqttAutoReconnect(value);
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
    final prefs = SharedPreferencesAsync();
    final settings = ref.read(settingsNotifierProvider);
    final sSettings = jsonEncode(settings.toJson());
    await prefs.setString("settings", sSettings);
  }

  Future<void> fetchSettings() async {
    final prefs = SharedPreferencesAsync();
    final sSettings = await prefs.getString('settings');
    if (sSettings != null) {
      final jSettings = jsonDecode(sSettings);
      final notifier = ref.read(settingsNotifierProvider.notifier);
      notifier.loadFromJson(jSettings);
      final settingsProv = ref.read(settingsNotifierProvider);
      
      _mqttHostController.text = settingsProv.mqtthost ?? "";
      _mqttPortController.text = settingsProv.mqttport?.toString() ?? "1883";
      _mqttUserController.text = settingsProv.mqttUser ?? "";
      _mqttPasswordController.text = settingsProv.mqttPassword ?? "";
      _mqttTopicController.text = settingsProv.mqttsensortopic ?? "";
      _mqttIntervalController.text = settingsProv.mqttsensorinterval?.toString() ?? "60";
      _urlController.text = settingsProv.url ?? "";
      _selFabLocation = settingsProv.fabLocation;
    }
  }
}
