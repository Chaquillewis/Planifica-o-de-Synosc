import 'package:flutter/material.dart';
import 'package:synosc/Main/People/MainPeople.dart';
import 'package:synosc/Main/Document/MainDocument.dart';
import 'package:synosc/Main/Chat/MainChat.dart';
import 'package:synosc/Main/Setting/MainSetting.dart';
import 'package:synosc/Main/Document/UploadDocumentPage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Widget> _telas = [
    const MainPeople(),
    const MainDocument(),
    const MainChat(),
    const MainSetting(),
  ];

  final List<String> _titulos = [
    'Pessoas',
    'Documentos',
    'Mensagens',
    'Configurações',
  ];

  void _onAddDocument() {
    if (_currentIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadDocumentPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4285F4),
        title: Text(
          _titulos[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _currentIndex == 1
            ? [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Adicionar Documento',
            onPressed: _onAddDocument,
          ),
        ]
            : null,
      ),
      body: _telas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4285F4),
        unselectedItemColor: Colors.grey.shade700,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pessoas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Documentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Mensagens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
