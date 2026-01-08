import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/room_model.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RoomCard({
    super.key,
    required this.room,
    this.isOwner = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Üst Kısım - Kategori ve Durum
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getCategoryColor(room.category).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: const Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(room.category),
                    color: _getCategoryColor(room.category),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(room.category),
                    style: TextStyle(
                      color: _getCategoryColor(room.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(),
                ],
              ),
            ),

            // İçerik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Oda Adı
                  Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Açıklama
                  Text(
                    room.description,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Tarih ve Katılımcı
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM, HH:mm', 'tr').format(room.eventDateTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${room.participants.length}/${room.maxParticipants}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (isOwner) ...[
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    if (room.isExpired) {
      color = Colors.grey;
      text = 'Sona Erdi';
    } else if (room.isOngoing) {
      color = Colors.green;
      text = 'Devam Ediyor';
    } else if (!room.isActive) {
      color = Colors.orange;
      text = 'Kapalı';
    } else {
      color = Colors.blue;
      text = 'Yaklaşıyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'sports': return Colors.green;
      case 'music': return Colors.purple;
      case 'gaming': return Colors.blue;
      case 'study': return Colors.orange;
      case 'chat': return Colors.teal;
      case 'movie': return Colors.red;
      case 'food': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'sports': return Icons.sports_soccer;
      case 'music': return Icons.music_note;
      case 'gaming': return Icons.gamepad;
      case 'study': return Icons.school;
      case 'chat': return Icons.chat;
      case 'movie': return Icons.movie;
      case 'food': return Icons.restaurant;
      default: return Icons.group;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'sports': return 'Spor';
      case 'music': return 'Müzik';
      case 'gaming': return 'Oyun';
      case 'study': return 'Çalışma';
      case 'chat': return 'Sohbet';
      case 'movie': return 'Film';
      case 'food': return 'Yemek';
      default: return 'Diğer';
    }
  }
}