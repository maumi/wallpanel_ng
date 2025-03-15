import 'dart:async';
import 'dart:convert';
import 'package:android_wake_lock/android_wake_lock.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wallpanel_ng/globals.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';
import 'package:wallpanel_ng/pages/settings.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  MqttPayloadBuilder? _mqttClientPayloadBuilder;
  Timer? _publishTimer;
  String? _subscribedTopic;
  WebViewController _webViewController = WebViewController();
  StreamSubscription? _streamSubscription;
  double dragStartY = 0;

  @override
  void initState() {
    talker.verbose("Init App");
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
          talker.debug("Again Setup mqtt because host changed");
          // setupMqtt();
        }
      },
    );
    widget.settings.notiMqttPort.addListener(
      () {
        talker.debug("Again Setup mqtt because port changed");
        // setupMqtt();
      },
    );
    widget.settings.notiMqttTopic.addListener(
      () {
        // setState(() {
        //   unSubscribeOldTopic();
        //   subscribeTopic(widget.settings.notiMqttTopic.value);
        // });
      },
    );
    widget.settings.notiMqttInterval.addListener(
      () {
        changePublishInterval();
      },
    );
    widget.settings.notiSaved.addListener(
      () {
        talker.debug("Saved. For test change mqtt Connection");
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
          return GestureDetector(
              onVerticalDragEnd: (details) {
                if (dragStartY < 100 &&
                    details.localPosition.dy - dragStartY > 100) {
                  talker.debug("Refresh page");
                  _webViewController.reload();
                }
              },
              onVerticalDragStart: (details) {
                dragStartY = details.localPosition.dy;
              },
              child: WebViewWidget(controller: _webViewController));
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
    var bPub = await publishMessage("battery", batteryLevel.toString());
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
    if (_mqttClientPayloadBuilder == null) {
      var builder = MqttPayloadBuilder();

      setState(() {
        _mqttClientPayloadBuilder = builder;
      });
    }
  }

  Future<void> subscribeMqtt() async {
    try {
      if (_mqttClient != null) {
        talker.debug("Should be able to listen to mqtt topics");
      } else {
        talker.debug(
            "Should not be able to listen to mqtt topics. Client: $_mqttClient, updates: ${_mqttClient?.updates}");
      }
      await _streamSubscription?.cancel();
      _streamSubscription = _mqttClient?.updates
          .listen((List<MqttReceivedMessage<MqttMessage?>>? c) async {
        talker.debug("Received mqtt Message: ${c?[0].payload}");

        await publishMessage("pong",
            "${DateTime.now().minute.toString()}${DateTime.now().second.toString()}");

        if (c == null || c[0].topic == null) {
          return;
        }

        final recMess = c[0].payload as MqttPublishMessage;
        final pt =
            MqttUtilities.bytesToStringAsString(recMess.payload.message!);
        if (c[0].topic!.endsWith("/command")) {
          talker.verbose("Found topic with command at the end");
          try {
            var jPayload = jsonDecode(pt);
            talker.verbose("After json decode $jPayload");

            var bWake = jPayload["wake"];
            talker.verbose("bWake is: $bWake");
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
        widget.settings.notiMqttInterval.value =
            settings.mqttsensorinterval ?? 60;
        widget.settings.notiMqttPort.value = settings.mqttport ?? 1883;
        widget.settings.notiMqttPublish.value =
            settings.mqttsensorpublish ?? false;
        widget.settings.notiMqttTopic.value = settings.mqttsensortopic ?? "";
        widget.settings.notiUrl.value = settings.url ?? "http://google.com";
        widget.settings.mqttautoreconnect = settings.mqttautoreconnect;
        widget.settings.mqttclientidentifier = settings.mqttclientidentifier;
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
      mqttClient.onSubscribed = onSubscribed;
      mqttClient.onConnected = onConnected;
      mqttClient.onAutoReconnect = onAutoReconnect;
      mqttClient.onDisconnected = onDisconnected;
      mqttClient.onUnsubscribed = onUnSubscribed;
      mqttClient.onFailedConnectionAttempt = onFailedConnectionAttempt;
      mqttClient.onSubscribeFail = onSubscribeFail;
      var mqttStatus = await mqttClient.connect();
      talker.debug(
          "Connected to MQTT Server with state: $mqttStatus and identifier: ${widget.settings.mqttclientidentifier ?? "myClient"}");
      _mqttClient?.disconnect();
      setState(() {
        _mqttClient = mqttClient;
      });
    }
  }

  void onSubscribed(MqttSubscription topic) {
    talker.debug('Subscription confirmed for topic $topic');
  }

  void onUnSubscribed(MqttSubscription topic) {
    talker.debug('Unsubscribed for topic $topic');
  }

  void onConnected() {
    talker.debug('Connected');
  }

  void onAutoReconnect() {
    talker.debug('Auto Reconnect');
  }

  void onDisconnected() {
    talker.debug('Disconnected');
  }

  void onSubscribeFail(MqttSubscription mqttSub) {
    talker.debug('Subscription failed: ${mqttSub.topic}');
  }

  void onFailedConnectionAttempt(int attempt) {
    talker.debug('FailedConnectionAttempt: $attempt');
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
        var mqttStatus = await mqttClient.connect();
        talker.debug(
            "Connected to MQTT Server with state: $mqttStatus and identifier: ${widget.settings.mqttclientidentifier ?? "myClient"}");
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
        _mqttClient!.unsubscribeStringTopic(_subscribedTopic!);
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
          if (_mqttClient?.connectionStatus?.state !=
              MqttConnectionState.connected) {
            talker.debug("(Not) Reconnect Mqtt");
            //await setupMqtt();
          }
          var iMqttId = _mqttClient?.publishMessage(
              "${widget.settings.mqttsensortopic!}/$subtopic",
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

  Future<void> wakeupIntent(int wakeTime) async {
    talker.verbose("Before alarm");
    AndroidWakeLock.wakeUp();
    WakelockPlus.enable();
    // await _webViewController.reload();
    Future.delayed(Duration(seconds: wakeTime), () {
      WakelockPlus.disable();
    });
  }

  Future<void> disableWakeLock() async {
    talker.verbose("Disable WakeLock");
    WakelockPlus.disable();
  }
}
