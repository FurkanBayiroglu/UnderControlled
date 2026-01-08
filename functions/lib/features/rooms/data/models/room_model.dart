import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String createdBy;
  final DateTime createdAt;
  final DateTime eventDate;
  final String eventTime; // "14:00" formatında
  final int durationMinutes; // Etkinlik süresi (dakika)
  final List<String> participants;
  final int maxParticipants;
  final bool isActive;
  final bool isPrivate;
  final String? imageUrl;

  RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.createdAt,
    required this.eventDate,
    required this.eventTime,
    this.durationMinutes = 120,
    required this.participants,
    this.maxParticipants = 20,
    this.isActive = true,
    this.isPrivate = false,
    this.imageUrl,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventTime: data['eventTime'] ?? '12:00',
      durationMinutes: data['durationMinutes'] ?? 120,
      participants: List<String>.from(data['participants'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 20,
      isActive: data['isActive'] ?? true,
      isPrivate: data['isPrivate'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'eventDate': Timestamp.fromDate(eventDate),
      'eventTime': eventTime,
      'durationMinutes': durationMinutes,
      'participants': participants,
      'participantCount': participants.length,
      'maxParticipants': maxParticipants,
      'isActive': isActive,
      'isPrivate': isPrivate,
      'imageUrl': imageUrl,
    };
  }

  // Etkinlik başlangıç zamanı
  DateTime get eventDateTime {
    final timeParts = eventTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 12;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      hour,
      minute,
    );
  }

  // Etkinlik bitiş zamanı
  DateTime get eventEndDateTime {
    return eventDateTime.add(Duration(minutes: durationMinutes));
  }

  // Etkinlik sona erdi mi?
  bool get isExpired {
    return DateTime.now().isAfter(eventEndDateTime);
  }

  // Etkinlik başladı mı?
  bool get hasStarted {
    return DateTime.now().isAfter(eventDateTime);
  }

  // Etkinlik devam ediyor mu?
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(eventDateTime) && now.isBefore(eventEndDateTime);
  }

  // Kalan süre
  Duration get timeUntilStart {
    return eventDateTime.difference(DateTime.now());
  }

  // Oda dolu mu?
  bool get isFull {
    return participants.length >= maxParticipants;
  }
}