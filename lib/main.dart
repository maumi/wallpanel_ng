import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpanel-ng',
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Wallpanel-ng'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var pubTopic = 'wallpanel/test';
  var mqttClient = MqttServerClient.withPort('192.168.1.101', 'myClient', 1883);
  var builder = MqttClientPayloadBuilder();

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
  ..loadRequest(Uri.parse('http://192.168.1.85:8123/dashboard-home/0'));

  Future<int> getBatteryLevel() async {
    var battery = Battery();
    var batteryLevel = await battery.batteryLevel;

    return batteryLevel;
  }

  Future<void> publishBatteryState() async {
    var batteryLevel = await getBatteryLevel();
   if (mqttClient.connectionStatus?.state != MqttConnectionState.connected) {
      mqttClient.keepAlivePeriod = 20;
      await mqttClient.connect('myClientId');
   }
    var bPub = publishMessage(batteryLevel.toString());
    print("Publish successful: $bPub");
  }

  bool publishMessage(String payload) {
    var bRet = true;
    builder.clear();
    builder.addString(payload);
    try {
    if (builder.payload != null && mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      mqttClient.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
    }
    } catch (e) {
      print(e);
      bRet = false;
    }
    return bRet;
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          ElevatedButton(
            onPressed: () => publishBatteryState(), 
            child: Text("MQTT"))
        ]
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
