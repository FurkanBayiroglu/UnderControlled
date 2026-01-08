import * as admin from 'firebase-admin';
import { Room, RoomSearchCriteria } from '../types';

class FirestoreService {
  private db: admin.firestore.Firestore | null = null;
  private initialized = false;

  constructor() {
    this.initialize();
  }

  private initialize() {
    try {
      if (!admin.apps.length) {
        // 1. FIREBASE_SERVICE_ACCOUNT environment variable
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
          console.log('🔑 Firebase Service Account ile bağlanılıyor...');
          const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id
          });
          console.log('✅ Firebase bağlantısı başarılı');
        }
        // 2. GOOGLE_APPLICATION_CREDENTIALS file
        else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
          console.log('📁 GOOGLE_APPLICATION_CREDENTIALS ile bağlanılıyor...');
          admin.initializeApp({
            projectId: process.env.FIREBASE_PROJECT_ID
          });
        }
        // 3. Fallback
        else {
          console.log('⚠️ Credentials bulunamadı, project ID ile deneniyor...');
          admin.initializeApp({
            projectId: process.env.FIREBASE_PROJECT_ID || 'undercontrolled-f1948'
          });
        }
      }

      this.db = admin.firestore();
      this.initialized = true;
    } catch (error) {
      console.error('❌ Firebase init hatası:', error);
      this.initialized = false;
    }
  }

  /**
   * Aktif odaları getir - ÇEŞİTLİLİK İÇİN SHUFFLE
   */
  async getActiveRooms(criteria: RoomSearchCriteria = {}): Promise<Room[]> {
    if (!this.db) {
      console.warn('⚠️ Firestore bağlı değil');
      return [];
    }

    try {
      console.log('🔍 Odalar aranıyor:', JSON.stringify(criteria));
      
      let query: admin.firestore.Query = this.db
        .collection('rooms')
        .where('isActive', '==', true);

      // Kategori filtresi - max 10 (Firestore limiti)
      if (criteria.categories && criteria.categories.length > 0) {
        const cats = criteria.categories.slice(0, 10);
        query = query.where('category', 'in', cats);
        console.log('📂 Kategori filtresi:', cats);
      }

      // Daha fazla oda çek ki shuffle edebilelim
      query = query.limit(Math.min((criteria.limit || 20) * 3, 50));

      const snapshot = await query.get();
      console.log(`📊 Firestore'dan ${snapshot.size} oda geldi`);
      
      const rooms: Room[] = [];

      snapshot.forEach(doc => {
        const data = doc.data();
        const participants = data.participants || [];
        const participantCount = participants.length;
        const maxParticipants = data.maxParticipants || 20;
        
        // Kullanıcı zaten katılmış mı?
        if (criteria.excludeUserId && participants.includes(criteria.excludeUserId)) {
          return;
        }

        // Oda dolu mu?
        if (participantCount >= maxParticipants) {
          return;
        }

        rooms.push({
          id: doc.id,
          name: data.name || 'İsimsiz Oda',
          description: data.description || '',
          category: data.category || 'chat',
          createdBy: data.createdBy || '',
          createdAt: data.createdAt?.toDate?.()?.toISOString() || '',
          eventDate: data.eventDate?.toDate?.()?.toISOString() || '',
          eventTime: data.eventTime || '',
          durationMinutes: data.durationMinutes || 120,
          participants: participants,
          participantCount: participantCount,
          maxParticipants: maxParticipants,
          isActive: data.isActive ?? true,
          isPrivate: data.isPrivate ?? false
        });
      });

      // 🔀 SHUFFLE - Her seferinde farklı sıra
      const shuffled = this.shuffleArray(rooms);
      
      // Limit uygula
      const result = shuffled.slice(0, criteria.limit || 20);
      console.log(`✅ ${result.length} oda döndürülüyor`);
      
      return result;
    } catch (error: any) {
      console.error('❌ getActiveRooms hatası:', error.message);
      return [];
    }
  }

  /**
   * Fisher-Yates shuffle algoritması
   */
  private shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  /**
   * Belirli odaları hariç tut ve getir
   */
  async getActiveRoomsExcluding(
    excludeRoomIds: string[],
    criteria: RoomSearchCriteria = {}
  ): Promise<Room[]> {
    const allRooms = await this.getActiveRooms(criteria);
    return allRooms.filter(room => !excludeRoomIds.includes(room.id));
  }

  /**
   * Tek oda getir
   */
  async getRoom(roomId: string): Promise<Room | null> {
    if (!this.db) return null;

    try {
      const doc = await this.db.collection('rooms').doc(roomId).get();
      
      if (!doc.exists) return null;

      const data = doc.data()!;
      return {
        id: doc.id,
        name: data.name || 'İsimsiz Oda',
        description: data.description || '',
        category: data.category || 'chat',
        createdBy: data.createdBy || '',
        createdAt: data.createdAt?.toDate?.()?.toISOString() || '',
        eventDate: data.eventDate?.toDate?.()?.toISOString() || '',
        eventTime: data.eventTime || '',
        durationMinutes: data.durationMinutes || 120,
        participants: data.participants || [],
        participantCount: data.participantCount || (data.participants?.length || 0),
        maxParticipants: data.maxParticipants || 20,
        isActive: data.isActive ?? true,
        isPrivate: data.isPrivate ?? false
      };
    } catch (error: any) {
      console.error('❌ getRoom hatası:', error.message);
      return null;
    }
  }

  /**
   * Kategori bazlı oda sayısı
   */
  async getRoomCountByCategory(): Promise<Record<string, number>> {
    if (!this.db) return {};

    try {
      const snapshot = await this.db
        .collection('rooms')
        .where('isActive', '==', true)
        .get();

      const counts: Record<string, number> = {};
      snapshot.forEach(doc => {
        const category = doc.data().category || 'chat';
        counts[category] = (counts[category] || 0) + 1;
      });

      return counts;
    } catch (error) {
      console.error('❌ getRoomCountByCategory hatası:', error);
      return {};
    }
  }

  /**
   * Popüler kategoriler
   */
  async getPopularCategories(limit: number = 5): Promise<string[]> {
    const counts = await this.getRoomCountByCategory();
    return Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([category]) => category);
  }

  /**
   * Bağlantı durumu
   */
  isConnected(): boolean {
    return this.initialized && this.db !== null;
  }

  /**
   * Test bağlantısı
   */
  async testConnection(): Promise<{ success: boolean; message: string; roomCount?: number }> {
    if (!this.db) {
      return { success: false, message: 'Firestore bağlı değil' };
    }

    try {
      const count = await this.db.collection('rooms').count().get();
      const totalRooms = count.data().count;
      
      return { 
        success: true, 
        message: `Firestore bağlı. Toplam ${totalRooms} oda.`,
        roomCount: totalRooms
      };
    } catch (error: any) {
      return { 
        success: false, 
        message: `Bağlantı testi başarısız: ${error.message}` 
      };
    }
  }
}

export const firestoreService = new FirestoreService();
export default FirestoreService;
