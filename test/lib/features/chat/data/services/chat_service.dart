import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/message_model.dart'; 

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<String> getOrCreateConversation(String otherUserId) async {
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    final conversationRef = await _firestore.collection('conversations').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  Future<void> sendMessage(String conversationId, String text) async {
    // Mesajı gönder
    await _firestore
        .collection('messages')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Conversation'ı güncelle
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    print('✅ Mesaj gönderildi: $conversationId');
    // NOT: Bildirim artık Cloud Functions tarafından otomatik gönderiliyor
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return MessageModel(
                id: doc.id,
                text: data['text'] ?? '',
                senderId: data['senderId'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isRead: data['isRead'] ?? false,
              );
            }).toList());
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    final messages = await _firestore
        .collection('messages')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Stream<List<Map<String, dynamic>>> getConversations() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}