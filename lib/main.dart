import 'dart:async';
import 'dart:convert';
import 'package:android_wake_lock/android_wake_lock.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wallpanel_ng/globals.dart';
import 'package:wallpanel_ng/model/settingsmodel.dart';
import 'package:wallpanel_ng/pages/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallpanel_ng/providers/settings_provider.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final useDark = settings.darkmode ?? false;
    return MaterialApp(
      title: 'Wallpanel-ng',
      darkTheme: ThemeData.dark(),
      themeMode: useDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Wallpanel-ng', settings: settings),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget  {
  const MyHomePage({super.key, required this.title, required this.settings});

  final String title;
  final SettingsModel settings;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> with WidgetsBindingObserver {
  MqttServerClient? _mqttClient;
  MqttClientPayloadBuilder? _mqttClientPayloadBuilder;
  // Timer? _publishTimer;
  String? _subscribedTopic;
  StreamSubscription? _streamSubscription;
  final double _webViewProgress = 1;
  InAppWebViewController? webViewController;
  String? _fabLocation;
  bool? _transparentSettings;
  bool _webViewPausedByApp = false;
  DateTime? _wakeupStartTime;

  // neu: detaillierte Zeiten + Poll-Timer
  DateTime? _wakeupResumeCallTime;
  DateTime? _appResumedTime;
  DateTime? _webviewResumeCompletedTime;
  Timer? _wakeupPollTimer;
  int _wakeupPollAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.settings;
    final cur = widget.settings;

    if (old.mqtthost != cur.mqtthost || old.mqttport != cur.mqttport) {
      changeMqttConnection();
    }

    if (old.mqttsensortopic != cur.mqttsensortopic) {
      if (old.mqttsensortopic?.isNotEmpty ?? false) unSubscribeOldTopic();
      if (cur.mqttsensortopic != null && cur.mqttsensortopic!.isNotEmpty) {
        subscribeTopic(cur.mqttsensortopic!);
      }
    }

    if (old.url != cur.url && cur.url != null && webViewController != null) {
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(cur.url!)));
    }

    if (old.fabLocation != cur.fabLocation) {
      setState(() {
        _fabLocation = cur.fabLocation;
      });
    }

    if (old.transparentsettings != cur.transparentsettings) {
      setState(() {
        _transparentSettings = cur.transparentsettings;
      });
    }
  }

  Future<void> initAsync() async {
    WidgetsFlutterBinding.ensureInitialized();
    final settings = ref.read(settingsNotifierProvider);
    if (settings.url != null && webViewController != null) {
      await webViewController!
          .loadUrl(urlRequest: URLRequest(url: WebUri(settings.url!)));
      //await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    await setupMqtt();

    // if (settings.mqttsensorpublish == true) {
    //   _publishTimer?.cancel();
    //   _publishTimer = null;
    //   _publishTimer = Timer.periodic(
    //     Duration(seconds: settings.mqttsensorinterval ?? 60),
    //     (timer) async {
    //       await publishBatteryState();
    //     },
    //   );
    // }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    talker.debug("didChangeAppLifecycleState: $state at ${DateTime.now()}");
    // wenn App in den Hintergrund geht: WebView pausieren
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseWebView();
      _webViewPausedByApp = true;
    } else if (state == AppLifecycleState.resumed) {
      _appResumedTime = DateTime.now();
      if (_wakeupStartTime != null) {
        talker.debug("Time since wakeup -> App resumed: ${_appResumedTime!.difference(_wakeupStartTime!).inMilliseconds} ms");
      } else {
        talker.debug("App resumed (no wakeupStartTime)");
      }
      if (_webViewPausedByApp) {
        _resumeWebView();
        _webViewPausedByApp = false;
      }
    }
  }

// navigation timing helper removed (unused). Keep code in VCS if needed later.

