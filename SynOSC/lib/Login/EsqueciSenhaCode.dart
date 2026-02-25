import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'EsqueciSenhaNova.dart';

class EsqueciSenhaCode extends StatefulWidget {
  final String userId;
  final String email;

  const EsqueciSenhaCode({super.key, required this.userId, required this.email});

  @override
  State<EsqueciSenhaCode> createState() => _EsqueciSenhaCodeState();
}

class _EsqueciSenhaCodeState extends State<EsqueciSenhaCode> {
  final TextEditingController _codigoController = TextEditingController();
  String _mensagemErro = '';
  bool _carregando = false;

  Future<void> _verificarCodigo() async {
    final codigoDigitado = _codigoController.text.trim();

    if (codigoDigitado.isEmpty || codigoDigitado.length != 6) {
      setState(() => _mensagemErro = "Digite um código válido.");
      return;
    }

    setState(() {
      _mensagemErro = '';
      _carregando = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('recuperacoes')
          .doc(widget.userId)
          .get();

      if (!doc.exists || doc.data()?['codigo'] != codigoDigitado) {
        setState(() {
          _mensagemErro = 'Código inválido.';
          _carregando = false;
        });
        return;
      }

      // Tudo certo: navegar para tela de nova senha
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EsqueciSenhaNova(userId: widget.userId, email: widget.email),
          ),
        );
      }
    } catch (e) {
      setState(() => _mensagemErro = 'Erro ao verificar código: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _reenviarCodigo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reenvio ainda não implementado.')),
    );
    // Aqui você pode usar o mesmo fluxo da tela anterior (EsqueciSenhaEmail)
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
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Código de Verificação",
                    prefixIcon: const Icon(Icons.verified_user),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _verificarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verificar Código", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _reenviarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Reenviar Código", style: TextStyle(fontSize: 18, color: Colors.white)),
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
