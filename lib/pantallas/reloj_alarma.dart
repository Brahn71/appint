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
  List<Map<String, dynamic>> alarmas = [];

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
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tapped logic here
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Alarma"),
            content: Text("Es hora de pararte de la silla!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  void loadAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmasString = prefs.getString('alarmas');
    if (alarmasString != null) {
      final List<dynamic> alarmasJson = jsonDecode(alarmasString);
      setState(() {
        alarmas = alarmasJson.map((json) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(json);
          map['days'] = List<bool>.from(map['days']);
          return map;
        }).toList();
      });
    }
  }

  void saveAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final String alarmasJson = jsonEncode(alarmas);
    await prefs.setString('alarmas', alarmasJson);
  }

  Future<void> agregarAlarma() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final List<bool>? diasSeleccionados = await showDialog(
        context: context,
        builder: (context) {
          return SelectDaysDialog();
        },
      );

      if (diasSeleccionados != null && diasSeleccionados.contains(true)) {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );

        final nuevaAlarma = {
          'time': selectedDateTime.toIso8601String(),
          'days': diasSeleccionados,
        };

        setState(() {
          alarmas.add(nuevaAlarma);
          programarNotificacion(nuevaAlarma, alarmas.length - 1);
          saveAlarmas();
        });
      }
    }
  }

  Future<void> editarAlarma(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.parse(alarmas[index]['time'])),
    );

    if (picked != null) {
      final List<bool>? diasSeleccionados = await showDialog(
        context: context,
        builder: (context) {
          return SelectDaysDialog(
            diasIniciales: alarmas[index]['days'],
          );
        },
      );

      if (diasSeleccionados != null && diasSeleccionados.contains(true)) {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );

        final updatedAlarma = {
          'time': selectedDateTime.toIso8601String(),
          'days': diasSeleccionados,
        };

        setState(() {
          alarmas[index] = updatedAlarma;
          flutterLocalNotificationsPlugin.cancel(index);
          programarNotificacion(updatedAlarma, index);
          saveAlarmas();
        });
      }
    }
  }

  void eliminarAlarma(int index) async {
    await flutterLocalNotificationsPlugin.cancel(index);
    setState(() {
      alarmas.removeAt(index);
      saveAlarmas();
    });
  }

  void programarNotificacion(Map<String, dynamic> alarma, int id) async {
    final DateTime scheduledDate = DateTime.parse(alarma['time']);
    final List<bool> diasSeleccionados = alarma['days'];

    for (int i = 0; i < diasSeleccionados.length; i++) {
      if (diasSeleccionados[i]) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Alarma',
          'Es hora de pararte de la silla!',
          _nextInstanceOfScheduledDate(scheduledDate, i),
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
    }
  }

  tz.TZDateTime _nextInstanceOfScheduledDate(DateTime scheduledDate, int day) {
    tz.TZDateTime scheduledInstance = tz.TZDateTime.from(scheduledDate, tz.local);

    while (scheduledInstance.weekday != day + 1) {
      scheduledInstance = scheduledInstance.add(Duration(days: 1));
    }

    return scheduledInstance;
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
              final DateTime alarmaDateTime = DateTime.parse(alarmas[index]['time']);
              final List<bool> diasSeleccionados = alarmas[index]['days'];

              return ListTile(
                title: Text('Alarma ${index + 1}: ${alarmaDateTime.toLocal()}'),
                subtitle: Text('Días: ${_diasSeleccionadosToString(diasSeleccionados)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        editarAlarma(index);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        eliminarAlarma(index);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _diasSeleccionadosToString(List<bool> diasSeleccionados) {
    final List<String> dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final List<String> diasSeleccionadosString = [];

    for (int i = 0; i < diasSeleccionados.length; i++) {
      if (diasSeleccionados[i]) {
        diasSeleccionadosString.add(dias[i]);
      }
    }

    return diasSeleccionadosString.join(', ');
  }
}

class SelectDaysDialog extends StatefulWidget {
  final List<bool>? diasIniciales;

  const SelectDaysDialog({Key? key, this.diasIniciales}) : super(key: key);

  @override
  _SelectDaysDialogState createState() => _SelectDaysDialogState();
}

class _SelectDaysDialogState extends State<SelectDaysDialog> {
  late List<bool> _diasSeleccionados;

  @override
  void initState() {
    super.initState();
    _diasSeleccionados = widget.diasIniciales ?? List<bool>.filled(7, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Seleccionar días'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(7, (index) {
          final List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
          return CheckboxListTile(
            title: Text(dias[index]),
            value: _diasSeleccionados[index],
            onChanged: (bool? value) {
              setState(() {
                _diasSeleccionados[index] = value!;
              });
            },
          );
        }),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_diasSeleccionados);
          },
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}
