import 'dart:async';
import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/volume_settings.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpanel_ng/globals.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';
import 'package:wallpanel_ng/pages/settings.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screen_state/screen_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SettingsModel settings = SettingsModel();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: settings.notiDarkmode,
        builder: (BuildContext context, bool value, Widget? child) {
          return MaterialApp(
            title: 'Wallpanel-ng',
            darkTheme: ThemeData.dark(),
            themeMode: value ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: MyHomePage(title: 'Wallpanel-ng', settings: settings),
            // ),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.settings});

  final String title;
  final SettingsModel settings;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MqttServerClient? _mqttClient;
  MqttClientPayloadBuilder? _mqttClientPayloadBuilder;
  Timer? _publishTimer;
  String? _subscribedTopic;
  WebViewController _webViewController = WebViewController();
  final Screen _screen = Screen();
  ScreenStateEvent? _screenStateEvent;

  @override
  void initState() {
    talker.verbose("Init App");
    AndroidAlarmManager.initialize();
    widget.settings.notiUrl.addListener(() {
      if (widget.settings.notiUrl.value.isNotEmpty) {
        setState(() {
          _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
          _webViewController
              .loadRequest(Uri.parse(widget.settings.notiUrl.value));
        });
      }
      talker.debug(
          "Notifier: Url has changed to: ${widget.settings.notiUrl.value}");
    });
    widget.settings.notiMqttHost.addListener(
      () {
        if (widget.settings.notiMqttHost.value.isNotEmpty) {
          setState(() {
            changeMqttConnection();
          });
        }
      },
    );
    widget.settings.notiMqttPort.addListener(
      () {
        setState(() {
          changeMqttConnection();
        });
      },
    );
    widget.settings.notiMqttTopic.addListener(
      () {
        setState(() {
          unSubscribeOldTopic();
          subscribeTopic(widget.settings.notiMqttTopic.value);
        });
      },
    );
    widget.settings.notiMqttInterval.addListener(
      () {
        changePublishInterval();
      },
    );
    widget.settings.notiMqttPublish.addListener(() {
      if (widget.settings.notiMqttPublish.value) {
        setState(() {
          _publishTimer?.cancel();
          _publishTimer = null;
          _publishTimer = Timer.periodic(
            Duration(seconds: widget.settings.mqttsensorinterval ?? 60),
            (timer) async {
              await publishBatteryState();
            },
          );
        });
      } else {
        _publishTimer?.cancel();
      }
    });
    _screen.screenStateStream.listen(onData);
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    await fetchSettings();
    if (widget.settings.url != null) {
      setWebViewController(widget.settings.url!);
    }
    await setupMqtt();
    WidgetsFlutterBinding.ensureInitialized();
    await Alarm.init();
    if (widget.settings.mqttsensorpublish == true) {
      _publishTimer?.cancel();
      _publishTimer = null;
      _publishTimer = Timer.periodic(
        Duration(seconds: widget.settings.mqttsensorinterval ?? 60),
        (timer) async {
          await publishBatteryState();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: widget.settings.notiUrl,
        builder: (BuildContext context, value, Widget? child) {
          return WebViewWidget(controller: _webViewController);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SettingsPage(settings: widget.settings)),
          );
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  void onData(ScreenStateEvent event) {
    setState(() {
      _screenStateEvent = event;
    });
  }

  void changePublishInterval() {
    _publishTimer?.cancel();
    _publishTimer = null;
    _publishTimer = Timer.periodic(
      Duration(seconds: widget.settings.mqttsensorinterval ?? 60),
      (timer) async {
        await publishBatteryState();
      },
    );
  }

  Future<int> getBatteryLevel() async {
    var battery = Battery();
    var batteryLevel = await battery.batteryLevel;

    return batteryLevel;
  }

  Future<void> publishBatteryState() async {
    var batteryLevel = await getBatteryLevel();
    var bPub = await publishMessage(batteryLevel.toString());
    talker.verbose("Publish successful: $bPub");
  }

  void setWebViewController(String requestUrl) {
    talker.verbose("Try to change WebView Controller");
    var controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(requestUrl));

    setState(() {
      _webViewController = controller;
    });
  }

  void setMqttClientBuilder() {
    var builder = MqttClientPayloadBuilder();

    setState(() {
      _mqttClientPayloadBuilder = builder;
    });
  }

  void subscribeMqtt() {
    try {
      if (_mqttClient != null && _mqttClient!.updates != null) {
        talker.debug("Should be able to listen to mqtt topics");
      } else {
        talker.debug(
            "Should not be able to listen to mqtt topics. Client: $_mqttClient, updates: ${_mqttClient?.updates}");
      }
      _mqttClient?.updates
          ?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        talker.debug("Received mqtt Message: ${c?[0].payload}");

        final recMess = c![0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        if (c[0].topic.endsWith("/command")) {
          talker.verbose("Found topic with command at the end");
          var jPayload = jsonDecode(pt);
          talker.verbose("After json decode $jPayload");
          try {
            var bWake = jPayload["wake"];
            talker.verbose("bWake is: $bWake");
            if (bWake) {
              wakeupIntent();
            } else {
              // disableWakeLock();
            }
          } catch (e) {
            talker.warning("Wrong command");
          }
        }
        talker.verbose(
            'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      });
    } catch (e) {
      talker.error("subscribeMqtt: $e");
    }
  }

  Future<void> fetchSettings() async {
    var prefs = SharedPreferencesAsync();
    var sSettings = await prefs.getString('settings');
    if (sSettings != null) {
      var jSettings = jsonDecode(sSettings);
      var settings = SettingsModel.fromJson(jSettings);
      setState(() {
        widget.settings.darkmode = settings.darkmode;
        widget.settings.url = settings.url;
        widget.settings.mqtthost = settings.mqtthost;
        widget.settings.mqttport = settings.mqttport;
        widget.settings.mqttsensorinterval = settings.mqttsensorinterval;
        widget.settings.mqttsensorpublish = settings.mqttsensorpublish;
        widget.settings.mqttsensortopic = settings.mqttsensortopic;
        widget.settings.notiDarkmode.value = settings.darkmode ?? false;
        widget.settings.notiMqttHost.value = settings.mqtthost ?? "";
        widget.settings.notiMqttInterval.value = settings.mqttsensorinterval ?? 60;
        widget.settings.notiMqttPort.value = settings.mqttport ?? 1883;
        widget.settings.notiMqttPublish.value = settings.mqttsensorpublish ?? false;
        widget.settings.notiMqttTopic.value = settings.mqttsensortopic ?? "";
        widget.settings.notiUrl.value = settings.url ?? "http://google.com";
      });
    }
  }

  Future<void> setupMqtt() async {
    await connectMqtt();
    setMqttClientBuilder();
    subscribeMqtt();
    if (widget.settings.mqttsensortopic != null) {
      subscribeTopic(widget.settings.mqttsensortopic!);
    }
    await changeMqttConnection();
  }

  Future<void> connectMqtt() async {
    if (widget.settings.mqtthost != null) {
      var mqttClient = MqttServerClient.withPort(widget.settings.mqtthost!,
          'myClient', widget.settings.mqttport ?? 1883);
      mqttClient.keepAlivePeriod = 86400;
      var mqttStatus = await mqttClient.connect('myClientId');
      talker.debug("Connected to MQTT Server with state: $mqttStatus");
      setState(() {
        _mqttClient = mqttClient;
      });
    }
  }

  Future<void> changeMqttConnection() async {
    try {
      if (_mqttClient?.connectionStatus?.state ==
          MqttConnectionState.connected) {
        _mqttClient?.disconnect();
      }
      if (widget.settings.mqtthost != null &&
          widget.settings.mqttport != null) {
        var mqttClient = MqttServerClient.withPort(
            widget.settings.notiMqttHost.value,
            'myClient',
            widget.settings.notiMqttPort.value);
        mqttClient.keepAlivePeriod = 86400;
        await mqttClient.connect('myClientId');
        setState(() {
          _mqttClient = mqttClient;
        });
      }
    } catch (e) {
      talker.warning("changeMqttConnection: $e");
    }
  }

  void subscribeTopic(String topic) {
    try {
      if (_mqttClient?.connectionStatus?.state ==
          MqttConnectionState.connected) {
        _mqttClient?.subscribe("$topic/command", MqttQos.atMostOnce);
        talker.debug("Subscribed to topic $topic/command");
        setState(() {
          _subscribedTopic = topic;
        });
      }
    } catch (e) {
      talker.error("subscribeTopic: $e");
    }
  }

  void unSubscribeOldTopic() {
    if (_subscribedTopic != null &&
        _mqttClient != null &&
        _mqttClient?.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        _mqttClient!.unsubscribe(_subscribedTopic!);
      } catch (e) {
        talker.error("unSubscribeOldTopic: $e");
      }
    }
  }

  Future<bool> publishMessage(String payload) async {
    var bRet = false;
    if (widget.settings.mqttsensortopic != null) {
      try {
        _mqttClientPayloadBuilder?.clear();
        _mqttClientPayloadBuilder?.addString(payload);
        if (_mqttClientPayloadBuilder?.payload != null) {
          if (_mqttClient?.connectionStatus?.state !=
              MqttConnectionState.connected) {
            talker.debug("Reconnect Mqtt");
            await changeMqttConnection();
          }
          var iMqttId = _mqttClient?.publishMessage(
              widget.settings.mqttsensortopic!,
              MqttQos.exactlyOnce,
              _mqttClientPayloadBuilder!.payload!);
          talker.verbose("published message $iMqttId");
          bRet = true;
        }
      } catch (e) {
        talker.error("publishMessage: $e");
      }
    }
    return bRet;
  }

  Future<void> wakeupIntent() async {
    talker.verbose("Before alarm");
    try {
      final alarmSettings = AlarmSettings(
        id: 42,
        dateTime: DateTime.now(),
        assetAudioPath: 'assets/marimba.mp3',
        // loopAudio: true,
        // vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fixed(
          volume: 0.0,
          volumeEnforced: true,
        ),
        notificationSettings: const NotificationSettings(
          title: 'This is the title',
          body: 'This is the body',
          stopButton: 'Stop the alarm',
          icon: 'notification_icon',
        ),
      );
      if (_screenStateEvent == ScreenStateEvent.SCREEN_OFF) {
        talker.debug("Wakeup Screen");
        await Alarm.set(alarmSettings: alarmSettings);
      } else {
        talker.debug("Not waking up because screen is on already");
      }
      talker.verbose("After Alarm fired");
    } catch (e) {
      talker.warning("wakeupIntent $e");
    }
  }
}
