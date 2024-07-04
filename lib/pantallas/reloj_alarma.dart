import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RelojAlarma extends StatefulWidget {
  const RelojAlarma({super.key});

  @override
  _RelojAlarmaState createState() => _RelojAlarmaState();
}

class _RelojAlarmaState extends State<RelojAlarma> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<DateTime> alarmas = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _agregarAlarma() async {
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
        _programarNotificacion(selectedDateTime);
      });
    }
  }

  void _programarNotificacion(DateTime scheduledDate) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      alarmas.length,  // Unique id for each notification
      'Alarma',
      'Es hora de tu alarma!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
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
          onPressed: _agregarAlarma,
          child: const Text('Agregar Alarma'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: alarmas.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Alarma ${index + 1}: ${alarmas[index].toLocal()}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
