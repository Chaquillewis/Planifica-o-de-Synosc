import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MaterialApp(
    home: UploadDocumentPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class UploadDocumentPage extends StatefulWidget {
  final String? nomePreenchido;

  const UploadDocumentPage({super.key, this.nomePreenchido});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _imagensSelecionadas = [];

  String? _tipoUsuario;
  String? _nomeUsuario;
  String? _uidUsuario;
  String? _codigoOsc;

  bool _carregando = true;
  bool _isEnviando = false;

  List<String> _beneficiarios = [];

  final List<String> _tiposDocumento = [
    'RG',
    'CPF',
    'Comprovante de Endereço',
    'Certidão de Nascimento',
    'Título de Eleitor',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final data = doc.data();

      if (data != null) {
        _tipoUsuario = data['tipo'];
        _nomeUsuario = data['nome'];
        _uidUsuario = user.uid;
        _codigoOsc = data['codigoOsc'];

        if (_tipoUsuario == 'beneficiario') {
          _nomeController.text = _nomeUsuario ?? '';
        } else {
          final snap = await FirebaseFirestore.instance
              .collection('usuarios')
              .where('codigoOsc', isEqualTo: _codigoOsc)
              .where('tipo', isEqualTo: 'beneficiario')
              .orderBy('nome')
              .get();

          _beneficiarios = snap.docs.map((d) => d['nome'].toString()).toList();
        }

        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _selecionarImagensGaleria() async {
    final List<XFile>? imagens = await _picker.pickMultiImage();
    if (imagens != null && imagens.isNotEmpty) {
      setState(() {
        _imagensSelecionadas.addAll(imagens);
      });
    }
  }

  Future<void> _tirarFotoCamera() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        _imagensSelecionadas.add(foto);
      });
    }
  }

  Future<void> _enviarDocumento() async {
    final titulo = _tituloController.text.trim();
    final nome = _nomeController.text.trim();
    final tipo = _tipoController.text.trim();

    if (titulo.isEmpty || nome.isEmpty || tipo.isEmpty || _imagensSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos e adicione ao menos uma imagem.')),
      );
      return;
    }

    setState(() => _isEnviando = true);

    try {
      String? codigoBeneficiario;

      if (_tipoUsuario == 'beneficiario') {
        codigoBeneficiario = _uidUsuario;
      } else {
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('nome', isEqualTo: nome)
            .where('codigoOsc', isEqualTo: _codigoOsc)
            .where('tipo', isEqualTo: 'beneficiario')
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Beneficiário não encontrado.')),
          );
          setState(() => _isEnviando = false);
          return;
        }

        codigoBeneficiario = query.docs.first.id;
      }

      // Cria documento no Firestore para obter o ID
      final docRef = await FirebaseFirestore.instance.collection('documentos').add({
        'titulo': titulo,
        'tipo': tipo,
        'beneficiario': nome,
        'codigoBeneficiario': codigoBeneficiario,
        'solicitadoPor': _tipoUsuario == 'funcionario' ? _nomeUsuario : null,
        'dataEnvio': FieldValue.serverTimestamp(),
        'status': 'Pendente',
        'codigoOsc': _codigoOsc,
        'imagens': [],
      });

      final List<String> caminhos = [];

      for (int i = 0; i < _imagensSelecionadas.length; i++) {
        final file = File(_imagensSelecionadas[i].path);
        final fileName = 'imagem_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final path = 'documentos/${docRef.id}/$fileName';

        final ref = FirebaseStorage.instance.ref().child(path);
        await ref.putFile(file);

        caminhos.add(path);
      }

      await docRef.update({'imagens': caminhos});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento enviado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar documento.')),
      );
    } finally {
      setState(() => _isEnviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Novo Documento', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTextField(_tituloController, 'Título do Documento'),
          const SizedBox(height: 16),
          _tipoUsuario == 'funcionario'
              ? DropdownButtonFormField<String>(
            value: _nomeController.text.isEmpty ? null : _nomeController.text,
            items: _beneficiarios.map((String nome) {
              return DropdownMenuItem<String>(
                value: nome,
                child: Text(nome),
              );
            }).toList(),
            onChanged: (value) => _nomeController.text = value!,
            decoration: InputDecoration(
              labelText: 'Nome do Beneficiário',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
              : _buildTextField(_nomeController, 'Nome do Beneficiário', readOnly: true),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _tipoController.text.isEmpty ? null : _tipoController.text,
            items: _tiposDocumento.map((String tipo) {
              return DropdownMenuItem<String>(
                value: tipo,
                child: Text(tipo),
              );
            }).toList(),
            onChanged: (value) => _tipoController.text = value!,
            decoration: InputDecoration(
              labelText: 'Tipo de Documento',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Status: Pendente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Solicitado por: ${_tipoUsuario == 'funcionario' ? _nomeUsuario : '---'}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Data: $dataHoje', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: _tirarFotoCamera,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('Tirar Foto', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selecionarImagensGaleria,
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: const Text('Galeria', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _imagensSelecionadas.isEmpty
              ? const Text('Nenhuma imagem selecionada.')
              : SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagensSelecionadas.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Image.file(
                    File(_imagensSelecionadas[index].path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEnviando ? null : _enviarDocumento,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isEnviando
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Enviar Documento', style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
