import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String selectedUserID;
  final String selectedUserDisplayName;
  final String selectedUserBio;

  const ChatPage({
    Key? key,
    required this.selectedUserID,
    required this.selectedUserDisplayName,
    required this.selectedUserBio,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversation avec ${widget.selectedUserDisplayName}'),
            const SizedBox(height: 4),
            Text(
              widget.selectedUserBio.length > 100
                  ? '${widget.selectedUserBio.substring(0, 100)}...'
                  : widget.selectedUserBio,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Future.wait([
        FirebaseFirestore.instance
            .collection('messages')
            .where('from', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('to', isEqualTo: widget.selectedUserID)
            .get(),
        FirebaseFirestore.instance
            .collection('messages')
            .where('from', isEqualTo: widget.selectedUserID)
            .where('to', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .get(),
      ]).asStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }

        final List<QuerySnapshot?> querySnapshots = snapshot.data ?? [];
        final List<QueryDocumentSnapshot> messages = [];

        for (var querySnapshot in querySnapshots) {
          if (querySnapshot != null) {
            messages.addAll(querySnapshot.docs);
          }
        }

        // Tri des messages par timestamp
        messages.sort((a, b) {
          final timestampA = a['timestamp'] as Timestamp;
          final timestampB = b['timestamp'] as Timestamp;
          return timestampB.compareTo(timestampA);
        });

        if (messages.isEmpty) {
          return Center(
            child: Text('Aucun message. Démarrez la conversation !'),
          );
        }

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final messageContent = messageData['content'];
            final isCurrentUser = messageData['from'] == FirebaseAuth.instance.currentUser!.uid;
            final timestamp = (messageData['timestamp'] as Timestamp).toDate();

            return Container(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Color(0xFF5AFF96) : Color(0xFFE4E4E4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      messageContent ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${timestamp.day}/${timestamp.month}/${timestamp.year} '
                          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Envoyez un message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final String messageContent = _messageController.text.trim();
    final String currentUserID = FirebaseAuth.instance.currentUser!.uid;

    if (messageContent.isNotEmpty) {
      await FirebaseFirestore.instance.collection('messages').add({
        'from': currentUserID,
        'to': widget.selectedUserID,
        'timestamp': FieldValue.serverTimestamp(),
        'content': messageContent,
      });
      _messageController.clear();

      // Rechargement de la conversation après l'envoi du message
      setState(() {});
    }
  }
}
