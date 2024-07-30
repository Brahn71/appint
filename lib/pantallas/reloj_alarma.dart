import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class RelojAlarma extends StatefulWidget {
  const RelojAlarma({super.key});

  @override
  _RelojAlarmaState createState() => _RelojAlarmaState();
}

class _RelojAlarmaState extends State<RelojAlarma> {
  List<Map<String, dynamic>> alarmas = [];

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadAlarmas();
  }

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tapped logic here
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Alarma"),
            content: const Text("Es hora de pararte de la silla!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
    );

    _createNotificationChannel(); // Ensure the notification channel is created
  }

  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id',
      'your_channel_name',
      description: 'your_channel_description',
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
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
      final List<bool>? diasSeleccionados = await showDialog<List<bool>>(
        context: context,
        builder: (context) {
          return const SelectDaysDialog();
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

  Future<void> programarNotificacion(Map<String, dynamic> alarma, int id) async {
    final DateTime scheduledDate = DateTime.parse(alarma['time']);
    final List<bool> diasSeleccionados = alarma['days'];

    for (int i = 0; i < diasSeleccionados.length; i++) {
      if (diasSeleccionados[i]) {
        final tz.TZDateTime scheduledInstance = _nextInstanceOfScheduledDate(scheduledDate, i);
        if (kDebugMode) {
          print('Programando notificación para $scheduledInstance');
        } // Log para verificar la programación

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Alarma',
          'Es hora de pararte de la silla!',
          scheduledInstance,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'your_channel_id',
              'your_channel_name',
              channelDescription: 'your_channel_description',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exact,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  tz.TZDateTime _nextInstanceOfScheduledDate(DateTime scheduledDate, int day) {
    tz.TZDateTime scheduledInstance = tz.TZDateTime.from(scheduledDate, tz.local);

    while (scheduledInstance.weekday != day + 1) {
      scheduledInstance = scheduledInstance.add(const Duration(days: 1));
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
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        editarAlarma(index);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
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
  final List<bool> diasIniciales;

  const SelectDaysDialog({super.key, this.diasIniciales = const [false, false, false, false, false, false, false]});

  @override
  _SelectDaysDialogState createState() => _SelectDaysDialogState();
}

class _SelectDaysDialogState extends State<SelectDaysDialog> {
  late List<bool> diasSeleccionados;

  @override
  void initState() {
    super.initState();
    diasSeleccionados = List<bool>.from(widget.diasIniciales);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona los días'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CheckboxListTile(
            title: const Text('Lunes'),
            value: diasSeleccionados[0],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[0] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Martes'),
            value: diasSeleccionados[1],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[1] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Miércoles'),
            value: diasSeleccionados[2],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[2] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Jueves'),
            value: diasSeleccionados[3],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[3] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Viernes'),
            value: diasSeleccionados[4],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[4] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Sábado'),
            value: diasSeleccionados[5],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[5] = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Domingo'),
            value: diasSeleccionados[6],
            onChanged: (bool? value) {
              setState(() {
                diasSeleccionados[6] = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(diasSeleccionados);
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
