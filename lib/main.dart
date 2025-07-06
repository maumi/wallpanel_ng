import 'dart:async';
import 'dart:convert';
import 'package:android_wake_lock/android_wake_lock.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wallpanel_ng/globals.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';
import 'package:wallpanel_ng/pages/settings.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  StreamSubscription? _streamSubscription;
  final double _webViewProgress = 1;
  InAppWebViewController? webViewController;
  String? _fabLocation;
  bool? _transparentSettings;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    widget.settings.notiUrl.addListener(() {
      if (widget.settings.notiUrl.value.isNotEmpty &&
          webViewController != null) {
        webViewController?.loadUrl(
            urlRequest: URLRequest(url: WebUri(widget.settings.notiUrl.value)));
      }
    });
    widget.settings.notiFabLocation.addListener(() {
      if (widget.settings.notiFabLocation.value.isNotEmpty) {
        setState(() {
          _fabLocation = widget.settings.notiFabLocation.value;
        });
      }
    });
    widget.settings.notiTransparentSettings.addListener(() {
      setState(() {
        _transparentSettings = widget.settings.notiTransparentSettings.value;
      });
    });
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
    super.initState();
  }

  Future<void> initAsync() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (widget.settings.url != null && webViewController != null) {
      await webViewController!
          .loadUrl(urlRequest: URLRequest(url: WebUri(widget.settings.url!)));
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    await setupMqtt();

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
        body: webView(),
        floatingActionButton: fab(),
        floatingActionButtonLocation: mapFabLocations.containsKey(_fabLocation)
            ? mapFabLocations[_fabLocation]
            : FloatingActionButtonLocation.endDocked);
  }

  Widget webView() {
    return _webViewProgress != 1
        ? biggerCircularProgressIndicator()
        : InAppWebView(
            initialUrlRequest: URLRequest(
                url: WebUri(widget.settings.url ?? "http://google.com")),
            initialSettings: InAppWebViewSettings(
              forceDark: ForceDark.ON,
              mediaPlaybackRequiresUserGesture: false,
              allowBackgroundAudioPlaying: true,
              allowsBackForwardNavigationGestures: false,
            ),
            onWebViewCreated: (controller) async {
              webViewController = controller;
              await fetchSettings();
              await initAsync();
            },
            onConsoleMessage: (controller, consoleMessage) async {
              talker.debug(consoleMessage.message);
            },
          );
  }

  Widget biggerCircularProgressIndicator() {
    return Center(
      child: SizedBox(
        height: 60,
        width: 60,
        child: CircularProgressIndicator(value: _webViewProgress),
      ),
    );
  }

  Widget fab() {
    return FloatingActionButton(
      backgroundColor: _transparentSettings == true
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.2)
          : Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: _transparentSettings == true
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.white,
      heroTag: 'fabSettings',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SettingsPage(settings: widget.settings)),
        );
      },
      child: const Icon(Icons.settings),
    );
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
    await publishMessage("battery", batteryLevel.toString());
  }

  void setMqttClientBuilder() {
    if (_mqttClientPayloadBuilder == null) {
      var builder = MqttClientPayloadBuilder();
      _mqttClientPayloadBuilder = builder;
    }
  }

  Future<void> subscribeMqtt() async {
    try {
      if (_mqttClient == null) {
        talker.debug(
            "Should not be able to listen to mqtt topics. Client: $_mqttClient, updates: ${_mqttClient?.updates}");
      }
      await _streamSubscription?.cancel();
      _streamSubscription = _mqttClient?.updates
          ?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) async {
        await publishMessage("pong",
            "${DateTime.now().minute.toString()}${DateTime.now().second.toString()}");

        if (c == null) {
          return;
        }

        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        if (c[0].topic.endsWith("/command")) {
          try {
            var jPayload = jsonDecode(pt);
            var bWake = jPayload["wake"];
            if (bWake) {
              int wakeTime = 60;
              try {
                wakeTime = jPayload["wakeTime"];
              } catch (e) {
                talker.debug(
                    "waketime not specified. Using default of 60 seconds");
              }
              wakeupIntent(wakeTime);
            } else {
              disableWakeLock();
            }
          } catch (e) {
            talker.warning("Wrong command");
          }
        }
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
      if (settings.url != null) {
        webViewController?.loadUrl(
            urlRequest: URLRequest(url: WebUri(settings.url!)));
      }
      widget.settings.url = settings.url;
      widget.settings.darkmode = settings.darkmode;
      widget.settings.fabLocation = settings.fabLocation;
      widget.settings.transparentsettings = settings.transparentsettings;
      widget.settings.mqtthost = settings.mqtthost;
      widget.settings.mqttport = settings.mqttport;
      widget.settings.mqttUser = settings.mqttUser;
      widget.settings.mqttPassword = settings.mqttPassword;
      widget.settings.mqttsensorinterval = settings.mqttsensorinterval;
      widget.settings.mqttsensorpublish = settings.mqttsensorpublish;
      widget.settings.mqttsensortopic = settings.mqttsensortopic;
      widget.settings.notiDarkmode.value = settings.darkmode ?? false;
      widget.settings.notiMqttHost.value = settings.mqtthost ?? "";
      widget.settings.notiMqttInterval.value =
          settings.mqttsensorinterval ?? 60;
      widget.settings.notiMqttPort.value = settings.mqttport ?? 1883;
      widget.settings.notiMqttPublish.value =
          settings.mqttsensorpublish ?? false;
      widget.settings.notiMqttTopic.value = settings.mqttsensortopic ?? "";
      widget.settings.notiUrl.value = settings.url ?? "http://google.com";
      widget.settings.mqttautoreconnect = settings.mqttautoreconnect;
      widget.settings.mqttclientidentifier = settings.mqttclientidentifier;
      setState(() {
        _fabLocation = settings.fabLocation;
        _transparentSettings = settings.transparentsettings;
      });
    }
  }

  Future<void> setupMqtt() async {
    await connectMqtt();
    setMqttClientBuilder();
    await subscribeMqtt();
    if (widget.settings.mqttsensortopic != null) {
      subscribeTopic(widget.settings.mqttsensortopic!);
    }
  }

  Future<void> connectMqtt() async {
    if (widget.settings.mqtthost != null) {
      var mqttClient = MqttServerClient.withPort(
          widget.settings.mqtthost!,
          widget.settings.mqttclientidentifier ?? 'myClientId',
          widget.settings.mqttport ?? 1883);
      mqttClient.keepAlivePeriod = 86400;
      mqttClient.autoReconnect = true;
      var mqttStatus = await mqttClient.connect(widget.settings.mqttUser, widget.settings.mqttPassword);
      talker.debug(
          "Connected to MQTT Server with state: $mqttStatus and identifier: ${widget.settings.mqttclientidentifier ?? "myClient"}");
      _mqttClient?.disconnect();
      _mqttClient = mqttClient;
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
            widget.settings.notiMqttClientIdentifier.value,
            widget.settings.notiMqttPort.value);
        mqttClient.keepAlivePeriod = 86400;
        var mqttStatus = await mqttClient.connect(widget.settings.mqttUser, widget.settings.mqttPassword);
        talker.debug(
            "Connected to MQTT Server with state: $mqttStatus and identifier: ${widget.settings.mqttclientidentifier ?? "myClient"}");
        _mqttClient = mqttClient;
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
        _subscribedTopic = topic;
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

  Future<bool> publishMessage(String subtopic, String payload) async {
    var bRet = false;
    if (widget.settings.mqttsensortopic != null) {
      try {
        _mqttClientPayloadBuilder?.clear();
        _mqttClientPayloadBuilder?.addString(payload);
        if (_mqttClientPayloadBuilder?.payload != null &&
            widget.settings.mqttsensortopic != null) {
          _mqttClient?.publishMessage(
              "${widget.settings.mqttsensortopic!}/$subtopic",
              MqttQos.exactlyOnce,
              _mqttClientPayloadBuilder!.payload!);
          bRet = true;
        }
      } catch (e) {
        talker.error("publishMessage: $e");
      }
    }
    return bRet;
  }

  Future<void> wakeupIntent(int wakeTime) async {
    AndroidWakeLock.wakeUp();
    WakelockPlus.enable();
    Future.delayed(Duration(seconds: wakeTime), () {
      WakelockPlus.disable();
    });
  }

  Future<void> disableWakeLock() async {
    WakelockPlus.disable();
  }
}
