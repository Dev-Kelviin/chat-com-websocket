import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_client/web_socket_client.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.name, required this.id}) : super(key: key);

  final String name;
  final String id;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final socket = WebSocket(Uri.parse('ws://localhost:8765'));
  final List<types.Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  late types.User otherUser;
  late types.User me;

  @override
  void initState() {
    super.initState();

    me = types.User(
      id: widget.id,
      firstName: widget.name,
    );

    socket.messages.listen((incomingMessage) {
      List<String> parts = incomingMessage.split(' from ');
      String jsonString = parts[0];
      Map<String, dynamic> data = jsonDecode(jsonString);
      String id = data['id'];
      String msg = data['msg'];
      String nick = data['nick'] ?? id;
      bool isImage = data['isImage'] ?? false;

      if (id != me.id) {
        otherUser = types.User(
          id: id,
          firstName: nick,
        );
        onMessageReceived(msg, isImage);
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  String randomString() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }

  String _saveImage(Uint8List imageBytes) {
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    return url;
  }

  void onMessageReceived(String message, bool isImage) async {
    types.Message newMessage;

    if (isImage) {
      Uint8List imageBytes = base64Decode(message);
      String filePath = _saveImage(imageBytes);

      newMessage = types.ImageMessage(
        author: otherUser,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'received_image.jpg',
        size: imageBytes.length,
        uri: filePath,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        metadata: {'isImage': true},
      );
    } else {
      newMessage = types.TextMessage(
        author: otherUser,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        metadata: {'isImage': false},
      );
    }

    _addMessage(newMessage);
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _sendMessageCommon(String text, {bool isImage = false}) async {
    types.Message textMessage;

    if (isImage) {
      Uint8List imageBytes = base64Decode(text);
      String filePath = _saveImage(imageBytes);

      textMessage = types.ImageMessage(
        author: me,
        id: randomString(),
        name: 'sent_image.jpg',
        size: imageBytes.length,
        uri: filePath,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        metadata: {'isImage': true},
      );
    } else {
      textMessage = types.TextMessage(
        author: me,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        text: text,
        metadata: {'isImage': false},
      );
    }

    var payload = {
      'id': me.id,
      'msg': text,
      'nick': me.firstName,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'isImage': isImage,
    };

    socket.send(json.encode(payload));
    _addMessage(textMessage);
  }

  void _handleSendPressed(types.PartialText message) {
    _sendMessageCommon(message.text);
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      _sendMessageCommon(base64Image, isImage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // exemplo tema escuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 5),
            const CircleAvatar(
              backgroundImage: AssetImage('assets/avatar_placeholder.png'),
              radius: 18,
            ),
            const SizedBox(width: 10),
            Text(widget.name, style: const TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.video_call, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Chat(
              messages: _messages,
              user: me,
              showUserAvatars: true,
              showUserNames: false,
              onSendPressed: _handleSendPressed,
              theme: const DefaultChatTheme(
                inputBackgroundColor: Color(0xFF1F1F1F),
                inputTextColor: Colors.white,
                primaryColor: Color(0xFF4A90E2),
                secondaryColor: Color(0xFF2E2E2E),
                backgroundColor: Color(0xFF121212),
                inputBorderRadius: BorderRadius.all(Radius.circular(25)),
                inputMargin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                inputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sendButtonIcon: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF1F1F1F),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem', // placeholder correto
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (text) {
                      if (text.trim().isEmpty) return;
                      _sendMessageCommon(text);
                      _messageController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if (_messageController.text.trim().isEmpty) return;
                    _sendMessageCommon(_messageController.text);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    socket.close();
    super.dispose();
  }
}
