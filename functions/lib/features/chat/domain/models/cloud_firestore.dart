import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : FieldValue.serverTimestamp(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
    };
  }
}