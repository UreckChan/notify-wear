import 'dart:convert';
import 'package:LedNotify/notification_controller.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:wear/wear.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'firebase_options.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Asegura la inicialización de los bindings de Flutter

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa AwesomeNotifications
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
        channelGroupKey: "basic_channel_group",
        channelKey: "basic_channel",
        channelName: "Basic Notifications",
        channelDescription: "Test notifications")
  ], channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: "basic_channel_group", channelGroupName: "Basic group")
  ]);

  bool isAllowedToSendNotification =
      await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotification) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
}

Future<String> getAccessToken() async {
  // Cargar el archivo JSON desde los activos
  final String response =
      await rootBundle.loadString('assets/notifications.json');
  final serviceAccountJson = json.decode(response);

  List<String> scopes = [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/firebase.database",
    "https://www.googleapis.com/auth/firebase.messaging"
  ];

  http.Client client = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
  );

  // Obtain the access token
  auth.AccessCredentials credentials =
      await auth.obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client);

  // Close the HTTP client
  client.close();

  // Return the access token
  return credentials.accessToken.data;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? notificationTitle;
  String? notificationBody;

  @override
  void initState() {
    super.initState();

    // Configuración de AwesomeNotifications
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);

    // Configuración de Firebase Messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Manejar el mensaje aquí
      setState(() {
        notificationTitle = message.notification?.title ?? 'Sin título';
        notificationBody = message.notification?.body ?? 'Sin contenido';
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Cuando se abre la app desde una notificación en segundo plano
      setState(() {
        notificationTitle = message.notification?.title ?? 'Sin título';
        notificationBody = message.notification?.body ?? 'Sin contenido';
      });
    });

    // Obtener el token de Firebase Messaging
    FirebaseMessaging.instance.getToken().then((token) {
      print('Token de Firebase Messaging: $token');
    });

    // Suscripción al topic 'allDevices'
    _subscribeToTopic();
  }

  Future<void> _subscribeToTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic('allDevices');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SmartWatch Counter",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.compact,
      ),
      home: WatchScreen(
          notificationTitle: notificationTitle,
          notificationBody: notificationBody),
    );
  }
}

class WatchScreen extends StatelessWidget {
  final String? notificationTitle;
  final String? notificationBody;

  const WatchScreen({super.key, this.notificationTitle, this.notificationBody});

  @override
  Widget build(BuildContext context) {
    return WatchShape(builder: (context, shape, child) {
      return AmbientMode(
        builder: (context, mode, child) => Counter(mode,
            notificationTitle: notificationTitle,
            notificationBody: notificationBody),
      );
    });
  }
}

class Counter extends StatefulWidget {
  final WearMode mode;
  final String? notificationTitle;
  final String? notificationBody;

  const Counter(this.mode,
      {super.key, this.notificationTitle, this.notificationBody});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:
            widget.mode == WearMode.active ? Colors.white : Colors.black,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.notificationBody == "Apagado"
                  ? Icons.radio_button_off
                  : widget.notificationBody == "Encendido"
                      ? Icons.radio_button_checked
                      : Icons
                          .notifications, // Puedes usar cualquier otro ícono por defecto
              size: 50, // Puedes ajustar el tamaño del ícono aquí
              color:
                  widget.mode == WearMode.active ? Colors.blue : Colors.white,
            ),
            SizedBox(height: 10),
            Center(
              child: Text(widget.notificationTitle ?? "LED"),
            ),
            SizedBox(height: 5),
            Center(
              child: Text(widget.notificationBody ?? ""),
            ),
          ],
        )));
  }
}
