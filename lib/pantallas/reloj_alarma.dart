import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final String channelId = Uuid().v4(); // Generar un ID único para el canal

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
        // Manejo de la respuesta de la notificación
      },
    );

    _createNotificationChannel();
  }

  void _createNotificationChannel() async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,  // Usar el ID generado automáticamente
      'Alarm Channel',
      description: 'Channel for alarm notifications',
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

      // Reprogramar alarmas
      for (int i = 0; i < alarmas.length; i++) {
        programarNotificacion(alarmas[i], i);
      }
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
        }

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i, // Asegúrate de usar un ID único para cada notificación
          'Alarma',
          '¡Levántate flojo!',
          scheduledInstance,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              'Alarm Channel',
              channelDescription: 'Channel for alarm notifications',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableLights: true,
              enableVibration: true,
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

    while (scheduledInstance.weekday != (day + 1) % 7 + 1) {
      scheduledInstance = scheduledInstance.add(const Duration(days: 1));
    }

    if (kDebugMode) {
      print('Siguiente instancia programada: $scheduledInstance');
    }

    return scheduledInstance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: alarmas.length,
              itemBuilder: (context, index) {
                final DateTime alarmaDateTime = DateTime.parse(alarmas[index]['time']);
                final List<bool> diasSeleccionados = alarmas[index]['days'];

                return ListTile(
                  title: Text(_formattedTime(alarmaDateTime)),
                  subtitle: Text('Días: ${_diasSeleccionadosToString(diasSeleccionados)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mode_edit_outline_outlined),
                        onPressed: () {
                          editarAlarma(index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_outlined),
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
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: agregarAlarma,
              child: const Text('Agregar Alarma'),
            ),
          ),
        ],
      ),
    );
  }

  String _formattedTime(DateTime dateTime) {
    final hour = dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour; // Muestra 12 en lugar de 0 para las 12 AM/PM
    return "${displayHour.toString().padLeft(2, '0')}:${minute} $amPm";
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
          _buildDayCheckbox('Lunes', 0),
          _buildDayCheckbox('Martes', 1),
          _buildDayCheckbox('Miércoles', 2),
          _buildDayCheckbox('Jueves', 3),
          _buildDayCheckbox('Viernes', 4),
          _buildDayCheckbox('Sábado', 5),
          _buildDayCheckbox('Domingo', 6),
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

  CheckboxListTile _buildDayCheckbox(String title, int index) {
    return CheckboxListTile(
      title: Text(title),
      value: diasSeleccionados[index],
      onChanged: (bool? value) {
        setState(() {
          diasSeleccionados[index] = value ?? false;
        });
      },
    );
  }
}
