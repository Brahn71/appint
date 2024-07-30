import 'package:appint/pantallas/reloj_alarma.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart'; // Asegúrate de importar el archivo Login.dart

class Usuario extends StatefulWidget {
  final String nombreUsuario;
  final String email; // Agregado para mostrar el correo electrónico
  final DateTime lastLogin; // Agregado para mostrar la última fecha de inicio de sesión

  const Usuario({
    super.key,
    required this.nombreUsuario,
    required this.email,
    required this.lastLogin,
  });

  @override
  _UsuarioState createState() => _UsuarioState();
}

class _UsuarioState extends State<Usuario> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } catch (e) {
      // Manejo de errores en caso de fallo al cerrar sesión
      String errorMessage = 'Error: ${e.toString()}';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: Text("Aceptar"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.alarm), text: 'Reloj de Alarma'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPerfil(),
          const RelojAlarma(),
        ],
      ),
    );
  }

  Widget _buildPerfil() {
    return SingleChildScrollView(
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
                  widget.nombreUsuario,
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
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(widget.email), // Mostrar el correo electrónico
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Último inicio de sesión: ${widget.lastLogin.toLocal()}'), // Mostrar la última fecha de inicio de sesión
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _logout, // Cambiado para llamar al método _logout
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Colors.blue.shade900,
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
        ],
      ),
    );
  }
}
