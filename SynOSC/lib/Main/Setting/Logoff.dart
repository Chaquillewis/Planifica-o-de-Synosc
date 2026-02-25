import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Realiza logout do usuário autenticado no Firebase.
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Log opcional ou tratamento personalizado
      print('Erro ao fazer logout: $e');
    }
  }
}
