import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DeleteUserPage extends StatefulWidget {
  const DeleteUserPage({super.key});

  @override
  State<DeleteUserPage> createState() => _DeleteUserPageState();
}

class _DeleteUserPageState extends State<DeleteUserPage> {
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

  Future<void> _confirmarExclusao(BuildContext context, String uid, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o usuário "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      // 1. Buscar e excluir documentos vinculados ao beneficiário
      final docsSnapshot = await firestore
          .collection('documentos')
          .where('codigoBeneficiario', isEqualTo: uid)
          .get();

      for (final doc in docsSnapshot.docs) {
        final docId = doc.id;

        // Excluir arquivos do Storage
        final pastaRef = storage.ref().child('documentos/$docId');
        final arquivos = await pastaRef.listAll();
        for (final item in arquivos.items) {
          await item.delete();
        }

        // Excluir documento no Firestore
        await firestore.collection('documentos').doc(docId).delete();
      }

      // 2. Excluir foto de perfil
      try {
        final fotoRef = storage.ref().child('fotos/$uid.jpg');
        await fotoRef.delete();
      } catch (_) {
        // ignorar caso não exista
      }

      // 3. Excluir usuário do Firestore
      await firestore.collection('usuarios').doc(uid).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário e dados relacionados excluídos com sucesso.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir usuário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Excluir Usuário', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _carregando || _codigoOscUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('codigoOsc', isEqualTo: _codigoOscUsuario)
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final usuarios = snapshot.data!.docs
              .where((doc) => doc.id != _uidUsuario)
              .toList();

          if (usuarios.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarExclusao(context, doc.id, nome),
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
