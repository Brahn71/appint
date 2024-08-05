import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TomarPeso extends StatelessWidget {
  const TomarPeso({super.key});

  static Future<String> obtenerPesoDesdeFirebase() async {
    DatabaseReference databaseReference =
    FirebaseDatabase.instance.ref().child('Usarios').child('peso');

    DatabaseEvent event = await databaseReference.once();
    DataSnapshot snapshot = event.snapshot;

    print('Valor recuperado de Firebase: ${snapshot.value}'); // Agrega esta línea

    if (snapshot.value != null) {
      double pesoGramos = double.tryParse(snapshot.value.toString()) ?? 0.0;
      double pesoKilogramos = pesoGramos / 1000;
      String pesoKilogramosString = pesoKilogramos.toStringAsFixed(2);

      // Obtener la fecha y hora actual
      String fechaHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Registrar el peso en la sección Peso1 con un nombre descriptivo y la fecha
      DatabaseReference peso1Ref = FirebaseDatabase.instance.ref().child('Usarios').child('Pesos');
      await peso1Ref.push().set({
        'nombre': 'peso',
        'valor': pesoKilogramosString,
        'fecha': fechaHora,
      });

      print('Datos registrados en Firebase: nombre=peso, valor=$pesoKilogramosString, fecha=$fechaHora'); // Agrega esta línea

      return pesoKilogramosString;
    } else {
      return 'Peso no encontrado';
    }
  }


  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
