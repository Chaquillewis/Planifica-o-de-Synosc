import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../Main/Chat/ChatPage.dart';
import '../../Main/Document/UploadDocumentPage.dart';
import 'EditBeneficiaryPage.dart';

class MainPeople extends StatefulWidget {
  const MainPeople({super.key});

  @override
  State<MainPeople> createState() => _MainPeopleState();
}

class _MainPeopleState extends State<MainPeople> {
  final TextEditingController _searchController = TextEditingController();
  String? _codigoOscUsuario;
  String? _uidUsuario;
  String? _tipoUsuarioLogado;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _uidUsuario = user.uid;
            _codigoOscUsuario = data['codigoOsc'];
            _tipoUsuarioLogado = data['tipo'];
            _carregando = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.lightBlue.shade50,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar pessoas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('codigoOsc', isEqualTo: _codigoOscUsuario)
                  .where('status', isEqualTo: 'ATIVO')
                  .orderBy('nome')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((d) => d.id != _uidUsuario).toList();
                final filtro = _searchController.text.trim().toLowerCase();

                final filtrados = filtro.isEmpty
                    ? docs
                    : docs.where((d) {
                  final nome = (d.data() as Map<String, dynamic>)['nome']?.toLowerCase() ?? '';
                  return nome.contains(filtro);
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text('Nenhum usuário encontrado.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = filtrados[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final nome = data['nome'] ?? '';
                    final tipo = data['tipo'] ?? '';
                    final caminhoFoto = data['fotoPerfil'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: FutureBuilder<String>(
                          future: caminhoFoto.isNotEmpty
                              ? FirebaseStorage.instance.ref(caminhoFoto).getDownloadURL()
                              : Future.value(''),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data!.isNotEmpty) {
                              return CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(snapshot.data!),
                              );
                            } else {
                              return const CircleAvatar(
                                radius: 26,
                                backgroundImage: AssetImage('assets/default_user.jpg'),
                              );
                            }
                          },
                        ),
                        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(tipo == 'beneficiario' ? 'Beneficiário' : 'Funcionário'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_tipoUsuarioLogado != 'beneficiario' && tipo == 'beneficiario') ...[
                              _buildIconButton(
                                icon: Icons.edit,
                                tooltip: 'Editar Beneficiário',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EditBeneficiaryPage(userId: id)),
                                  );
                                },
                              ),
                              _buildIconButton(
                                icon: Icons.upload_file,
                                tooltip: 'Enviar Documento',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UploadDocumentPage(nomePreenchido: nome),
                                    ),
                                  );
                                },
                              ),
                            ],
                            _buildIconButton(
                              icon: Icons.chat,
                              tooltip: 'Abrir Chat',
                              onPressed: () async {
                                final conversaId = await _obterOuCriarConversa(_uidUsuario!, id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      conversaId: conversaId,
                                      myUserId: _uidUsuario!,
                                      otherUserId: id,
                                      otherUserName: nome,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.blueAccent),
            onPressed: onPressed,
            splashRadius: 20,
          ),
        ),
      ),
    );
  }

  Future<String> _obterOuCriarConversa(String meuId, String outroId) async {
    final conversas = FirebaseFirestore.instance.collection('conversas');

    final query = await conversas
        .where('participantes', arrayContains: meuId)
        .get();

    for (var doc in query.docs) {
      final dados = doc.data();
      final participantes = List<String>.from(dados['participantes']);
      if (participantes.contains(outroId)) {
        return doc.id;
      }
    }

    final nova = await conversas.add({
      'participantes': [meuId, outroId],
      'ultimaMensagem': '',
      'remetenteId': '',
      'lidaPor': [],
      'timestamp': FieldValue.serverTimestamp(),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return nova.id;
  }
}
