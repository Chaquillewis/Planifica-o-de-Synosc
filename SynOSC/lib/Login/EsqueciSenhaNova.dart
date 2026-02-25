import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Login.dart';

class EsqueciSenhaNova extends StatefulWidget {
  final String userId;
  final String email;

  const EsqueciSenhaNova({super.key, required this.userId, required this.email});

  @override
  State<EsqueciSenhaNova> createState() => _EsqueciSenhaNovaState();
}

class _EsqueciSenhaNovaState extends State<EsqueciSenhaNova> {
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _repitaSenhaController = TextEditingController();

  String _mensagemErro = '';
  bool _carregando = false;

  Future<void> _validarNovaSenha() async {
    final novaSenha = _novaSenhaController.text.trim();
    final repitaSenha = _repitaSenhaController.text.trim();

    if (novaSenha.length < 6) {
      setState(() => _mensagemErro = "A senha deve ter no mínimo 6 caracteres.");
      return;
    }

    if (novaSenha != repitaSenha) {
      setState(() => _mensagemErro = "As senhas não coincidem.");
      return;
    }

    setState(() {
      _mensagemErro = '';
      _carregando = true;
    });

    try {
      // 🔒 Aqui você marca que o usuário solicitou alteração de senha
      await FirebaseFirestore.instance
          .collection('recuperacoes')
          .doc(widget.userId)
          .update({'novaSenha': novaSenha});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação de nova senha registrada.')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
      }
    } catch (e) {
      setState(() => _mensagemErro = 'Erro ao atualizar senha: $e');
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
                  controller: _novaSenhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Nova Senha",
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _repitaSenhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Repita a Nova Senha",
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _validarNovaSenha,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Validar Nova Senha", style: TextStyle(fontSize: 18, color: Colors.white)),
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
