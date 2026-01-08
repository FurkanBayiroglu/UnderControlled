import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart'; // BU SATIRI EKLE
import 'firebase_options.dart';
import 'features/auth/presentation/login/login_page.dart';
import 'features/social/presentation/pages/chat_detail_page.dart';
import 'features/social/presentation/pages/follow_requests_page.dart';
import 'screens/home_page.dart';
import 'core/services/notification_service.dart';

// Global navigator key - bildirimden navigasyon için
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Arka plan mesaj işleyici - TOP LEVEL olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Arka plan mesajı: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Türkçe locale başlat - BU SATIRI EKLE
  await initializeDateFormatting('tr', null);
  
  // Arka plan mesaj işleyicisini ayarla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnderControlled',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }
  
  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;
    
    // Bildirim izni iste
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('📱 Bildirim izni: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM Token al ve kaydet
      String? token = await messaging.getToken();
      if (token != null) {
        print('🔑 FCM Token alındı: ${token.substring(0, 20)}...');
        _saveFCMToken(token);
      }
      
      // Token yenilendiğinde
      messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token yenilendi');
        _saveFCMToken(newToken);
      });
      
      // Uygulama açıkken gelen mesajlar
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Ön plan mesajı: ${message.notification?.title}');
        _showInAppNotification(message);
      });
      
      // Bildirime tıklandığında (uygulama arka plandayken)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('👆 Bildirime tıklandı: ${message.data}');
        _handleNotificationTap(message);
      });
      
      // Uygulama kapalıyken bildirime tıklandığında
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 Uygulama bildirimden açıldı');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      }
    }
  }
  
  // FCM Token'ı Firestore'a kaydet
  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM Token kaydedildi');
      } catch (e) {
        print('❌ FCM Token kayıt hatası: $e');
      }
    }
  }
  
  // Uygulama açıkken bildirim göster
// Uygulama açıkken bildirim göster
void _showInAppNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;
  
  final context = navigatorKey.currentContext;
  if (context == null) return;
  
  final data = message.data;
  final type = data['type'] ?? '';
  final conversationId = data['conversationId'];
  
  // Eğer bu sohbetteysen bildirim gösterme
  if (type == 'message' && !_notificationService.shouldShowNotification(conversationId)) {
    print('🔕 Aktif sohbetten bildirim - gösterilmiyor');
    return;
  }
  
  // Önceki banner'ı kapat
  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  
  // Üstten MaterialBanner ile bildirim göster
  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      padding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: type == 'message' ? Colors.blue : Colors.purple,
        child: Icon(
          type == 'message' ? Icons.message : Icons.person_add,
          color: Colors.white,
          size: 20,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            notification.title ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            notification.body ?? '',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 4,
      actions: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          },
          child: const Text('Kapat'),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            _handleNotificationTap(message);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: type == 'message' ? Colors.blue : Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aç'),
        ),
      ],
    ),
  );
  
  // 4 saniye sonra otomatik kapat
  Future.delayed(const Duration(seconds: 4), () {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }
  });
}
  
  // Bildirime tıklandığında yönlendir
  void _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    
    print('🔀 Yönlendirme tipi: $type');
    print('🔀 Data: $data');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Kullanıcı giriş yapmamış');
      return;
    }
    
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      print('❌ Navigator bulunamadı');
      return;
    }
    
    if (type == 'message') {
      final conversationId = data['conversationId'];
      final senderId = data['senderId'];
      
      if (conversationId != null && senderId != null) {
        try {
          final senderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();
          
          final senderName = senderDoc.data()?['name'] ?? 'İsimsiz';
          
          navigator.push(
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                conversationId: conversationId,
                otherUserId: senderId,
                otherUserName: senderName,
              ),
            ),
          );
          print('✅ Sohbet sayfasına yönlendirildi');
        } catch (e) {
          print('❌ Yönlendirme hatası: $e');
        }
      }
    } else if (type == 'follow_request') {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => FollowRequestsPage(),
        ),
      );
      print('✅ Takip istekleri sayfasına yönlendirildi');
    } else if (type == 'follow_accepted') {
      print('ℹ️ Takip kabul bildirimi - ana sayfada kalındı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bağlanıyor...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // Kullanıcı giriş yaptığında FCM token'ı kaydet
          FirebaseMessaging.instance.getToken().then((token) {
            if (token != null) _saveFCMToken(token);
          });
          return const HomePage();
        }
        
        return const LoginPage();
      },
    );
  }
}