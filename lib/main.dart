import 'package:flutter/material.dart';
import '../pantallas/login.dart';
import '../pantallas/usuario.dart';


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
