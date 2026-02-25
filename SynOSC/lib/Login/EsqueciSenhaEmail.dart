import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'EsqueciSenhaCode.dart';

class EsqueciSenhaEmail extends StatefulWidget {
  const EsqueciSenhaEmail({super.key});

  @override
  State<EsqueciSenhaEmail> createState() => _EsqueciSenhaEmailState();
}

class _EsqueciSenhaEmailState extends State<EsqueciSenhaEmail> {
  final TextEditingController _emailController = TextEditingController();
  String _mensagemErro = '';
  bool _carregando = false;

  void _enviarCodigo() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      setState(() => _mensagemErro = "Preencha um e-mail válido.");
      return;
    }

    setState(() {
      _mensagemErro = '';
      _carregando = true;
    });

    try {
      // Verifica se o e-mail existe
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _mensagemErro = 'E-mail não encontrado.';
          _carregando = false;
        });
        return;
      }

      final usuarioDoc = snap.docs.first;
      final userId = usuarioDoc.id;

      // Gera código aleatório de 6 dígitos
      final codigo = (Random().nextInt(900000) + 100000).toString();

      // Salva o código e timestamp temporário no Firestore
      await FirebaseFirestore.instance.collection('recuperacoes').doc(userId).set({
        'codigo': codigo,
        'email': email,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // TODO: Enviar e-mail real aqui, se tiver backend com SMTP ou EmailJS

      // Navega para próxima tela com email e userId
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EsqueciSenhaCode(userId: userId, email: email),
          ),
        );
      }
    } catch (e) {
      setState(() => _mensagemErro = "Erro ao processar: $e");
    } finally {
      setState(() => _carregando = false);
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _enviarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Enviar Código", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 16),

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
