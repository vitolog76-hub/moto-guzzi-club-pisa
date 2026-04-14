import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/event_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final EventChatService _chatService = EventChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  DateTime? _lastMarkedReadAt;

  static const Color guzziRed = Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    _markAsReadIfLoggedIn();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsReadIfLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _chatService.markEventChatAsRead(widget.eventId, user.uid);
  }

  void _maybeMarkAsRead(Timestamp? timestamp) {
    if (timestamp == null) return;
    final messageTime = timestamp.toDate();
    if (_lastMarkedReadAt != null && !messageTime.isAfter(_lastMarkedReadAt!)) {
      return;
    }
    _lastMarkedReadAt = messageTime;
    _markAsReadIfLoggedIn();
  }

  Future<Map<String, String>> _loadCurrentUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'userName': (data['nome'] ?? 'Utente').toString(),
          'userModello': (data['modelloMoto'] ?? '').toString(),
        };
      }
    } catch (_) {}

    return {'userName': 'Utente', 'userModello': ''};
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final userData = await _loadCurrentUserData(user.uid);
      await _chatService.sendMessage(
        eventId: widget.eventId,
        userId: user.uid,
        userName: userData['userName'] ?? 'Utente',
        userModello: userData['userModello'] ?? '',
        text: text,
      );
      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is! Timestamp) return '--:--';
    final date = timestamp.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat - ${widget.eventTitle}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (!isLoggedIn)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Effettua il login per leggere e scrivere in chat.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: !isLoggedIn
                ? const Center(
                    child: Text(
                      'Accesso richiesto',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chatService.streamMessages(widget.eventId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: guzziRed),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Errore chat: ${snapshot.error}'),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nessun messaggio. Inizia la conversazione!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final latestTimestamp = docs.first.data()['timestamp'];
                      _maybeMarkAsRead(
                        latestTimestamp is Timestamp ? latestTimestamp : null,
                      );

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final messageUserId = (data['userId'] ?? '')
                              .toString();
                          final isMine = messageUserId == user.uid;
                          final userName = (data['userName'] ?? 'Utente')
                              .toString();
                          final userModello = (data['userModello'] ?? '')
                              .toString();
                          final text = (data['text'] ?? '').toString();
                          final time = _formatTime(data['timestamp']);

                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? guzziRed.withOpacity(0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMine
                                      ? guzziRed.withOpacity(0.35)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userModello.isNotEmpty
                                        ? '$userName ($userModello)'
                                        : userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMine
                                          ? guzziRed
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(text),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: isLoggedIn && !_isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: isLoggedIn
                          ? 'Scrivi un messaggio...'
                          : 'Login richiesto',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isLoggedIn ? guzziRed : Colors.grey,
                  child: IconButton(
                    onPressed: isLoggedIn && !_isSending ? _sendMessage : null,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
