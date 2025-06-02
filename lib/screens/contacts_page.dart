import 'dart:math';
import 'package:flutter/material.dart';
import 'chat_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String userId = '';
  String nickname = '';
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _generateRandomUserId();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _generateRandomUserId() {
    final random = Random();
    final generatedId = (100000 + random.nextInt(900000)).toString();
    setState(() {
      userId = generatedId;
      _nicknameController.clear();
    });
  }

  void _startChat(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(name: nickname, id: userId),
        ),
      );
    }
  }

  String? _validateNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, entre com um nickname';
    }
    if (value.trim().length < 2) {
      return 'Nickname deve ter mais de 2 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Seu Chat:', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F1B24),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _generateRandomUserId,
            tooltip: 'Gerar novo ID',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Digite seu nickname',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.person_outline, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                  validator: _validateNickname,
                  onChanged: (value) {
                    setState(() {
                      nickname = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildStartChatButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartChatButton() {
    return ElevatedButton(
      onPressed: () => _startChat(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Iniciar Chat',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