Future<void> _pauseWebView() async {
 try {
      // Plugin-API (falls implementiert)
      await webViewController?.pause();
    } catch (_) {}
    // try {
    //   // Fallback: stoppe Medien/Animationen per JS (geringere Risiko-API)
    //   await webViewController?.evaluateJavascript(source: """
    //     try {
    //       document.querySelectorAll('video,audio').forEach(v => { try { v.pause(); } catch(e){} });
    //       window.__wallpanel_paused = true;
    //     } catch(e){}
    //   """);
    // } catch (_) {}
  }

  Future<void> _resumeWebView() async {
    try {
      _wakeupResumeCallTime = DateTime.now();
      talker.debug("Resuming WebView called at $_wakeupResumeCallTime (since wakeup: ${_wakeupStartTime != null ? _wakeupResumeCallTime!.difference(_wakeupStartTime!).inMilliseconds : 'n/a'} ms)");
      await webViewController?.resume();
      _webviewResumeCompletedTime = DateTime.now();
      talker.debug("WebView.resume completed at $_webviewResumeCompletedTime (since wakeup: ${_wakeupStartTime != null ? _webviewResumeCompletedTime!.difference(_wakeupStartTime!).inMilliseconds : 'n/a'} ms)");
      _startWakeupPoll();
    } catch (e) {
      talker.debug("Resume WebView failed: $e");
    }
  }

  void _startWakeupPoll() {
    _wakeupPollAttempts = 0;
    _wakeupPollTimer?.cancel();
    _wakeupPollTimer = Timer.periodic(Duration(milliseconds: 250), (t) async {
      _wakeupPollAttempts++;
      if (webViewController == null) return;
      try {
        final readyState = await webViewController!.evaluateJavascript(source: "document.readyState");
        talker.debug("wakeupPoll #$_wakeupPollAttempts readyState=$readyState at ${DateTime.now()} (since wakeup: ${_wakeupStartTime != null ? DateTime.now().difference(_wakeupStartTime!).inMilliseconds : 'n/a'} ms)");
        if (readyState == 'complete' || _wakeupPollAttempts > 80) {
          talker.debug("wakeupPoll stopping (readyState=$readyState) after $_wakeupPollAttempts attempts");
          _wakeupPollTimer?.cancel();
          // await _logNavigationTiming();
        }
      } catch (e) {
        talker.debug("wakeupPoll eval failed: $e (attempt $_wakeupPollAttempts)");
        if (_wakeupPollAttempts > 80) _wakeupPollTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: webView(),
      floatingActionButton: fab(),
      floatingActionButtonLocation: mapFabLocations.containsKey(_fabLocation)
          ? mapFabLocations[_fabLocation]
          : FloatingActionButtonLocation.endDocked,
    );
  }

  Widget webView() {
    return _webViewProgress != 1
        ? biggerCircularProgressIndicator()
        : InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(ref.read(settingsNotifierProvider).url ?? "http://google.com")),
            initialSettings: InAppWebViewSettings(
              forceDark: ForceDark.ON,
              mediaPlaybackRequiresUserGesture: false,
              allowBackgroundAudioPlaying: false,
              allowsBackForwardNavigationGestures: false,
            ),
            onWebViewCreated: (controller) async {
              webViewController = controller;
              await fetchSettings();
              await initAsync();
            },
            // neu: Lade- / Fortschritts- Listener zum Messen von Verzögerungen
            onLoadStart: (controller, url) {
              talker.debug("onLoadStart ${url?.toString()} at ${DateTime.now()}");
              if (_wakeupStartTime != null) {
                talker.debug(
                    "Time since wakeup -> onLoadStart: ${DateTime.now().difference(_wakeupStartTime!).inMilliseconds} ms");
              }
            },
            onProgressChanged: (controller, progress) {
              talker.debug(
                  "onProgressChanged: $progress% at ${DateTime.now()} (since wakeup: ${_wakeupStartTime != null ? DateTime.now().difference(_wakeupStartTime!).inMilliseconds : 'n/a'} ms)");
            },
            onLoadStop: (controller, url) {
              talker.debug("onLoadStop ${url?.toString()} at ${DateTime.now()}");
              _wakeupPollTimer?.cancel();
              if (_wakeupStartTime != null) {
                talker.debug(
                    "Time since wakeup -> onLoadStop: ${DateTime.now().difference(_wakeupStartTime!).inMilliseconds} ms");
                // optional: clear timestamp nachdem geladen
                _wakeupStartTime = null;
              }
            },
            onReceivedError: (controller, request, error) {
              _wakeupPollTimer?.cancel();
              // Log the error and request in a generic way to avoid SDK-version
              // or platform-specific field differences on WebResourceError/WebResourceRequest
              String urlString;
              try {
                urlString = request.url.toString();
              } catch (_) {
                urlString = request.toString();
              }

              talker.error(
                  "onReceivedError ({description}) for $urlString at ${DateTime.now()}");
            },
            onConsoleMessage: (controller, consoleMessage) async {
              //talker.debug(consoleMessage.message);
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
          ? Colors.grey.withValues(alpha: 0.05)
          : Colors.grey,
      foregroundColor: _transparentSettings == true
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.white,
      heroTag: 'fabSettings',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
      child: GestureDetector(
        onLongPress: () {
          if (webViewController != null) {
            webViewController?.reload();
          }
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  // void changePublishInterval() {
  //   _publishTimer?.cancel();
  //   _publishTimer = null;
  //   _publishTimer = Timer.periodic(
  //     Duration(seconds: widget.settings.mqttsensorinterval ?? 60),
  //     (timer) async {
  //       await publishBatteryState();
  //     },
  //   );
  // }

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
        // await publishMessage("pong",
        //     "${DateTime.now().minute.toString()}${DateTime.now().second.toString()}");

        await publishBatteryState();

        if (c == null) {
          return;
        }

        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        if (c[0].topic.endsWith("echo")) {
          try {
            publishMessage("echoBack", pt);
          } catch (e) {
            talker.warning("Wrong command");
          }
        }
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
              await disableWakeLock();
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
      final notifier = ref.read(settingsNotifierProvider.notifier);
      notifier.loadFromJson(jSettings);
      final settings = ref.read(settingsNotifierProvider);
      if (settings.url != null) {
        webViewController?.loadUrl(
            urlRequest: URLRequest(url: WebUri(settings.url!)));
      }
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
    final settings = ref.read(settingsNotifierProvider);
    if (settings.mqttsensortopic != null) {
      subscribeTopic(settings.mqttsensortopic!);
    }
  }

  Future<void> connectMqtt() async {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.mqtthost != null) {
      var clientId = Uuid().v4().toString();
      var mqttClient = MqttServerClient.withPort(settings.mqtthost!,
          clientId, settings.mqttport ?? 1883);
      mqttClient.keepAlivePeriod = 30;
      mqttClient.autoReconnect = true;
      var mqttStatus = await mqttClient.connect(
          settings.mqttUser, settings.mqttPassword);
      talker.debug(
          "Connected to MQTT Server with state: $mqttStatus and identifier: $clientId");
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
      var clientId = Uuid().v4().toString();
        final settings = ref.read(settingsNotifierProvider);
        if (settings.mqtthost != null && settings.mqttport != null) {
        var mqttClient = MqttServerClient.withPort(
          settings.notiMqttHost.value,
          clientId,
          settings.notiMqttPort.value);
        mqttClient.keepAlivePeriod = 60;
        var mqttStatus = await mqttClient.connect(
          settings.mqttUser, settings.mqttPassword);
        talker.debug(
            "Connected to MQTT Server with state: $mqttStatus and identifier: $clientId");
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
        _mqttClient?.subscribe("$topic/echo", MqttQos.atMostOnce);
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
    final settings = ref.read(settingsNotifierProvider);
    if (settings.mqttsensortopic != null) {
      try {
        _mqttClientPayloadBuilder?.clear();
        _mqttClientPayloadBuilder?.addString(payload);
        if (_mqttClientPayloadBuilder?.payload != null &&
            settings.mqttsensortopic != null) {
          _mqttClient?.publishMessage(
              "${settings.mqttsensortopic!}/$subtopic",
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
    talker.debug("Before AndroidWakeLock");

        // setze Startzeit für Messung
    _wakeupStartTime = DateTime.now();
    talker.debug("wakeupIntent started at $_wakeupStartTime, wakeTime=$wakeTime");

    // WebView so früh wie möglich wieder aufnehmen (schnell und ohne zu blockieren)
    try {
      // Fire-and-forget: starte Resume asynchron, blockiert nicht den weiteren Ablauf
      _resumeWebView();
    } catch (e) {
      talker.debug("Resume WebView failed: $e");
    }

    await AndroidWakeLock.wakeUp();
    talker.debug('Before WakelockPlus.enable');
    await WakelockPlus.enable();
    talker.debug('Before Future.delayed');
    await Future.delayed(Duration(seconds: wakeTime));
    talker.debug('Before WakelockPlus.disable');
    await WakelockPlus.disable();
    talker.debug('After WakelockPlus.disable');
  }

  Future<void> disableWakeLock() async {
    talker.debug('In function disableWakeLock');
    await WakelockPlus.disable();
  }
}
