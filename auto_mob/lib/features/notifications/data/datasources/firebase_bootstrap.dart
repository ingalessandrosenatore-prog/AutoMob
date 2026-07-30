import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../firebase_options.dart';

/// Inizializza Firebase senza impedire l'avvio di AutoMob quando i file di
/// configurazione non sono ancora presenti. Questo e' utile fino a quando il
/// progetto Firebase Android/iOS non viene collegato con FlutterFire CLI.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (error) {
      debugPrint('Firebase non configurato: notifiche disabilitate ($error)');
      return false;
    }
  }
}
