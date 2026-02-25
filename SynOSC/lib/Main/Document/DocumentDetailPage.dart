import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synosc/Model/Document.dart';

class DocumentDetailPage extends StatefulWidget {
  final Document document;
  final String documentId;

  const DocumentDetailPage({
    super.key,
    required this.document,
    required this.documentId,
  });

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late String _selectedStatus;
  final List<String> _statusOptions = ['Pendente', 'Aprovado', 'Rejeitado'];
  List<String> _imageUrls = [];
  bool _isBeneficiario = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.document.status;
    _verificarTipoUsuario();
    _carregarImagens();
  }

  Future<void> _verificarTipoUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      final tipo = doc.data()?['tipo'];
      setState(() {
        _isBeneficiario = tipo == 'beneficiario';
      });
    }
  }

  Future<void> _carregarImagens() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('documentos')
          .doc(widget.documentId)
          .get();

      final data = doc.data();
      if (data == null || !data.containsKey('imagens')) return;

      final List imagens = data['imagens'];
      final urls = await Future.wait(
        imagens.map((path) => FirebaseStorage.instance.ref(path).getDownloadURL()),
      );

      setState(() {
        _imageUrls = List<String>.from(urls);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar imagens: $e')),
      );
    }
  }

  Future<void> _atualizarStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('documentos')
          .doc(widget.documentId)
          .update({'status': _selectedStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    final preenchido = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontStyle: preenchido ? FontStyle.normal : FontStyle.italic,
                color: preenchido ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirVisualizador(int indexInicial) {
    showDialog(
      context: context,
      builder: (_) {
        int indexAtual = indexInicial;
        final pageController = PageController(initialPage: indexInicial);

        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                Container(
                  color: Colors.black,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: _imageUrls.length,
                    onPageChanged: (index) => setState(() => indexAtual = index),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        panEnabled: true,
                        minScale: 1,
                        maxScale: 5,
                        child: Center(
                          child: Image.network(
                            _imageUrls[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: Text(
                    '${indexAtual + 1} / ${_imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime data = widget.document.data;

    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Detalhes do Documento', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              widget.document.titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(data),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildDetailItem('Nome do Beneficiário', widget.document.nome),
            _buildDetailItem('Tipo do Documento', widget.document.tipoDocumento),
            _buildDetailItem('Status Atual', _selectedStatus),
            _buildDetailItem('Solicitado por', widget.document.solicitadoPor),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Atualizar Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: _isBeneficiario ? null : (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedStatus = newValue);
                }
              },
            ),

            const SizedBox(height: 24),
            if (!_isBeneficiario)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _atualizarStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Atualizar Status', style: TextStyle(color: Colors.white)),
                ),
              ),

            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Imagens:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _imageUrls.isEmpty
                ? const Text('Nenhuma imagem encontrada.')
                : SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _abrirVisualizador(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Image.network(
                        _imageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}