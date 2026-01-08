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

    // Yeni conversation oluştur - unreadCount ile birlikte
    final conversationRef = await _firestore.collection('conversations').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'unreadCount': {
        currentUserId: 0,
        otherUserId: 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  Future<void> sendMessage(String conversationId, String text) async {
    // Önce conversation'ı al - alıcıyı bulmak için
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    
    final participants = List<String>.from(conversationDoc.data()?['participants'] ?? []);
    final receiverId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    
    // Mesajı conversations altına yaz (Cloud Functions'ın dinlediği path)
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Mevcut unreadCount'u al
    final currentUnreadCount = conversationDoc.data()?['unreadCount'] as Map<String, dynamic>? ?? {};
    final receiverUnread = (currentUnreadCount[receiverId] ?? 0) as int;

    // Conversation'ı güncelle - tüm gerekli alanlarla
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'unreadCount': {
        currentUserId: 0,  // Gönderen için 0
        receiverId: receiverUnread + 1,  // Alıcı için +1
      },
    });
    
    print('✅ Mesaj gönderildi: $conversationId');
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    // conversations altından mesajları oku (yeni path)
    return _firestore
        .collection('conversations')
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
    // Mesajları okundu olarak işaretle
    final messages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
    
    // unreadCount'u sıfırla
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$currentUserId': 0,
    });
  }

  Stream<List<Map<String, dynamic>>> getConversations() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }
}