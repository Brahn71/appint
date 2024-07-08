import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';

class RelojAlarma extends StatefulWidget {
  const RelojAlarma({Key? key}) : super(key: key);

  @override
  _RelojAlarmaState createState() => _RelojAlarmaState();
}

class _RelojAlarmaState extends State<RelojAlarma> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<DateTime> alarmas = [];

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadAlarmas();
  }

  void initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void loadAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmasString = prefs.getString('alarmas');
    if (alarmasString != null) {
      final List<dynamic> alarmasJson = jsonDecode(alarmasString);
      setState(() {
        alarmas = alarmasJson.map((json) => DateTime.parse(json)).toList();
      });
    }
  }

  void saveAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmasJson = alarmas.map((alarm) => alarm.toIso8601String()).toList();
    await prefs.setString('alarmas', jsonEncode(alarmasJson));
  }

  Future<void> agregarAlarma() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      setState(() {
        alarmas.add(selectedDateTime);
        programarNotificacion(selectedDateTime);
        saveAlarmas();
      });
    }
  }

  void eliminarAlarma(int index) async {
    await flutterLocalNotificationsPlugin.cancel(index); // Cancelar la notificación
    setState(() {
      alarmas.removeAt(index);
      saveAlarmas();
    });
  }

  void programarNotificacion(DateTime scheduledDate) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      alarmas.length,
      'Alarma',
      'Es hora de tu alarma!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          icon: 'app_icon',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ElevatedButton(
          onPressed: agregarAlarma,
          child: const Text('Agregar Alarma'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: alarmas.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Alarma ${index + 1}: ${alarmas[index].toLocal()}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    eliminarAlarma(index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
