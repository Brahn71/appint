import 'package:flutter/material.dart';
import 'reloj_alarma.dart';

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
                  SizedBox(width: 30, height: 40),
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
    );
  }
}
