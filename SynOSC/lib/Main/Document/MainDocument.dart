import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Model/Document.dart';
import 'DocumentDetailPage.dart';

class MainDocument extends StatefulWidget {
  const MainDocument({super.key});

  @override
  State<MainDocument> createState() => _MainDocumentState();
}

class _MainDocumentState extends State<MainDocument> {
  final TextEditingController _searchController = TextEditingController();
  String? _codigoOsc;
  String? _userId;
  String? _tipo;
  String _filtro = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
    _searchController.addListener(() {
      setState(() {
        _filtro = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _buscarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final data = snap.data();
      if (data != null) {
        setState(() {
          _codigoOsc = data['codigoOsc'];
          _tipo = data['tipo'];
          _userId = user.uid;
          _carregando = false;
        });
      }
    }
  }

  void _abrirDetalhes(Document document, String documentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(document: document, documentId: documentId),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _codigoOsc == null || _userId == null || _tipo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Query query = FirebaseFirestore.instance.collection('documentos');

    if (_tipo == 'funcionario') {
      query = query.where('codigoOsc', isEqualTo: _codigoOsc);
    } else {
      query = query.where('codigoBeneficiario', isEqualTo: _userId);
    }

    query = query.orderBy('dataEnvio', descending: true);

    return Container(
      color: const Color(0xFFE1F3FF),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Filtrar por Nome do Beneficiário',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                final documentosFiltrados = docs.where((docSnap) {
                  final data = docSnap.data() as Map<String, dynamic>;
                  final nome = (data['beneficiario'] ?? '').toString().toLowerCase();
                  return _filtro.isEmpty || nome.contains(_filtro);
                }).toList();

                if (documentosFiltrados.isEmpty) {
                  return const Center(child: Text('Nenhum documento encontrado.'));
                }

                return ListView.builder(
                  itemCount: documentosFiltrados.length,
                  itemBuilder: (context, index) {
                    final docSnap = documentosFiltrados[index];
                    final data = docSnap.data() as Map<String, dynamic>;

                    final document = Document(
                      nome: data['beneficiario'] ?? '',
                      tipoDocumento: data['tipo'] ?? '',
                      status: data['status'] ?? '',
                      solicitadoPor: data['solicitadoPor'] ?? '',
                      data: (data['dataEnvio'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      titulo: data['titulo'] ?? '',
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onTap: () => _abrirDetalhes(document, docSnap.id),
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        document.titulo,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1967D2),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(document.data),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.black12),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCampo('Nome', document.nome),
                                    _buildCampo('Status', document.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCampo('Solicitado Por', document.solicitadoPor),
                                    _buildCampo('Tipo', document.tipoDocumento),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildCampo(String titulo, String valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
