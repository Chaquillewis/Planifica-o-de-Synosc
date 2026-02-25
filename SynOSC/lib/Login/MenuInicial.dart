// BASE IMPORTS
import 'package:flutter/material.dart';

// OTHER WIDGETS
import 'Login.dart';
import 'Cadastro.dart';
import '../Main/Home.dart';

import 'package:firebase_auth/firebase_auth.dart';

class MenuInicial extends StatefulWidget {
  const MenuInicial({super.key});

  @override
  State<MenuInicial> createState() => _MenuInicialState();
}

class _MenuInicialState extends State<MenuInicial> {
  @override
  void initState() {
    _verificaUsuarioLogado();
    super.initState();
  }

  Future<void> _verificaUsuarioLogado() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      User? usuarioLogado = auth.currentUser;

      if (usuarioLogado != null) {
        Future.microtask(() {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
                  (Route<dynamic> route) => false,
            );
          }
        });
      }
    } catch (e) {
      print("Erro ao verificar usuário logado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  "assets/gct.png",
                  width: 180,
                  height: 200,
                ),
                const SizedBox(height: 24),

                // Mensagem (se quiser adicionar imagem ou texto)
                Text(
                  "Bem-vindo ao SynOSC",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 40),

                // Botões
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Entrar",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const Cadastro()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Inscrever-se",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                // const SizedBox(height: 24),
                // const Divider(thickness: 1.5),
                // const SizedBox(height: 24),

                // Botão Gmail (opcional)
                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton.icon(
                //     onPressed: () {
                //       // Implementar login Gmail no futuro
                //     },
                //     icon: const Icon(Icons.email),
                //     label: const Text(
                //       "Entrar com Gmail",
                //       style: TextStyle(fontSize: 18),
                //     ),
                //     style: OutlinedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //       side: BorderSide(color: Colors.blue.shade700),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
