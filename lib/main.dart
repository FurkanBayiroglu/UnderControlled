import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/login/login_page.dart';
import 'features/social/presentation/pages/chat_detail_page.dart';
import 'features/social/presentation/pages/follow_requests_page.dart';
import 'screens/home_page.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/premium/premium_service.dart';
import 'core/services/notification_service.dart';

// Global navigator key - bildirimden navigasyon için
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Arka plan mesaj işleyici - TOP LEVEL olmalı!
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Arka plan mesajı: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Arka plan mesaj işleyicisini ayarla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Firestore Cache Ayarları
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PremiumService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        SystemChrome.setSystemUIOverlayStyle(
          themeProvider.isDarkMode
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppTheme.darkSurface,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppTheme.lightSurface,
                ),
        );
        
        return MaterialApp(
          title: 'UnderControlled',
          navigatorKey: navigatorKey,  // Navigator key ekle
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
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

  // ============ FCM KURULUMU ============
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
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // FCM Token al
      String? token = await messaging.getToken();
      print('🔑 FCM Token: $token');
      
      if (token != null) {
        await _saveFCMToken(token);
      } else {
        print('❌ FCM Token alınamadı!');
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
            .set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ FCM Token kaydedildi: ${token.substring(0, 30)}...');
      } catch (e) {
        print('❌ FCM Token kayıt hatası: $e');
      }
    } else {
      print('⚠️ FCM Token kaydedilemedi - kullanıcı giriş yapmamış');
    }
  }

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
    
    _notificationService.showTopBanner(
      context: context,
      title: notification.title ?? '',
      body: notification.body ?? '',
      type: type,
      onTap: () => _handleNotificationTap(message),
      onMarkAsRead: () {
        print('✓ Okundu işaretlendi');
      },
    );
  }

  // Bildirime tıklandığında yönlendir
  void _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    
    print('🔀 Yönlendirme tipi: $type');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    
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
    }
  }

  // Kullanıcı verilerini kontrol et ve düzelt
  Future<void> _checkAndFixUserData(User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists || userDoc.data()?['name'] == null) {
        print('⚠️ Kullanıcı verisi eksik, düzeltiliyor...');
        
        String? phoneNumber = user.phoneNumber;
        
        if (phoneNumber != null) {
          final phoneDoc = await firestore
              .collection('phoneNumbers')
              .doc(phoneNumber)
              .get();
          
          if (phoneDoc.exists) {
            final originalUserId = phoneDoc.data()?['userId'] as String?;
            
            if (originalUserId != null && originalUserId != user.uid) {
              final originalUserDoc = await firestore
                  .collection('users')
                  .doc(originalUserId)
                  .get();
              
              if (originalUserDoc.exists) {
                final originalData = originalUserDoc.data()!;
                
                await firestore.collection('users').doc(user.uid).set({
                  ...originalData,
                  'uid': user.uid,
                  'isOnline': true,
                  'lastSeen': FieldValue.serverTimestamp(),
                  'migratedFrom': originalUserId,
                  'migratedAt': FieldValue.serverTimestamp(),
                });
                
                await firestore.collection('phoneNumbers').doc(phoneNumber).update({
                  'userId': user.uid,
                  'previousUserId': originalUserId,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                final username = originalData['username'] as String?;
                if (username != null) {
                  await firestore.collection('usernames').doc(username).update({
                    'userId': user.uid,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }
                
                print('✅ Kullanıcı verileri düzeltildi');
              }
            }
          }
        }
      }
      
      // FCM Token'ı kaydet (her giriş yaptığında)
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _saveFCMToken(fcmToken);
      }
      
    } catch (e) {
      print('❌ Kullanıcı verisi kontrol hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.background(context),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary.withOpacity(0.2),
                          AppTheme.secondary.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'app.name'.tr(context),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'app.loading'.tr(context),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          _checkAndFixUserData(snapshot.data!);
          return const HomePage();
        }
        
        return const LoginPage();
      },
    );
  }
}