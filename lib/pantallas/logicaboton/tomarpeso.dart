import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TomarPeso extends StatelessWidget {
  const TomarPeso({super.key});

  static Future<String> obtenerPesoDesdeFirebase() async {
    DatabaseReference databaseReference =
    FirebaseDatabase.instance.ref().child('Usarios').child('peso');

    DatabaseEvent event = await databaseReference.once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      // Convertir el peso de gramos a kilogramos
      double pesoGramos = double.tryParse(snapshot.value.toString()) ?? 0.0;
      double pesoKilogramos = pesoGramos / 1000;
      return pesoKilogramos.toStringAsFixed(2); // Redondear a dos decimales
    } else {
      return 'Peso no encontrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
