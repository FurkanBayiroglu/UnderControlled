import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String username;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<String> followers;
  final List<String> following;
  final List<String> followRequests;
  final List<String> sentRequests;
  final bool isPrivate;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.username,
    this.photoUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.followers = const [],
    this.following = const [],
    this.followRequests = const [],
    this.sentRequests = const [],
    this.isPrivate = false,
    this.settings,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] ?? false,
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followRequests: List<String>.from(data['followRequests'] ?? []),
      sentRequests: List<String>.from(data['sentRequests'] ?? []),
      isPrivate: data['isPrivate'] ?? false,
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isVerified': isVerified,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'followers': followers,
      'following': following,
      'followRequests': followRequests,
      'sentRequests': sentRequests,
      'isPrivate': isPrivate,
      'settings': settings,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? username,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    List<String>? followers,
    List<String>? following,
    List<String>? followRequests,
    List<String>? sentRequests,
    bool? isPrivate,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      followRequests: followRequests ?? this.followRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      isPrivate: isPrivate ?? this.isPrivate,
      settings: settings ?? this.settings,
    );
  }

  String get displayName => name.isNotEmpty ? name : '@$username';

  String get profilePhotoUrl => photoUrl ?? _generateDefaultAvatar();

  String _generateDefaultAvatar() {
    final initials = name
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
    
    return 'https://ui-avatars.com/api/?name=$initials&background=random';
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}