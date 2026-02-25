import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReativarUsuariosPage extends StatefulWidget {
  const ReativarUsuariosPage({super.key});

  @override
  State<ReativarUsuariosPage> createState() => _ReativarUsuariosPageState();
}

class _ReativarUsuariosPageState extends State<ReativarUsuariosPage> {
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

  Future<void> _reativarUsuario(String uid, String nome) async {
    final explicacao = await _mostrarDialogoExplicacao();

    if (explicacao == null || explicacao.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A explicação deve ter pelo menos 15 caracteres.')),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      await docRef.update({
        'status': 'ATIVO',
        'ultimaJustificativaReativacao': explicacao.trim(),
      });

      final String codigoHistorico = DateTime.now().millisecondsSinceEpoch.toString();

      await docRef.collection('historicoAlteracoes').doc(codigoHistorico).set({
        'dataHora': FieldValue.serverTimestamp(),
        'alteradoPor': _uidUsuario ?? 'sistema',
        'novaSituacao': 'ATIVO',
        'justificativa': explicacao.trim(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário "$nome" reativado com sucesso.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reativar usuário: $e')),
      );
    }
  }

  Future<String?> _mostrarDialogoExplicacao() async {
    String? input;
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Justificativa para Reativação'),
          content: TextField(
            maxLines: 3,
            onChanged: (value) => input = value,
            decoration: const InputDecoration(
              hintText: 'Explique o motivo (mínimo 15 caracteres)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, input),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Reativar Usuários', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _carregando || _codigoOscUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('codigoOsc', isEqualTo: _codigoOscUsuario)
            .where('status', whereNotIn: ['ATIVO', 'PENDENTE'])
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final usuarios = snapshot.data!.docs;

          if (usuarios.isEmpty) {
            return const Center(child: Text('Nenhum usuário para reativar.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final doc = usuarios[index];
              final data = doc.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? '';
              final email = data['email'] ?? '';
              final statusAtual = data['status'] ?? 'DESCONHECIDO';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Email: $email\nStatus atual: $statusAtual'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    tooltip: 'Reativar',
                    onPressed: () => _reativarUsuario(doc.id, nome),
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
