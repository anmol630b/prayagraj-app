import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Har 5 second mein auto refresh
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    try {
      final msgs = await ApiService.getChatMessages();
      if (mounted) {
        setState(() { _messages = msgs; _isLoading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _controller.clear();
    await ApiService.sendChatMessage(text);
    _loadMessages();
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: Row(children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Icon(Icons.support_agent, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support Team', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('Online', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ]),
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _messages.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Koi message nahi!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Support se baat karo',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ]))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isAdmin = msg['is_admin'] == true;
                        return Align(
                          alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.white : Colors.green.shade700,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isAdmin ? 0 : 16),
                                bottomRight: Radius.circular(isAdmin ? 16 : 0),
                              ),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              )],
                            ),
                            child: Column(
                              crossAxisAlignment: isAdmin
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              children: [
                                if (isAdmin)
                                  Text('Support',
                                      style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                Text(msg['message'],
                                    style: TextStyle(
                                        color: isAdmin ? Colors.black87 : Colors.white,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(msg['created_at'],
                                    style: TextStyle(
                                        color: isAdmin
                                            ? Colors.grey.shade400
                                            : Colors.white70,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Message likho...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
