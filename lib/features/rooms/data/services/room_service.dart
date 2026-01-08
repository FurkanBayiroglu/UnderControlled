import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Oda oluştur
  Future<String> createRoom({
    required String name,
    required String description,
    required String category,
    required DateTime eventDate,
    required String eventTime,
    int durationMinutes = 120,
    int maxParticipants = 20,
    bool isPrivate = false,
  }) async {
    final roomRef = await _firestore.collection('rooms').add({
      'name': name,
      'description': description,
      'category': category,
      'createdBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'eventDate': Timestamp.fromDate(eventDate),
      'eventTime': eventTime,
      'durationMinutes': durationMinutes,
      'participants': [currentUserId],
      'participantCount': 1,
      'maxParticipants': maxParticipants,
      'isActive': true,
      'isPrivate': isPrivate,
    });

    return roomRef.id;
  }

  // Odaya katıl
  Future<void> joinRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'participants': FieldValue.arrayUnion([currentUserId]),
      'participantCount': FieldValue.increment(1),
    });
  }

  // Odadan ayrıl
  Future<void> leaveRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'participants': FieldValue.arrayRemove([currentUserId]),
      'participantCount': FieldValue.increment(-1),
    });
  }

  // Odayı sil (sadece oluşturan)
  Future<void> deleteRoom(String roomId) async {
    // Önce oda mesajlarını sil
    final messages = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .get();
    
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    
    // Sonra odayı sil
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  // Odayı kapat
  Future<void> closeRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'isActive': false,
    });
  }

  // Benim odalarım (oluşturduğum)
  Stream<List<RoomModel>> getMyCreatedRooms() {
    return _firestore
        .collection('rooms')
        .where('createdBy', isEqualTo: currentUserId)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromFirestore(doc))
            .toList());
  }

  // Katıldığım odalar
  Stream<List<RoomModel>> getMyJoinedRooms() {
    return _firestore
        .collection('rooms')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromFirestore(doc))
            .toList());
  }

  // Tek oda getir
  Stream<RoomModel?> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? RoomModel.fromFirestore(doc) : null);
  }

  // Oda mesajı gönder
  Future<void> sendRoomMessage(String roomId, String text) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Oda mesajlarını getir
  Stream<QuerySnapshot> getRoomMessages(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Oda katılımcılarının bilgilerini getir
  Future<List<Map<String, dynamic>>> getRoomMembers(List<String> userIds) async {
    final members = <Map<String, dynamic>>[];
    
    for (String userId in userIds) {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        members.add({
          'id': doc.id,
          ...doc.data()!,
        });
      }
    }
    
    return members;
  }

  // Süresi geçmiş odaları kapat (Cloud Function'da yapılabilir)
  Future<void> closeExpiredRooms() async {
    final now = DateTime.now();
    final rooms = await _firestore
        .collection('rooms')
        .where('isActive', isEqualTo: true)
        .get();

    for (var doc in rooms.docs) {
      final room = RoomModel.fromFirestore(doc);
      if (room.isExpired) {
        await closeRoom(doc.id);
      }
    }
  }
}