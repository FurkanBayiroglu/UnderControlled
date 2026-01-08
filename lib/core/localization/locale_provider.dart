import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  String _currentLanguage = 'tr';
  
  String get currentLanguage => _currentLanguage;
  bool get isTurkish => _currentLanguage == 'tr';
  bool get isEnglish => _currentLanguage == 'en';
  String get flag => _currentLanguage == 'tr' ? '🇹🇷' : '🇺🇸';
  String get languageName => _currentLanguage == 'tr' ? 'Türkçe' : 'English';
  
  LocaleProvider() { _loadLocale(); }
  
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_localeKey) ?? 'tr';
      notifyListeners();
    } catch (e) { _currentLanguage = 'tr'; }
  }
  
  Future<void> setLanguage(String lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, lang);
    } catch (e) {}
  }
  
  Future<void> toggleLanguage() async => await setLanguage(_currentLanguage == 'tr' ? 'en' : 'tr');
  
  String t(String key) => (_currentLanguage == 'tr' ? _tr : _en)[key] ?? key;
  
  String get(String key) => (_currentLanguage == 'tr' ? _tr : _en)[key] ?? key;

  static const Map<String, String> _tr = {
    // App
    'app.name': 'UnderControlled',
    'app.loading': 'Yükleniyor...',
    
    // Navigation
    'home': 'Ana Sayfa',
    'groups': 'Gruplar',
    'messages': 'Mesajlar',
    'profile': 'Profil',
    
    // Home
    'hello': 'Merhaba',
    'user': 'Kullanıcı',
    'whatToDo': 'Bugün ne yapmak istersin?',
    'createGroup': 'Grup Oluştur',
    'startNewEvent': 'Yeni bir etkinlik başlat ve insanları davet et',
    'joinGroups': 'Gruplara Katıl',
    'discoverGroups': 'Mevcut grupları keşfet ve katıl',
    'aiAssistant': 'AI Asistan',
    'aiAssistantDesc': 'Ne yapacağını bilmiyor musun? Sana özel öneriler al!',
    'new': 'YENİ',
    'quickAccess': 'Hızlı Erişim',
    'myRooms': 'Odalarım',
    'friends': 'Arkadaşlar',
    'popularRooms': 'Popüler Odalar 🔥',
    'all': 'Tümü',
    'noRoomsYet': 'Henüz aktif oda yok',
    'people': 'kişi',
    
    // Groups / Rooms
    'explore': 'Keşfet',
    'joined': 'Katıldıklarım',
    'createdRooms': 'Oluşturduklarım',
    'noCreatedRooms': 'Henüz oda oluşturmadın',
    'create': 'Oluştur',
    'createRoom': 'Oda Oluştur',
    'noRoomsInCategory': 'Bu kategoride oda bulunamadı',
    'noJoinedGroups': 'Henüz bir gruba katılmadın',
    'exploreGroups': 'Grupları Keşfet',
    'roomFull': 'Oda dolu!',
    'joinedGroup': 'Gruba katıldın!',
    'leftGroup': 'Gruptan ayrıldın',
    'enter': 'Gir',
    'join': 'Katıl',
    'leave': 'Ayrıl',
    'full': 'Dolu',
    'noMessages': 'Henüz mesaj yok',
    'sendMessage': 'Mesaj yaz...',
    'participants': 'Katılımcılar',
    
    // Profile
    'followers': 'Takipçi',
    'following': 'Takip',
    'editProfile': 'Profili Düzenle',
    'settings': 'Ayarlar',
    'privacy': 'Gizlilik',
    'logout': 'Çıkış Yap',
    'name': 'İsim',
    'save': 'Kaydet',
    'profileUpdated': 'Profil güncellendi!',
    
    // Follow
    'followRequests': 'Takip İstekleri',
    'noFollowRequests': 'Takip isteği yok',
    'accept': 'Kabul Et',
    'reject': 'Reddet',
    'follow': 'Takip Et',
    'unfollow': 'Takibi Bırak',
    'requestSent': 'İstek Gönderildi',
    'message': 'Mesaj',
    'requestAccepted': 'İstek kabul edildi',
    'requestRejected': 'İstek reddedildi',
    
    // Notifications
    'notifications': 'Bildirimler',
    'noNotifications': 'Bildirim yok',
    'markAllRead': 'Tümünü Okundu İşaretle',
    'allMarkedRead': 'Tüm bildirimler okundu',
    'recentActivity': 'Son Aktiviteler',
    'noUnreadMessages': 'Okunmamış mesaj yok',
    
    // Search
    'searchUsers': 'Kullanıcı Ara',
    'searchHint': 'Kullanıcı adı veya isim ara...',
    'minChars': 'En az 2 karakter yazın',
    'noResults': 'Sonuç bulunamadı',
    
    // Language
    'selectLanguage': 'Dil Seçin',
    
    // Room Create/Edit
    'roomName': 'Oda Adı',
    'description': 'Açıklama',
    'category': 'Kategori',
    'maxParticipants': 'Maks. Katılımcı',
    'privateRoom': 'Gizli Oda',
    'eventDate': 'Etkinlik Tarihi',
    'eventTime': 'Etkinlik Saati',
    'duration': 'Süre',
    'minutes': 'dakika',
    'hours': 'saat',
    'unlimited': 'Sınırsız',
    'roomCreated': 'Oda oluşturuldu!',
    'expired': 'Bitti',
    'deleteRoom': 'Odayı Sil',
    'deleteConfirm': 'Bu odayı silmek istediğinize emin misiniz?',
    'delete': 'Sil',
    'cancel': 'İptal',
    'edit': 'Düzenle',
    'roomDeleted': 'Oda silindi',
    
    // Chat
    'conversations': 'Sohbetler',
    'contacts': 'Kişiler',
    'noConversations': 'Henüz sohbet yok',
    'startChat': 'Sohbet başlat',
    'noContacts': 'Henüz kimseyi takip etmiyorsun',
    'groupChats': 'Grup Sohbetleri',
    'noGroupChats': 'Henüz grup sohbeti yok',
    'chat': 'Sohbet',
    
    // Followers Page
    'followersTab': 'Takipçiler',
    'followingTab': 'Takip Edilenler',
    'noFollowersYet': 'Henüz takipçi yok',
    'noFollowingYet': 'Henüz kimse takip edilmiyor',
    'nobodyFollowsYet': 'Bu kullanıcıyı henüz kimse takip etmiyor',
    'notFollowingAnyone': 'Bu kullanıcı henüz kimseyi takip etmiyor',
    'you': 'Sen',
    'inFollowing': 'Takipte',
    'requested': 'İstendi',
    'unfollowTitle': 'Takipten Çık',
    'unfollowConfirm': 'Bu kişiyi takipten çıkmak istediğine emin misin?',
    'unfollowed': 'Takipten çıkıldı',
    'requestCancelled': 'İstek iptal edildi',
    'followRequestSent': 'Takip isteği gönderildi!',
    'couldNotStartChat': 'Mesaj başlatılamadı',
    
    // Room List Page
    'allCategories': 'Tümü',
    'catSports': 'Spor',
    'catGaming': 'Oyun',
    'catMusic': 'Müzik',
    'catStudy': 'Ders',
    'catChat': 'Sohbet',
    'catMovie': 'Film',
    'catFood': 'Yemek',
    'catTech': 'Teknoloji',
    'catTravel': 'Seyahat',
    'noRoomsToJoin': 'Henüz katılabileceğin oda yok',
    'roomsCouldNotLoad': 'Odalar yüklenemedi',
    'tryAgain': 'Tekrar Dene',
    'leaveRoom': 'Odadan Ayrıl',
    'leaveRoomConfirm': 'Bu odadan ayrılmak istediğine emin misin?',
    
    // Room Detail Page
    'roomNotFound': 'Oda bulunamadı',
    'room': 'Oda',
    'closeRoom': 'Odayı Kapat',
    'date': 'Tarih',
    'time': 'Saat',
    'durationLabel': 'Süre',
    'ongoing': 'Devam',
    'closed': 'Kapalı',
    'soon': 'Yakında',
    'ended': 'Bitti',
    'daysShort': 'g',
    'hoursShort': 's',
    'joinRoom': 'Odaya Katıl',
    'founder': 'Kurucu',
    'sendFirstMessage': 'İlk mesajı gönder!',
    'joinToSendMessage': 'Mesaj göndermek için odaya katılın',
    'chatLocked': 'Sohbet Kilitli',
    'joinToSeeMessages': 'Mesajları görmek ve sohbete katılmak için odaya katılın',
    'roomNotActive': 'Bu oda artık aktif değil',
    'anonymous': 'Anonim',
    
    // Common
    'loading': 'Yükleniyor...',
    'userNotFound': 'Kullanıcı bulunamadı',
    'error': 'Hata',
    'confirm': 'Onayla',
    
    // Premium
    'premium': 'Premium',
    'premiumTitle': 'Premium Üyelik',
    'premiumSubtitle': 'Tüm özelliklerin kilidini aç',
    'premiumFeatures': 'Premium Özellikler',
    'choosePlan': 'Plan Seçin',
    'getPremium': 'Premium\'a Geç',
    'extendPremium': 'Süreyi Uzat',
    'youArePremium': 'Premium Üyesin!',
    'daysRemaining': 'gün kaldı',
    'active': 'Aktif',
    'popular': 'En Popüler',
    'saveDiscount': 'Tasarruf',
    'month': 'ay',
    'confirmPurchase': 'Satın Alma Onayı',
    'purchaseSuccess': 'Premium aktivasyonu başarılı! 🎉',
    'purchaseError': 'Satın alma sırasında hata oluştu',
    'premiumNote': 'Abonelik otomatik yenilenir. İstediğiniz zaman iptal edebilirsiniz.',
    'featureProfilePhoto': 'Profil fotoğrafı yükleyebilme',
    'featureUnlimitedRooms': 'Sınırsız oda oluşturma',
    'featureMoreParticipants': '100 kişiye kadar katılımcı',
    'featureMessageDelete': '24 saat mesaj silme süresi',
    'featurePremiumBadge': 'Premium rozeti',
    'featureHideRead': 'Okundu bilgisini gizleme',
    'featureProfileVisitors': 'Profil ziyaretçilerini görme',
    'featurePrioritySupport': 'Öncelikli destek',
    'roomLimitReached': 'Oda limitine ulaştın',
    'roomLimitMessage': 'Ücretsiz üyelikte en fazla 3 oda oluşturabilirsin. Premium ile sınırsız oda oluştur!',
    'goPremium': 'Premium\'a Geç',
    'premiumRequired': 'Premium Gerekli',
    'profilePhotoRequiresPremium': 'Profil fotoğrafı yüklemek için Premium üyelik gereklidir.',
    'changePhoto': 'Fotoğrafı Değiştir',
    'removePhoto': 'Fotoğrafı Kaldır',
    'photoUpdated': 'Profil fotoğrafı güncellendi!',
    'photoRemoved': 'Profil fotoğrafı kaldırıldı',
    
    // Auth / Register
    'login': 'Giriş Yap',
    'register': 'Kayıt Ol',
    'username': 'Kullanıcı Adı',
    'email': 'E-posta',
    'phone': 'Telefon Numarası',
    'password': 'Şifre',
    'confirmPassword': 'Şifre Tekrar',
    'sendSmsCode': 'SMS Kodu Gönder',
    'verify': 'Doğrula',
    'verifyAndRegister': 'Doğrula ve Kayıt Ol',
    'enterSmsCode': 'SMS Kodunu Girin',
    'codeSentTo': 'numarasına gönderilen 6 haneli kodu girin',
    'codeNotReceived': 'Kod gelmedi mi?',
    'resend': 'Tekrar Gönder',
    'waitSeconds': 'saniye bekleyin',
    'changeInfo': 'Bilgileri Düzenle',
    'alreadyHaveAccount': 'Hesabın var mı?',
    'dontHaveAccount': 'Hesabın yok mu?',
    'registerSuccess': 'Kayıt başarılı! 🎉',
    'loggingIn': 'Giriş yapılıyor...',
    'phoneLogin': 'Telefon ile Giriş',
    'enterPhone': 'Kayıtlı telefon numaranızı girin',
    'changeNumber': 'Numarayı Değiştir',
    
    // Validation messages
    'nameRequired': 'İsim gerekli',
    'nameTooShort': 'İsim çok kısa',
    'nameTooLong': 'İsim çok uzun',
    'nameOnlyLetters': 'İsim sadece harf içerebilir',
    'usernameRequired': 'Kullanıcı adı gerekli',
    'usernameMinChars': 'En az 3 karakter olmalı',
    'usernameMaxChars': 'En fazla 20 karakter olabilir',
    'usernameHelper': '3-20 karakter, benzersiz olmalı',
    'emailRequired': 'E-posta gerekli',
    'emailInvalid': 'Geçerli bir e-posta adresi girin',
    'emailHelper': 'Giriş yapmak için kullanacağınız e-posta',
    'phoneRequired': 'Telefon numarası gerekli',
    'phoneStartWith5': 'Telefon numarası 5 ile başlamalı',
    'phoneMustBe10': 'Telefon numarası 10 haneli olmalı',
    'phoneHelper': 'SMS doğrulaması için kullanılacak',
    'passwordRequired': 'Şifre gerekli',
    'passwordMinChars': 'Şifre en az 6 karakter olmalı',
    'passwordHelper': 'En az 6 karakter',
    'confirmPasswordRequired': 'Şifre tekrarı gerekli',
    'passwordsNotMatch': 'Şifreler eşleşmiyor',
    'chooseValidUsername': 'Lütfen geçerli bir kullanıcı adı seçin',
    
    // Password strength
    'weak': 'Zayıf',
    'medium': 'Orta',
    'good': 'İyi',
    'strong': 'Güçlü',
    'strongPassword': 'Güçlü şifre! ✓',
    'addForStronger': 'Daha güçlü için ekleyin:',
    'chars8plus': '8+ karakter',
    'uppercase': 'büyük harf',
    'number': 'rakam',
    'specialChar': 'özel karakter',
    // _tr Map'ine ekle:

    // Follow Requests Page - New Keys
    'newRequestsWillAppearHere': 'Yeni takip istekleri burada görünecek',
    'wantsToFollowYou': 'Seni takip etmek istiyor',
    'nowFollowsYou': 'Artık seni takip ediyor',
    'followBack': 'Geri Takip Et',
    'cancelRequest': 'İsteği İptal Et',
    
    // Greetings
    'goodMorning': 'Günaydın',
    'goodAfternoon': 'İyi günler',
    'goodEvening': 'İyi akşamlar',
    'goodNight': 'İyi geceler',
  };
  
  static const Map<String, String> _en = {
    // App
    'app.name': 'UnderControlled',
    'app.loading': 'Loading...',
    
    // Navigation
    'home': 'Home',
    'groups': 'Groups',
    'messages': 'Messages',
    'profile': 'Profile',
    
    // Home
    'hello': 'Hello',
    'user': 'User',
    'whatToDo': 'What do you want to do today?',
    'createGroup': 'Create Group',
    'startNewEvent': 'Start a new event and invite people',
    'joinGroups': 'Join Groups',
    'discoverGroups': 'Discover existing groups and join',
    'aiAssistant': 'AI Assistant',
    'aiAssistantDesc': "Don't know what to do? Get personalized suggestions!",
    'new': 'NEW',
    'quickAccess': 'Quick Access',
    'myRooms': 'My Rooms',
    'friends': 'Friends',
    'popularRooms': 'Popular Rooms 🔥',
    'all': 'All',
    'noRoomsYet': 'No active rooms yet',
    'people': 'people',
    
    // Groups / Rooms
    'explore': 'Explore',
    'joined': 'Joined',
    'createdRooms': 'Created',
    'noCreatedRooms': "You haven't created any rooms yet",
    'create': 'Create',
    'createRoom': 'Create Room',
    'noRoomsInCategory': 'No rooms found in this category',
    'noJoinedGroups': "You haven't joined any groups yet",
    'exploreGroups': 'Explore Groups',
    'roomFull': 'Room is full!',
    'joinedGroup': 'Joined the group!',
    'leftGroup': 'Left the group',
    'enter': 'Enter',
    'join': 'Join',
    'leave': 'Leave',
    'full': 'Full',
    'noMessages': 'No messages yet',
    'sendMessage': 'Write a message...',
    'participants': 'Participants',
    
    // Profile
    'followers': 'Followers',
    'following': 'Following',
    'editProfile': 'Edit Profile',
    'settings': 'Settings',
    'privacy': 'Privacy',
    'logout': 'Logout',
    'name': 'Name',
    'save': 'Save',
    'profileUpdated': 'Profile updated!',
    
    // Follow
    'followRequests': 'Follow Requests',
    'noFollowRequests': 'No follow requests',
    'accept': 'Accept',
    'reject': 'Reject',
    'follow': 'Follow',
    'unfollow': 'Unfollow',
    'requestSent': 'Request Sent',
    'message': 'Message',
    'requestAccepted': 'Request accepted',
    'requestRejected': 'Request rejected',
    
    // Notifications
    'notifications': 'Notifications',
    'noNotifications': 'No notifications',
    'markAllRead': 'Mark All as Read',
    'allMarkedRead': 'All notifications marked as read',
    'recentActivity': 'Recent Activity',
    'noUnreadMessages': 'No unread messages',
    
    // Search
    'searchUsers': 'Search Users',
    'searchHint': 'Search by username or name...',
    'minChars': 'Type at least 2 characters',
    'noResults': 'No results found',
    
    // Language
    'selectLanguage': 'Select Language',
    
    // Room Create/Edit
    'roomName': 'Room Name',
    'description': 'Description',
    'category': 'Category',
    'maxParticipants': 'Max Participants',
    'privateRoom': 'Private Room',
    'eventDate': 'Event Date',
    'eventTime': 'Event Time',
    'duration': 'Duration',
    'minutes': 'minutes',
    'hours': 'hours',
    'unlimited': 'Unlimited',
    'roomCreated': 'Room created!',
    'expired': 'Expired',
    'deleteRoom': 'Delete Room',
    'deleteConfirm': 'Are you sure you want to delete this room?',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'roomDeleted': 'Room deleted',
    
    // Chat
    'conversations': 'Conversations',
    'contacts': 'Contacts',
    'noConversations': 'No conversations yet',
    'startChat': 'Start chat',
    'noContacts': "You're not following anyone yet",
    'groupChats': 'Group Chats',
    'noGroupChats': 'No group chats yet',
    'chat': 'Chat',
    
    // Followers Page
    'followersTab': 'Followers',
    'followingTab': 'Following',
    'noFollowersYet': 'No followers yet',
    'noFollowingYet': 'Not following anyone yet',
    'nobodyFollowsYet': 'Nobody follows this user yet',
    'notFollowingAnyone': 'This user is not following anyone yet',
    'you': 'You',
    'inFollowing': 'Following',
    'requested': 'Requested',
    'unfollowTitle': 'Unfollow',
    'unfollowConfirm': 'Are you sure you want to unfollow this person?',
    'unfollowed': 'Unfollowed',
    'requestCancelled': 'Request cancelled',
    'followRequestSent': 'Follow request sent!',
    'couldNotStartChat': 'Could not start chat',
    
    // Room List Page
    'allCategories': 'All',
    'catSports': 'Sports',
    'catGaming': 'Gaming',
    'catMusic': 'Music',
    'catStudy': 'Study',
    'catChat': 'Chat',
    'catMovie': 'Movie',
    'catFood': 'Food',
    'catTech': 'Tech',
    'catTravel': 'Travel',
    'noRoomsToJoin': 'No rooms to join yet',
    'roomsCouldNotLoad': 'Could not load rooms',
    'tryAgain': 'Try Again',
    'leaveRoom': 'Leave Room',
    'leaveRoomConfirm': 'Are you sure you want to leave this room?',
    
    // Room Detail Page
    'roomNotFound': 'Room not found',
    'room': 'Room',
    'closeRoom': 'Close Room',
    'date': 'Date',
    'time': 'Time',
    'durationLabel': 'Duration',
    'ongoing': 'Ongoing',
    'closed': 'Closed',
    'soon': 'Soon',
    'ended': 'Ended',
    'daysShort': 'd',
    'hoursShort': 'h',
    'joinRoom': 'Join Room',
    'founder': 'Founder',
    'sendFirstMessage': 'Send the first message!',
    'joinToSendMessage': 'Join the room to send messages',
    'chatLocked': 'Chat Locked',
    'joinToSeeMessages': 'Join the room to see messages and participate in the chat',
    'roomNotActive': 'This room is no longer active',
    'anonymous': 'Anonymous',
    
    // Common
    'loading': 'Loading...',
    'userNotFound': 'User not found',
    'error': 'Error',
    'confirm': 'Confirm',
    
    // Premium
    'premium': 'Premium',
    'premiumTitle': 'Premium Membership',
    'premiumSubtitle': 'Unlock all features',
    'premiumFeatures': 'Premium Features',
    'choosePlan': 'Choose a Plan',
    'getPremium': 'Get Premium',
    'extendPremium': 'Extend Subscription',
    'youArePremium': 'You\'re Premium!',
    'daysRemaining': 'days remaining',
    'active': 'Active',
    'popular': 'Most Popular',
    'saveDiscount': 'Save',
    'month': 'month',
    'confirmPurchase': 'Confirm Purchase',
    'purchaseSuccess': 'Premium activated successfully! 🎉',
    'purchaseError': 'Error during purchase',
    'premiumNote': 'Subscription auto-renews. You can cancel anytime.',
    'featureProfilePhoto': 'Upload profile photo',
    'featureUnlimitedRooms': 'Unlimited room creation',
    'featureMoreParticipants': 'Up to 100 participants',
    'featureMessageDelete': '24 hour message delete window',
    'featurePremiumBadge': 'Premium badge',
    'featureHideRead': 'Hide read receipts',
    'featureProfileVisitors': 'See profile visitors',
    'featurePrioritySupport': 'Priority support',
    'roomLimitReached': 'Room limit reached',
    'roomLimitMessage': 'Free accounts can create up to 3 rooms. Go Premium for unlimited rooms!',
    'goPremium': 'Go Premium',
    'premiumRequired': 'Premium Required',
    'profilePhotoRequiresPremium': 'Uploading profile photo requires Premium membership.',
    'changePhoto': 'Change Photo',
    'removePhoto': 'Remove Photo',
    'photoUpdated': 'Profile photo updated!',
    'photoRemoved': 'Profile photo removed',
    
    // Auth / Register
    'login': 'Login',
    'register': 'Register',
    'username': 'Username',
    'email': 'Email',
    'phone': 'Phone Number',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'sendSmsCode': 'Send SMS Code',
    'verify': 'Verify',
    'verifyAndRegister': 'Verify and Register',
    'enterSmsCode': 'Enter SMS Code',
    'codeSentTo': 'Enter the 6-digit code sent to',
    'codeNotReceived': 'Code not received?',
    'resend': 'Resend',
    'waitSeconds': 'seconds wait',
    'changeInfo': 'Edit Info',
    'alreadyHaveAccount': 'Already have an account?',
    'dontHaveAccount': "Don't have an account?",
    'registerSuccess': 'Registration successful! 🎉',
    'loggingIn': 'Logging in...',
    'phoneLogin': 'Phone Login',
    'enterPhone': 'Enter your registered phone number',
    'changeNumber': 'Change Number',
    
    // Validation messages
    'nameRequired': 'Name is required',
    'nameTooShort': 'Name is too short',
    'nameTooLong': 'Name is too long',
    'nameOnlyLetters': 'Name can only contain letters',
    'usernameRequired': 'Username is required',
    'usernameMinChars': 'At least 3 characters',
    'usernameMaxChars': 'Maximum 20 characters',
    'usernameHelper': '3-20 characters, must be unique',
    'emailRequired': 'Email is required',
    'emailInvalid': 'Enter a valid email address',
    'emailHelper': 'Email you will use to login',
    'phoneRequired': 'Phone number is required',
    'phoneStartWith5': 'Phone number must start with 5',
    'phoneMustBe10': 'Phone number must be 10 digits',
    'phoneHelper': 'Will be used for SMS verification',
    'passwordRequired': 'Password is required',
    'passwordMinChars': 'Password must be at least 6 characters',
    'passwordHelper': 'At least 6 characters',
    'confirmPasswordRequired': 'Password confirmation is required',
    'passwordsNotMatch': 'Passwords do not match',
    'chooseValidUsername': 'Please choose a valid username',
    
    // Password strength
    'weak': 'Weak',
    'medium': 'Medium',
    'good': 'Good',
    'strong': 'Strong',
    'strongPassword': 'Strong password! ✓',
    'addForStronger': 'Add for stronger:',
    'chars8plus': '8+ characters',
    'uppercase': 'uppercase',
    'number': 'number',
    'specialChar': 'special character',
    // Follow Requests Page - New Keys
    'newRequestsWillAppearHere': 'New follow requests will appear here',
    'wantsToFollowYou': 'Wants to follow you',
    'nowFollowsYou': 'Now follows you',
    'followBack': 'Follow Back',
    'cancelRequest': 'Cancel Request',
    
    // Greetings
    'goodMorning': 'Good morning',
    'goodAfternoon': 'Good afternoon',
    'goodEvening': 'Good evening',
    'goodNight': 'Good night',
  };
}

extension LocaleStringExtension on String {
  String tr(BuildContext context) => Provider.of<LocaleProvider>(context, listen: true).get(this);
}

extension LocaleContextExtension on BuildContext {
  LocaleProvider get locale => Provider.of<LocaleProvider>(this, listen: true);
}
