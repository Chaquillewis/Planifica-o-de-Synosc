import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../Main/Chat/ChatPage.dart';

class MainChat extends StatefulWidget {
  const MainChat({super.key});

  @override
  State<MainChat> createState() => _MainChatState();
}

class _MainChatState extends State<MainChat> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _meuId;
  String _filtro = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
    _searchController.addListener(() {
      setState(() {
        _filtro = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _inicializarDados() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _meuId = user.uid;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _meuId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFE1F3FF),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversas')
                  .where('participantes', arrayContains: _meuId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final conversas = snapshot.data!.docs;

                if (conversas.isEmpty) {
                  return const Center(child: Text('Nenhuma conversa encontrada.'));
                }

                return ListView.builder(
                  itemCount: conversas.length,
                  itemBuilder: (context, index) {
                    final data = conversas[index].data() as Map<String, dynamic>;
                    final participantes = List<String>.from(data['participantes']);
                    final outroId = participantes.firstWhere((id) => id != _meuId);

                    final conversaId = conversas[index].id;
                    final ultimaMensagem = data['ultimaMensagem'] ?? '';
                    final remetenteId = data['remetenteId'] ?? '';
                    final lidaPor = List<String>.from(data['lidaPor'] ?? []);
                    final foiLida = lidaPor.contains(_meuId);

                    if (ultimaMensagem.isEmpty) return const SizedBox.shrink();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('usuarios').doc(outroId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

                        final usuarioData = snapshot.data!.data() as Map<String, dynamic>;
                        final nome = usuarioData['nome'] ?? '';
                        final caminhoFoto = usuarioData['fotoPerfil'] ?? '';

                        if (_filtro.isNotEmpty && !nome.toLowerCase().contains(_filtro)) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: FutureBuilder<String>(
                                future: caminhoFoto.isNotEmpty
                                    ? FirebaseStorage.instance.ref(caminhoFoto).getDownloadURL()
                                    : Future.value(''),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done &&
                                      snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    return CircleAvatar(
                                      backgroundImage: NetworkImage(snapshot.data!),
                                      radius: 26,
                                    );
                                  } else {
                                    return const CircleAvatar(
                                      backgroundImage: AssetImage('assets/default_user.jpg'),
                                      radius: 26,
                                    );
                                  }
                                },
                              ),
                              title: Text(
                                nome,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                ultimaMensagem,
                                style: TextStyle(
                                  fontWeight: !foiLida && remetenteId != _meuId
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: !foiLida && remetenteId != _meuId
                                  ? const Icon(Icons.circle, size: 10, color: Colors.green)
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      conversaId: conversaId,
                                      myUserId: _meuId!,
                                      otherUserId: outroId,
                                      otherUserName: nome,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
