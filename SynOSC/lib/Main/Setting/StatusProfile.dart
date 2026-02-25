import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AprovarUsuariosPage extends StatefulWidget {
  const AprovarUsuariosPage({super.key});

  @override
  State<AprovarUsuariosPage> createState() => _AprovarUsuariosPageState();
}

class _AprovarUsuariosPageState extends State<AprovarUsuariosPage> {
  String? _codigoOscUsuario;
  String? _uidUsuario;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuarioLogado();
  }

  Future<void> _carregarUsuarioLogado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _uidUsuario = user.uid;
          _codigoOscUsuario = data['codigoOsc'];
          _carregando = false;
        });
      }
    }
  }

  Future<void> _alterarStatusUsuario(String uid, String nome, String status) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'status': status,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário "$nome" atualizado para $status.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar usuário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Aprovar Usuários', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _carregando || _codigoOscUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('codigoOsc', isEqualTo: _codigoOscUsuario)
            .where('status', isEqualTo: 'PENDENTE')
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final usuarios = snapshot.data!.docs;

          if (usuarios.isEmpty) {
            return const Center(child: Text('Nenhum usuário pendente para aprovação.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final doc = usuarios[index];
              final data = doc.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? '';
              final email = data['email'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Aprovar',
                        onPressed: () => _alterarStatusUsuario(doc.id, nome, 'ATIVO'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Rejeitar',
                        onPressed: () => _alterarStatusUsuario(doc.id, nome, 'REJEITADO'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
