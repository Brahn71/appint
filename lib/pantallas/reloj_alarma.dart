import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

final String channelId = 'your_channel_id'; // Usar un ID único para el canal

class RelojAlarma extends StatefulWidget {
  const RelojAlarma({super.key});

  @override
  _RelojAlarmaState createState() => _RelojAlarmaState();
}

class _RelojAlarmaState extends State<RelojAlarma> {
  List<Map<String, dynamic>> alarmas = [];
  Timer? _timer;
  bool _alarmaActiva = false;

  @override
  void initState() {
    super.initState();
    loadAlarmas();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      final now = DateTime.now();
      for (var alarma in alarmas) {
        final DateTime alarmaDateTime = DateTime.parse(alarma['time']);
        final List<bool> diasSeleccionados = alarma['days'];

        if (diasSeleccionados[now.weekday - 1]) {
          if (now.hour == alarmaDateTime.hour && now.minute == alarmaDateTime.minute) {
            if (!_alarmaActiva) {
              _activarAlarma();
            }
            break; // Evita que la alarma se active nuevamente durante el minuto
          }
        }
      }

      // Resetea la alarma activa al inicio de cada minuto
      if (now.second == 0) {
        _alarmaActiva = false;
      }
    });
  }

  Future<void> loadAlarmas() async {
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

  Future<void> saveAlarmas() async {
    final prefs = await SharedPreferences.getInstance();
    final String alarmasJson = jsonEncode(alarmas);
    await prefs.setString('alarmas', alarmasJson);
  }

  Future<void> _activarAlarma() async {
    await actualizarLedBuz(true);
    _alarmaActiva = true; // Marcar la alarma como activa
    await Future.delayed(const Duration(seconds: 60));
    await actualizarLedBuz(false);
  }

  Future<void> actualizarLedBuz(bool estado) async {
    final url = Uri.parse('https://fitchair1-default-rtdb.firebaseio.com/ledbuz.json');
    final response = await http.patch(
      url,
      body: jsonEncode({'ledbuz': estado}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar ledbuz');
    }
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
          saveAlarmas();
        });
      }
    }
  }

  void eliminarAlarma(int index) async {
    setState(() {
      alarmas.removeAt(index);
      saveAlarmas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: agregarAlarma,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Agregar Alarma'),
              style: ElevatedButton.styleFrom(
                elevation: 5,
                padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: alarmas.isEmpty
                  ? const Center(child: Text('No hay alarmas. Agrega una alarma.'))
                  : ListView.builder(
                itemCount: alarmas.length,
                itemBuilder: (context, index) {
                  final DateTime alarmaDateTime = DateTime.parse(alarmas[index]['time']);
                  final List<bool> diasSeleccionados = alarmas[index]['days'];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        _formattedTime(alarmaDateTime),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _diasSeleccionadosToString(List<bool> diasSeleccionados) {
    final List<String> dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];

    return dias
        .asMap()
        .entries
        .where((entry) => diasSeleccionados[entry.key])
        .map((entry) => entry.value)
        .join(', ');
  }
}

class SelectDaysDialog extends StatefulWidget {
  final List<bool>? diasIniciales;

  const SelectDaysDialog({Key? key, this.diasIniciales}) : super(key: key);

  @override
  _SelectDaysDialogState createState() => _SelectDaysDialogState();
}

class _SelectDaysDialogState extends State<SelectDaysDialog> {
  late List<bool> diasSeleccionados;

  @override
  void initState() {
    super.initState();
    diasSeleccionados = widget.diasIniciales ?? List.generate(7, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona los días'),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(7, (index) {
            final String dia = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][index];
            return CheckboxListTile(
              title: Text(dia),
              value: diasSeleccionados[index],
              onChanged: (bool? value) {
                setState(() {
                  diasSeleccionados[index] = value ?? false;
                });
              },
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(diasSeleccionados);
          },
          child: const Text('Aceptar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
