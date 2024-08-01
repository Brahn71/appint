import 'package:appint/pantallas/logicaboton/tomarpeso.dart';
import 'package:appint/pantallas/reloj_alarma.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class Usuario extends StatefulWidget {
  final String nombreUsuario;
  final String email;
  final DateTime lastLogin;

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
  String? _peso;

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
      String errorMessage = 'Error: ${e.toString()}';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: const Text("Aceptar"),
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

  Future<void> _obtenerPeso() async {
    final peso = await TomarPeso.obtenerPesoDesdeFirebase();
    setState(() {
      _peso = peso;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Perfil de Usuario', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.alarm), text: 'Alarma'),
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.chair_alt,
                    size: 50,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.email.length >= 3 ? widget.email.substring(0, 3).toUpperCase()
                            : widget.email.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                    ],
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
                  title: Text(widget.email),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Último inicio de sesión: ${widget.lastLogin.toLocal()}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_peso != null) // Mostrar el peso si no es null
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                'Peso: $_peso Kg',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _obtenerPeso,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.settings_accessibility, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Tomar Peso',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _logout,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
