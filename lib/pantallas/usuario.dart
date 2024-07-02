import 'package:flutter/material.dart';

class Usuario extends StatelessWidget {
  final String nombreUsuario;

  const Usuario({super.key, required this.nombreUsuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  colors: [Colors.blue.shade900, Colors.lightBlueAccent],
                ),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    nombreUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ListTile(
                    leading: Icon(Icons.email),
                    title: Text('usuario@example.com'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('+1234567890'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text('Ciudad, País'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  // Implementa la lógica para cerrar sesión o navegar hacia atrás
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15), backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}