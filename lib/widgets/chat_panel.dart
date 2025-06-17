import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleconference_app/services/webrtc_service.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  
  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });
}

class ChatPanel extends StatefulWidget {
  const ChatPanel({Key? key}) : super(key: key);

  @override
  _ChatPanelState createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  void _listenForMessages() {
    // WebRTC servisinden gelen mesajları dinle
    // Bu fonksiyon, WebRTC servisi mesaj alma özelliği eklendiğinde güncellenecek
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final webRTCService = Provider.of<WebRTCService>(context, listen: false);
    
    // Mesajı gönder
    webRTCService.sendChatMessage(_messageController.text);
    
    // Yerel mesaj listesine ekle
    setState(() {
      _messages.add(ChatMessage(
        senderId: webRTCService.userId,
        senderName: '${webRTCService.userName} (Sen)',
        message: _messageController.text,
        timestamp: DateTime.now(),
      ));
    });
    
    // Metin alanını temizle
    _messageController.clear();
    
    // Otomatik olarak en alta kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 300 : 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık çubuğu
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sohbet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_messages.length} mesaj',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          
          // Mesaj listesi ve giriş alanı
          if (_isExpanded)
            Expanded(
              child: Column(
                children: [
                  // Mesaj listesi
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Henüz mesaj yok',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.senderId ==
                                  Provider.of<WebRTCService>(context, listen: false).userId;
                              
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Gönderen adı
                                      Text(
                                        message.senderName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      
                                      // Mesaj içeriği
                                      Text(message.message),
                                      
                                      // Zaman damgası
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          DateFormat('HH:mm').format(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Mesaj giriş alanı
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Mesajınızı yazın...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
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
    _scrollController.dispose();
    super.dispose();
  }
}