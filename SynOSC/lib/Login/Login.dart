import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Model/Usuario.dart';
import 'Cadastro.dart';
import 'EsqueciSenhaEmail.dart';
import '../Main/Home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerSenha = TextEditingController();

  String _mensagemErro = '';
  final Usuario _usuario = Usuario();
  bool _loading = false;

  bool _validarCampos() {
    String email = _controllerEmail.text.trim();
    String senha = _controllerSenha.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      setState(() => _mensagemErro = "Preencha um e-mail válido.");
      return false;
    }

    if (senha.isEmpty) {
      setState(() => _mensagemErro = "Preencha a senha.");
      return false;
    }

    _usuario.email = email;
    _usuario.senha = senha;
    return true;
  }

  void _logarUsuario(Usuario usuario) async {
    setState(() {
      _loading = true;
      _mensagemErro = '';
    });

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
      );

      final uid = userCredential.user!.uid;
      final doc = await firestore.collection('usuarios').doc(uid).get();
      final data = doc.data();

      if (data == null || data['status'] != 'ATIVO') {
        await auth.signOut();
        setState(() {
          _mensagemErro = "Conta ainda não foi ativada por um funcionário.";
        });
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
            (route) => false,
      );
    } catch (error) {
      print("ERRO APP: $error");
      setState(() {
        _mensagemErro = "Erro ao logar usuário. Verifique e tente novamente.";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset("assets/gct.png", width: 180, height: 200),
                const SizedBox(height: 32),

                TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _controllerSenha,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_validarCampos()) {
                        _logarUsuario(_usuario);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Entrar", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Cadastro()),
                        );
                      },
                      child: const Text("Não tem conta? Cadastre-se"),
                    ),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EsqueciSenhaEmail()),
                      );
                    },
                    child: const Text("Esqueceu a senha?"),
                  ),
                ),

                const SizedBox(height: 12),

                if (_mensagemErro.isNotEmpty)
                  Center(
                    child: Text(
                      _mensagemErro,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
