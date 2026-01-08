import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import'lar
import '../features/social/presentation/pages/chat_list_page.dart';
import '../features/social/presentation/pages/user_search_page.dart';
import '../features/social/presentation/pages/follow_requests_page.dart';
import '../features/events/presentation/pages/room_list_page.dart';
import '../features/events/presentation/pages/ai_assistant_page.dart';
import '../features/rooms/presentation/pages/create_room_page.dart';
import '../features/rooms/presentation/pages/my_rooms_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomeTab(),
    const ChatListPage(),
    const ProfileTab(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// Ana Sayfa Tab
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'UnderControlled',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSearchPage(),
                ),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowRequestsPage(),
                    ),
                  );
                },
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  
                  final requests = (snapshot.data?.data() as Map<String, dynamic>?)?['followRequests'] as List?;
                  final requestCount = requests?.length ?? 0;
                  
                  if (requestCount == 0) return const SizedBox();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        requestCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(user),
              const SizedBox(height: 30),
              
              const Text(
                'Etkinlikler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Etkinlik Oluştur
              _buildActionCard(
                context: context,
                icon: Icons.add_circle_outline,
                iconColor: Colors.green,
                title: 'Etkinlik Oluştur',
                subtitle: 'Kendi etkinliğini başlat ve insanları davet et',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateRoomPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Etkinliğe Katıl
              _buildActionCard(
                context: context,
                icon: Icons.group_outlined,
                iconColor: Colors.blue,
                title: 'Etkinliğe Katıl',
                subtitle: 'Mevcut odalara göz at ve katıl',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoomListPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Odalarım
              _buildActionCard(
                context: context,
                icon: Icons.meeting_room_outlined,
                iconColor: Colors.orange,
                title: 'Odalarım',
                subtitle: 'Katıldığın ve oluşturduğun odaları gör',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyRoomsPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // AI Asistan
              _buildActionCard(
                context: context,
                icon: Icons.psychology_outlined,
                iconColor: Colors.purple,
                title: 'Ne İstediğimi Bilmiyorum',
                subtitle: 'AI asistanımız sana yardımcı olsun',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiAssistantPage()),
                  );
                },
                isSpecial: true,
              ),
              
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popüler Odalar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RoomListPage()),
                      );
                    },
                    child: const Text('Tümünü Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              _buildPopularRooms(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour >= 5 && hour < 12) {
      greeting = 'Günaydın';
      emoji = '☀️';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'İyi günler';
      emoji = '👋';
    } else if (hour >= 18 && hour < 22) {
      greeting = 'İyi akşamlar';
      emoji = '🌆';
    } else {
      greeting = 'İyi geceler';
      emoji = '🌙';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting! $emoji',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.displayName ?? user?.email?.split('@')[0] ?? 'Kullanıcı',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bugün ne yapmak istersin?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSpecial 
              ? Border.all(color: Colors.purple.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSpecial 
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRooms(BuildContext context) {
    final categories = {
      'sports': {'color': Colors.green, 'emoji': '⚽'},
      'fitness': {'color': Colors.orange, 'emoji': '💪'},
      'yoga': {'color': Colors.teal, 'emoji': '🧘'},
      'gaming': {'color': Colors.blue, 'emoji': '🎮'},
      'esports': {'color': Colors.red, 'emoji': '🏆'},
      'music': {'color': Colors.purple, 'emoji': '🎵'},
      'art': {'color': Colors.pink, 'emoji': '🎨'},
      'study': {'color': Colors.indigo, 'emoji': '📚'},
      'coding': {'color': Colors.green, 'emoji': '💻'},
      'chat': {'color': Colors.teal, 'emoji': '💬'},
      'movie': {'color': Colors.red, 'emoji': '🎬'},
      'food': {'color': Colors.amber, 'emoji': '🍕'},
      'travel': {'color': Colors.lightBlue, 'emoji': '✈️'},
      'tech': {'color': Colors.blueGrey, 'emoji': '🖥️'},
    };
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isActive', isEqualTo: true)
          .orderBy('participantCount', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Henüz aktif oda yok',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text('İlk odayı sen oluştur!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRoomPage()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Oda Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] as String? ?? 'chat';
            final catInfo = categories[category] ?? categories['chat']!;
            final participants = List.from(data['participants'] ?? []);
            final maxParticipants = data['maxParticipants'] ?? 20;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (catInfo['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(catInfo['emoji'] as String, style: const TextStyle(fontSize: 22))),
                ),
                title: Text(
                  data['name'] ?? 'İsimsiz Oda',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${participants.length}/$maxParticipants kişi', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Katıl', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RoomListPage()));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// Profil Tab
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(user?.displayName ?? 'İsimsiz Kullanıcı', style: Theme.of(context).textTheme.headlineSmall),
            Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final userData = snapshot.data?.data() ?? {};
                final followers = (userData['followers'] as List?)?.length ?? 0;
                final following = (userData['following'] as List?)?.length ?? 0;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatColumn('Takipçi', followers.toString()),
                    const SizedBox(width: 32),
                    _buildStatColumn('Takip', following.toString()),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('Odalarım'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyRoomsPage()));
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Takip İstekleri'),
              trailing: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  final requests = (snapshot.data?.data()?['followRequests'] as List?)?.length ?? 0;
                  
                  if (requests == 0) return const Icon(Icons.arrow_forward_ios, size: 16);
                  
                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(requests.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  );
                },
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FollowRequestsPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}