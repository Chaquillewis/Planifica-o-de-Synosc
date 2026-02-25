import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nomeController = TextEditingController();
  final _nomeSocialController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _escolaridadeController = TextEditingController();
  final _ocupacaoController = TextEditingController();
  final _dependentesController = TextEditingController();

  String? _generoSelecionado;
  String? _estadoCivilSelecionado;

  final List<String> _generos = ['Masculino', 'Feminino', 'Outro'];
  final List<String> _estadosCivis = ['Solteiro', 'Casado', 'Divorciado', 'Viúvo'];

  File? _fotoPerfil;
  String? _fotoUrl;
  bool _carregando = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarDadosDoUsuario();
  }

  Future<void> _carregarDadosDoUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    String? caminho = data['fotoPerfil'];
    String? url;
    if (caminho != null && caminho.isNotEmpty) {
      try {
        url = await FirebaseStorage.instance.ref(caminho).getDownloadURL();
      } catch (_) {
        url = null;
      }
    }

    setState(() {
      _nomeController.text = data['nome'] ?? '';
      _nomeSocialController.text = data['nomeSocial'] ?? '';
      _dataNascimentoController.text = data['dataNascimento'] ?? '';
      _cpfController.text = data['cpf'] ?? '';
      _telefoneController.text = data['telefone'] ?? '';
      _cepController.text = data['cep'] ?? '';
      _estadoController.text = data['estado'] ?? '';
      _cidadeController.text = data['cidade'] ?? '';
      _enderecoController.text = data['endereco'] ?? '';
      _escolaridadeController.text = data['escolaridade'] ?? '';
      _ocupacaoController.text = data['ocupacao'] ?? '';
      _dependentesController.text = data['numeroDependentes']?.toString() ?? '';
      _generoSelecionado = data['genero'];
      _estadoCivilSelecionado = data['estadoCivil'];
      _fotoUrl = url;
      _carregando = false;
    });
  }

  Future<void> _selecionarFoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar Foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Selecionar da Galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final XFile? foto = await _picker.pickImage(source: source);
    if (foto != null) {
      final user = FirebaseAuth.instance.currentUser;
      final file = File(foto.path);

      if (user != null) {
        final caminho = 'fotos/${user.uid}.jpg';
        final ref = FirebaseStorage.instance.ref().child(caminho);
        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        setState(() {
          _fotoPerfil = file;
          _fotoUrl = url;
        });

        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
          'fotoPerfil': caminho,
        });
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome é obrigatório.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'nome': _nomeController.text.trim(),
        'nomeSocial': _nomeSocialController.text.trim(),
        'dataNascimento': _dataNascimentoController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'cep': _cepController.text.trim(),
        'estado': _estadoController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'escolaridade': _escolaridadeController.text.trim(),
        'ocupacao': _ocupacaoController.text.trim(),
        'numeroDependentes': int.tryParse(_dependentesController.text.trim()) ?? 0,
        'genero': _generoSelecionado,
        'estadoCivil': _estadoCivilSelecionado,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _selecionarFoto,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _fotoPerfil != null
                    ? FileImage(_fotoPerfil!)
                    : (_fotoUrl != null && _fotoUrl!.isNotEmpty
                    ? NetworkImage(_fotoUrl!)
                    : null),
                child: _fotoPerfil == null && (_fotoUrl == null || _fotoUrl!.isEmpty)
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _buildField(_nomeController, 'Nome Completo'),
            _buildField(_nomeSocialController, 'Como deseja ser chamado'),
            _buildField(_dataNascimentoController, 'Data de Nascimento', hint: 'dd/mm/aaaa'),
            _buildField(_cpfController, 'CPF'),
            _buildDropdown('Gênero', _generos, _generoSelecionado, (v) => setState(() => _generoSelecionado = v)),
            _buildDropdown('Estado Civil', _estadosCivis, _estadoCivilSelecionado, (v) => setState(() => _estadoCivilSelecionado = v)),
            _buildField(_telefoneController, 'Telefone'),
            _buildField(_cepController, 'CEP'),
            _buildField(_estadoController, 'Estado'),
            _buildField(_cidadeController, 'Cidade'),
            _buildField(_enderecoController, 'Endereço'),
            _buildField(_escolaridadeController, 'Escolaridade'),
            _buildField(_ocupacaoController, 'Ocupacão'),
            _buildField(_dependentesController, 'Número de Dependentes', keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarAlteracoes,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Salvar Alterações',
                  style: TextStyle(color: Colors.white), // <- texto em branco
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, String? hint}) {
    final isFilled = controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          fontStyle: isFilled ? FontStyle.normal : FontStyle.italic,
          color: isFilled ? Colors.black : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options.map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
