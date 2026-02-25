import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// IMPORTS DAS TELAS
import '../Setting/Logoff.dart';
import '../Setting/EditProfile.dart';
import '../Setting/CadastroUsuario.dart';
import '../Setting/DeleteUsuario.dart';
import '../Setting/StatusProfile.dart';
import '../Setting/ReativarUsuariosPage.dart';  // ✅ Importação da nova tela

class MainSetting extends StatefulWidget {
  const MainSetting({super.key});

  @override
  State<MainSetting> createState() => _MainSettingState();
}

class _MainSettingState extends State<MainSetting> {
  String? _tipoUsuario;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTipoUsuario();
  }

  Future<void> _carregarTipoUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _tipoUsuario = data['tipo'];
          _carregando = false;
        });
      }
    }
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar saída'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          if (_tipoUsuario != 'beneficiario') ...[
            _buildSectionTitle('Gerenciar Usuários'),
            _buildCardTile(
              context,
              icon: Icons.person_add,
              title: 'Cadastrar Usuário',
              subtitle: 'Adicionar novo usuário',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CadastrarUsuarioPage()),
              ),
            ),
            _buildCardTile(
              context,
              icon: Icons.check_circle,
              title: 'Aceitar Usuário',
              subtitle: 'Aprovar novo usuário',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AprovarUsuariosPage()),
              ),
            ),
            _buildCardTile(
              context,
              icon: Icons.refresh,
              title: 'Reativar Usuário',
              subtitle: 'Reativar usuários inativos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReativarUsuariosPage()),  // ✅ Aqui adicionamos o botão
              ),
            ),
            _buildCardTile(
              context,
              icon: Icons.delete,
              title: 'Excluir Usuário',
              subtitle: 'Remover usuário do sistema',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeleteUserPage()),
              ),
            ),
            const SizedBox(height: 24),
          ],

          _buildSectionTitle('Conta'),
          _buildCardTile(
            context,
            icon: Icons.person,
            title: 'Meu Perfil',
            subtitle: 'Editar perfil',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Aplicativo'),
          _buildCardTile(
            context,
            icon: Icons.language,
            title: 'Idioma',
            subtitle: 'Escolher idioma',
            onTap: () {},
          ),
          _buildCardTile(
            context,
            icon: Icons.notifications,
            title: 'Notificações',
            subtitle: 'Configurar alertas',
            onTap: () {},
          ),
          _buildCardTile(
            context,
            icon: Icons.palette,
            title: 'Tema',
            subtitle: 'Claro / Escuro',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Sobre'),
          _buildCardTile(
            context,
            icon: Icons.info,
            title: 'Sobre o App',
            subtitle: 'Versão 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SynOSC',
                applicationVersion: '1.0.0', 
                applicationLegalese: '© 2025 GCT Inova Tech',
              );
            },
          ),
          _buildCardTile(
            context,
            icon: Icons.logout,
            title: 'Sair',
            subtitle: 'Encerrar sessão',
            onTap: () => _confirmarLogout(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1967D2),
        ),
      ),
    );
  }

  Widget _buildCardTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(icon, size: 28, color: const Color(0xFF4285F4)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          onTap: onTap,
        ),
      ),
    );
  }
}
