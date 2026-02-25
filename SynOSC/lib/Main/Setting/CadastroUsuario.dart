import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class CadastrarUsuarioPage extends StatefulWidget {
  const CadastrarUsuarioPage({super.key});

  @override
  State<CadastrarUsuarioPage> createState() => _CadastrarUsuarioPageState();
}

class _CadastrarUsuarioPageState extends State<CadastrarUsuarioPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _repetirSenhaController = TextEditingController();

  String _tipoSelecionado = 'beneficiario';
  String? _codigoOsc;
  String _erro = '';
  bool _carregando = false;

  final List<String> _tipos = ['beneficiario', 'funcionario'];

  @override
  void initState() {
    super.initState();
    _buscarCodigoOsc();
  }

  Future<void> _buscarCodigoOsc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      setState(() {
        _codigoOsc = doc.data()?['codigoOsc'];
      });
    }
  }

  Future<void> _cadastrarUsuario() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final repetirSenha = _repetirSenhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || repetirSenha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _erro = 'E-mail inválido.');
      return;
    }

    if (senha != repetirSenha) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    if (_codigoOsc == null) {
      setState(() => _erro = 'Erro ao obter código da OSC.');
      return;
    }

    setState(() {
      _erro = '';
      _carregando = true;
    });

    try {
      // Cria um app Firebase secundário temporário
      final FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      await FirebaseFirestore.instance.collection('usuarios').doc(cred.user!.uid).set({
        'nome': nome,
        'email': email,
        'codigoOsc': _codigoOsc,
        'tipo': _tipoSelecionado,
        'status': 'ATIVO',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Limpa o usuário do app secundário
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao cadastrar: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Cadastrar Novo Usuário', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _codigoOsc == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_nomeController, 'Nome Completo'),
            const SizedBox(height: 12),
            _buildTextField(_emailController, 'E-mail', tipo: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildTextField(_senhaController, 'Senha', senha: true),
            const SizedBox(height: 12),
            _buildTextField(_repetirSenhaController, 'Repetir Senha', senha: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              decoration: InputDecoration(
                labelText: 'Tipo de usuário',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _tipos.map((tipo) {
                return DropdownMenuItem<String>(
                  value: tipo,
                  child: Text(tipo[0].toUpperCase() + tipo.substring(1)),
                );
              }).toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => _tipoSelecionado = valor);
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _carregando ? null : _cadastrarUsuario,
                icon: _carregando
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.person_add, color: Colors.white),
                label: Text(_carregando ? 'Cadastrando...' : 'Cadastrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_erro.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_erro, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType tipo = TextInputType.text, bool senha = false}) {
    final isFilled = controller.text.trim().isNotEmpty;

    return TextField(
      controller: controller,
      keyboardType: tipo,
      obscureText: senha,
      style: TextStyle(
        fontSize: 16,
        fontStyle: FontStyle.normal,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
