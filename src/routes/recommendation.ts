import { Router, Request, Response } from 'express';
import { groqService } from '../services/groqService';
import { firestoreService } from '../services/firestoreService';
import { RecommendationRequest, UserPreferences, CATEGORIES, MOOD_CATEGORIES } from '../types';

const router = Router();

// Daha önce önerilen odaları takip et (basit in-memory)
const userRecommendationHistory: Map<string, string[]> = new Map();

/**
 * POST /api/recommend
 * Oda önerileri al
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const { userId, preferences, limit = 5 } = req.body as RecommendationRequest;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId zorunlu'
      });
    }

    // Kullanıcının daha önce gördüğü odalar
    const previouslyRecommended = userRecommendationHistory.get(userId) || [];

    // Kategorileri belirle
    let categories = preferences?.categories || [];
    
    // Mood'a göre kategoriler
    if (preferences?.mood && categories.length === 0) {
      categories = MOOD_CATEGORIES[preferences.mood] || [];
    }

    // Odaları çek - daha önce önerilmeyenleri tercih et
    let rooms = await firestoreService.getActiveRoomsExcluding(
      previouslyRecommended,
      {
        categories: categories.length > 0 ? categories : undefined,
        excludeUserId: userId,
        limit: 30
      }
    );

    // Yeterli oda yoksa tümünden al
    if (rooms.length < limit) {
      const allRooms = await firestoreService.getActiveRooms({
        categories: categories.length > 0 ? categories : undefined,
        excludeUserId: userId,
        limit: 30
      });
      
      // Birleştir ve tekrarları kaldır
      const roomIds = new Set(rooms.map(r => r.id));
      allRooms.forEach(r => {
        if (!roomIds.has(r.id)) {
          rooms.push(r);
        }
      });
    }

    if (rooms.length === 0) {
      return res.json({
        success: true,
        recommendations: [],
        message: 'Şu an aktif oda bulunamadı. Yeni bir oda oluşturmak ister misin? 🏠'
      });
    }

    // Skorla
    const scoredRooms = scoreRooms(rooms, preferences || {}, previouslyRecommended);

    // En iyi önerileri al
    const topRooms = scoredRooms.slice(0, limit);

    // AI açıklamaları al
    const explanations = await groqService.generateRoomExplanations(topRooms, preferences || {});

    // Önerileri hazırla
    const recommendations = topRooms.map(room => ({
      ...room,
      aiExplanation: explanations.get(room.id) || getDefaultExplanation(room)
    }));

    // History'ye ekle
    const newHistory = [
      ...previouslyRecommended,
      ...recommendations.map(r => r.id)
    ].slice(-50); // Son 50 öneriyi tut
    userRecommendationHistory.set(userId, newHistory);

    return res.json({
      success: true,
      recommendations,
      totalFound: rooms.length,
      message: generateResultMessage(recommendations.length, preferences || {})
    });

  } catch (error: any) {
    console.error('❌ Recommendation hatası:', error);
    return res.status(500).json({
      success: false,
      error: 'Öneri oluşturulamadı'
    });
  }
});

/**
 * GET /api/recommend/categories
 * Kategorileri listele
 */
router.get('/categories', async (_req: Request, res: Response) => {
  try {
    const counts = await firestoreService.getRoomCountByCategory();
    
    const categories = Object.entries(CATEGORIES).map(([id, info]) => ({
      id,
      name: info.name,
      emoji: info.emoji,
      roomCount: counts[id] || 0
    }));

    // Oda sayısına göre sırala
    categories.sort((a, b) => b.roomCount - a.roomCount);

    return res.json({
      success: true,
      categories,
      popularCategories: categories.slice(0, 5).map(c => c.id)
    });

  } catch (error) {
    console.error('❌ Categories hatası:', error);
    return res.status(500).json({
      success: false,
      error: 'Kategoriler getirilemedi'
    });
  }
});

/**
 * POST /api/recommend/quick
 * Hızlı öneri - skorlama olmadan
 */
router.post('/quick', async (req: Request, res: Response) => {
  try {
    const { userId, category, limit = 5 } = req.body;

    const rooms = await firestoreService.getActiveRooms({
      categories: category ? [category] : undefined,
      excludeUserId: userId,
      limit
    });

    return res.json({
      success: true,
      rooms,
      count: rooms.length
    });

  } catch (error) {
    console.error('❌ Quick recommend hatası:', error);
    return res.status(500).json({
      success: false,
      error: 'Hızlı öneri başarısız'
    });
  }
});

/**
 * POST /api/recommend/reset
 * Kullanıcının öneri geçmişini sıfırla
 */
