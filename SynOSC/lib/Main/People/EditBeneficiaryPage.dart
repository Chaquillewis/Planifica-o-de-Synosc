import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class EditBeneficiaryPage extends StatefulWidget {
  final String userId;

  const EditBeneficiaryPage({super.key, required this.userId});

  @override
  State<EditBeneficiaryPage> createState() => _EditBeneficiaryPageState();
}

class _EditBeneficiaryPageState extends State<EditBeneficiaryPage> {
  final _nomeController = TextEditingController();
  final _nomeSocialController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _escolaridadeController = TextEditingController();
  final _ocupacaoController = TextEditingController();
  final _dependentesController = TextEditingController();
  final _programaController = TextEditingController();

  bool _carregando = true;
  String _statusSelecionado = 'ATIVO';
  String? _razaoInatividade;

  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});

  final List<String> _statusDisponiveis = ['ATIVO', 'INATIVO', 'AGUARDANDO DOCUMENTOS'];
  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosBeneficiario();
  }

  Future<void> _carregarDadosBeneficiario() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nomeController.text = data['nome'] ?? '';
        _nomeSocialController.text = data['nomeSocial'] ?? '';
        _cpfController.text = data['cpf'] ?? '';
        _telefoneController.text = data['telefone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _cepController.text = data['cep'] ?? '';
        _estadoController.text = data['estado'] ?? '';
        _cidadeController.text = data['cidade'] ?? '';
        _enderecoController.text = data['endereco'] ?? '';
        _escolaridadeController.text = data['escolaridade'] ?? '';
        _ocupacaoController.text = data['ocupacao'] ?? '';
        _dependentesController.text = data['numeroDependentes']?.toString() ?? '';
        _programaController.text = data['programa'] ?? '';
        _statusSelecionado = (data['status'] ?? 'ATIVO').toString().toUpperCase();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados')),
      );
    }
    setState(() => _carregando = false);
  }

  Future<void> _buscarCep(String cep) async {
    if (cep.length == 9) {
      final url = Uri.parse('https://viacep.com.br/ws/${cep.replaceAll('-', '')}/json/');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data.containsKey('erro')) {
          setState(() {
            _estadoController.text = data['uf'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _enderecoController.text = data['logradouro'] ?? '';
          });
        }
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode ser vazio.')),
      );
      return;
    }

    if (_programaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo Programa é obrigatório.')),
      );
      return;
    }

    if (_emailController.text.isNotEmpty && !_emailController.text.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail inválido.')),
      );
      return;
    }

    if (_statusSelecionado == 'INATIVO') {
      String? razao = await _mostrarDialogoRazao();
      if (razao == null || razao.trim().length < 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A razão deve ter pelo menos 15 caracteres.')),
        );
        return;
      }
      _razaoInatividade = razao.trim();
    } else {
      _razaoInatividade = null;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(widget.userId);
      final docSnapshot = await docRef.get();
      final currentUser = FirebaseAuth.instance.currentUser;

      Map<String, dynamic> dadosAtuais = docSnapshot.data() ?? {};

      Map<String, dynamic> novosDados = {
        'nome': _nomeController.text.trim(),
        'nomeSocial': _nomeSocialController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'email': _emailController.text.trim(),
        'cep': _cepController.text.trim(),
        'estado': _estadoController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'escolaridade': _escolaridadeController.text.trim(),
        'ocupacao': _ocupacaoController.text.trim(),
        'numeroDependentes': int.tryParse(_dependentesController.text.trim()) ?? 0,
        'programa': _programaController.text.trim(),
        'status': _statusSelecionado.toUpperCase(),
      };

      if (_razaoInatividade != null) {
        novosDados['razaoInatividade'] = _razaoInatividade;
      } else {
        novosDados.remove('razaoInatividade');
      }

      Map<String, dynamic> alteracoes = {};
      novosDados.forEach((chave, novoValor) {
        if (dadosAtuais[chave] != novoValor) {
          alteracoes[chave] = {'de': dadosAtuais[chave], 'para': novoValor};
        }
      });

      if (alteracoes.isNotEmpty) {
        await docRef.update(novosDados);

        final String codigoHistorico = DateTime.now().millisecondsSinceEpoch.toString();

        await docRef.collection('historicoAlteracoes').doc(codigoHistorico).set({
          'dataHora': FieldValue.serverTimestamp(),
          'alteradoPor': currentUser?.uid ?? 'sistema',
          'alteracoes': alteracoes,
          if (_razaoInatividade != null) 'razaoInatividade': _razaoInatividade
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiário atualizado com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar alterações: $e')),
      );
    }
  }

  Future<String?> _mostrarDialogoRazao() async {
    String? input;
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Motivo da Inativação'),
          content: TextField(
            maxLines: 3,
            onChanged: (value) => input = value,
            decoration: const InputDecoration(
              hintText: 'Descreva o motivo (mínimo 15 caracteres)',
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

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      bool obrigatorio, {
        TextInputType tipo = TextInputType.text,
        List<TextInputFormatter>? formato,
        void Function(String)? onChanged,
      }) {
    final preenchido = controller.text.trim().isNotEmpty;

    return TextField(
      controller: controller,
      keyboardType: tipo,
      inputFormatters: formato,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: preenchido ? Colors.black : Colors.grey.shade600,
        fontWeight: preenchido ? FontWeight.w500 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: obrigatorio ? '$label *' : label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text('Editar Beneficiário', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(_nomeController, 'Nome Completo', true),
            const SizedBox(height: 16),
            _buildTextField(_nomeSocialController, 'Nome Social (Opcional)', false),
            const SizedBox(height: 16),
            _buildTextField(_cpfController, 'CPF', false, formato: [_cpfFormatter]),
            const SizedBox(height: 16),
            _buildTextField(_telefoneController, 'Telefone', false, formato: [_telefoneFormatter]),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'E-mail', false, tipo: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_cepController, 'CEP', false, formato: [_cepFormatter], onChanged: _buscarCep),
            const SizedBox(height: 16),
            _buildTextField(_estadoController, 'Estado', false),
            const SizedBox(height: 16),
            _buildTextField(_cidadeController, 'Cidade', false),
            const SizedBox(height: 16),
            _buildTextField(_enderecoController, 'Endereço', false),
            const SizedBox(height: 16),
            _buildTextField(_escolaridadeController, 'Escolaridade', false),
            const SizedBox(height: 16),
            _buildTextField(_ocupacaoController, 'Ocupação', false),
            const SizedBox(height: 16),
            _buildTextField(_programaController, 'Programa', true), // NOVO
            const SizedBox(height: 16),
            _buildTextField(_dependentesController, 'Número de Dependentes', false, tipo: TextInputType.number),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _statusSelecionado,
              items: _statusDisponiveis.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (String? novoStatus) {
                if (novoStatus != null) {
                  setState(() {
                    _statusSelecionado = novoStatus;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Status',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarAlteracoes,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
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
}
