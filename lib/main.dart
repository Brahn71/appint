import 'package:appint/pantallas/login.dart';
import 'package:appint/pantallas/usuario.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FITCHAIR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return Usuario(
              nombreUsuario: user.displayName ?? 'Nombre no disponible',
              email: user.email ?? 'No email',
              lastLogin: user.metadata.lastSignInTime ?? DateTime.now(),
            );
          } else {
            return Login();
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