router.post('/reset', async (req: Request, res: Response) => {
  try {
    const { userId } = req.body;
    
    if (userId) {
      userRecommendationHistory.delete(userId);
    }

    return res.json({
      success: true,
      message: 'Öneri geçmişi sıfırlandı'
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      error: 'Sıfırlama başarısız'
    });
  }
});

// ============ HELPERS ============

/**
 * Odaları skorla - ÇEŞİTLİLİK İLE
 */
function scoreRooms(
  rooms: any[],
  preferences: UserPreferences,
  previouslyRecommended: string[]
): any[] {
  return rooms.map(room => {
    let score = 50;

    // Kategori uyumu (+30)
    if (preferences.categories?.includes(room.category)) {
      score += 30;
    }

    // Mood uyumu (+20)
    if (preferences.mood) {
      const moodCategories = MOOD_CATEGORIES[preferences.mood] || [];
      if (moodCategories.includes(room.category)) {
        score += 20;
      }
    }

    // Enerji uyumu (+15)
    if (preferences.energy) {
      const highEnergy = ['sports', 'fitness', 'dance', 'esports', 'outdoor'];
      const lowEnergy = ['yoga', 'reading', 'coffee', 'movie', 'podcast'];
      
      if (preferences.energy === 'high' && highEnergy.includes(room.category)) {
        score += 15;
      } else if (preferences.energy === 'low' && lowEnergy.includes(room.category)) {
        score += 15;
      }
    }

    // Grup büyüklüğü uyumu (+10)
    if (preferences.groupSize) {
      const max = room.maxParticipants;
      if (preferences.groupSize === 'solo' && max <= 5) score += 10;
      else if (preferences.groupSize === 'small' && max <= 10) score += 10;
      else if (preferences.groupSize === 'large' && max >= 15) score += 10;
    }

    // Aktif oda bonusu (+15)
    if (room.participantCount >= 1 && room.participantCount <= 5) {
      score += 15;
    } else if (room.participantCount > 5) {
      score += 10;
    }

    // Yeni oda bonusu (+5)
    if (room.participantCount === 0) {
      score += 5;
    }

    // Doluluk oranı - az dolu odalar tercih
    const fillRate = room.participantCount / room.maxParticipants;
    if (fillRate < 0.3) score += 10;
    else if (fillRate < 0.6) score += 5;

    // DAHA ÖNCE ÖNERİLMİŞSE BÜYÜK CEZA (-50)
    if (previouslyRecommended.includes(room.id)) {
      score -= 50;
    }

    // Rastgele varyasyon (+0-25) - ÇEŞİTLİLİK İÇİN
    score += Math.random() * 25;

    return {
      ...room,
      score: Math.round(score),
      matchReason: getMatchReason(room, preferences)
    };
  }).sort((a, b) => b.score - a.score);
}

/**
 * Eşleşme nedeni
 */
function getMatchReason(room: any, preferences: UserPreferences): string {
  if (preferences.categories?.includes(room.category)) {
    return '✓ Tercihine uygun';
  }
  
  if (preferences.mood) {
    const moodCategories = MOOD_CATEGORIES[preferences.mood] || [];
    if (moodCategories.includes(room.category)) {
      return '🎯 Ruh haline göre';
    }
  }
  
  if (room.participantCount > 5) {
    return '🔥 Popüler';
  }
  
  if (room.participantCount === 0) {
    return '🆕 Yeni açıldı';
  }
  
  return '💡 Sana göre';
}

/**
 * Varsayılan açıklama
 */
function getDefaultExplanation(room: any): string {
  const category = CATEGORIES[room.category];
  const emoji = category?.emoji || '✨';
  
  const options = [
    `${emoji} Burayı seveceksin!`,
    `${emoji} Tam senlik bir yer!`,
    `${emoji} Yeni insanlarla tanış!`,
    `${emoji} Eğlenceli bir ortam!`,
    `${emoji} Denemeye değer!`
  ];
  
  return options[Math.floor(Math.random() * options.length)];
}

/**
 * Sonuç mesajı
 */
function generateResultMessage(count: number, preferences: UserPreferences): string {
  if (count === 0) {
    return 'Şu an uygun oda bulamadım, yeni odalar sürekli açılıyor! 🔍';
  }
  
  const emoji = preferences.mood === 'energetic' ? '⚡' :
                preferences.mood === 'calm' ? '🧘' :
                preferences.mood === 'social' ? '🎉' : '🎯';
  
  return `${emoji} Senin için ${count} oda buldum!`;
}

export default router;
