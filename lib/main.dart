import 'package:appint/pantallas/login.dart';
import 'package:appint/pantallas/usuario.dart';
import 'package:flutter/material.dart';
import '../pantallas/login.dart'; // Importa tu pantalla de inicio de sesión
import '../pantallas/usuario.dart'; // Importa tu pantalla de usuarios

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // Ruta inicial
      routes: {
        '/': (context) => Login(), // Ruta para la pantalla de inicio de sesión
        '/usuarios': (context) => Usuario(nombreUsuario: 'parra',), // Ruta para la pantalla de usuarios
      },
    );
  }
}