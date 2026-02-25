// BASE IMPORTS
import 'package:flutter/material.dart';

// FIREBASE IMPORTS
import 'package:firebase_core/firebase_core.dart';
import 'package:synosc/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// OTHER WIDGETS
import 'Login/MenuInicial.dart';
import 'Main/Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ativa App Check com Play Integrity no Android e App Attest no iOS
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  FirebaseFirestore.instance.collection("usuarios").doc("001").set({'Nome': 'Guilherme'});

  runApp(MaterialApp(
    home: MenuInicial(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff075E54),
        secondary: const Color(0xff25D366),
      ),
    ),
  ));
}
