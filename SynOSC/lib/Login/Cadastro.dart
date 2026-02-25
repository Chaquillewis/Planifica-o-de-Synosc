import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// OTHER WIDGETS
import 'Login.dart';
import '../../Model/Usuario.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final TextEditingController _controllerNome = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerSenha = TextEditingController();
  final TextEditingController _controllerRepitaSenha = TextEditingController();
  final TextEditingController _controllerCodigo = TextEditingController();

  String _mensagemErro = '';
  final Usuario _usuario = Usuario();
  bool _loading = false;

  bool _validarCampos() {
    String nome = _controllerNome.text.trim();
    String email = _controllerEmail.text.trim();
    String senha = _controllerSenha.text.trim();
    String repitaSenha = _controllerRepitaSenha.text.trim();
    String codigo = _controllerCodigo.text.trim();

    if (nome.isEmpty) {
      setState(() => _mensagemErro = "Preencha o Nome");
      return false;
    }
    if (email.isEmpty || !email.contains("@")) {
      setState(() => _mensagemErro = "Preencha um E-mail válido");
      return false;
    }
    if (senha.isEmpty || senha.length < 6) {
      setState(() => _mensagemErro = "Senha precisa ter no mínimo 6 caracteres");
      return false;
    }
    if (senha != repitaSenha) {
      setState(() => _mensagemErro = "As senhas não coincidem");
      return false;
    }
    if (codigo.isEmpty) {
      setState(() => _mensagemErro = "Preencha o Código da OSC");
      return false;
    }

    _usuario.nome = nome;
    _usuario.email = email;
    _usuario.senha = senha;
    _usuario.codigo = codigo;

    setState(() => _mensagemErro = '');
    return true;
  }

  Future<void> _cadastrarUsuario(Usuario usuario) async {
    setState(() => _loading = true);

    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
      );

      String uid = userCredential.user!.uid;

      await db.collection("usuarios").doc(uid).set({
        "nome": usuario.nome,
        "email": usuario.email,
        "codigoOsc": usuario.codigo,
        "tipo": "beneficiario",
        "status": "PENDENTE",
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } catch (error) {
      print('ERRO APP: $error');
      setState(() => _mensagemErro = "Erro ao cadastrar usuário. Verifique os dados.");
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
                Image.asset(
                  "assets/gct.png",
                  width: 180,
                  height: 200,
                ),
                const SizedBox(height: 32),

                _buildCampoTexto("Nome Completo", _controllerNome, icon: Icons.person),
                const SizedBox(height: 16),

                _buildCampoTexto("Email", _controllerEmail, tipo: TextInputType.emailAddress, icon: Icons.email),
                const SizedBox(height: 16),

                _buildCampoTexto("Senha", _controllerSenha, senha: true, icon: Icons.lock),
                const SizedBox(height: 16),

                _buildCampoTexto("Repita a Senha", _controllerRepitaSenha, senha: true, icon: Icons.lock),
                const SizedBox(height: 16),

                _buildCampoTexto("Código da OSC", _controllerCodigo, icon: Icons.domain),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_validarCampos()) {
                        _cadastrarUsuario(_usuario);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Cadastrar", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        );
                      },
                      child: const Text("Já possui conta? Fazer login"),
                    ),
                  ],
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

  Widget _buildCampoTexto(
      String label,
      TextEditingController controller, {
        TextInputType tipo = TextInputType.text,
        bool senha = false,
        IconData? icon,
      }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      obscureText: senha,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
