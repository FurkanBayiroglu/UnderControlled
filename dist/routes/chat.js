"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const groqService_1 = require("../services/groqService");
const firestoreService_1 = require("../services/firestoreService");
const types_1 = require("../types");
const uuid_1 = require("uuid");
const router = (0, express_1.Router)();
// Session storage (production'da Redis kullan)
const sessions = new Map();
/**
 * POST /api/chat
 * Ana chat endpoint
 */
router.post('/', async (req, res) => {
    try {
        const { userId, sessionId, message, preferences, language } = req.body;
        const lang = (language === 'en' ? 'en' : 'tr');
        if (!userId || !message) {
            return res.status(400).json({
                success: false,
                error: lang === 'tr' ? 'userId ve message zorunlu' : 'userId and message are required'
            });
        }
        // Session al veya oluştur
        const currentSessionId = sessionId || (0, uuid_1.v4)();
        let session = sessions.get(currentSessionId);
        if (!session) {
            session = {
                messages: [],
                preferences: preferences || {},
                createdAt: new Date(),
                recommendedRoomIds: [],
                language: lang
            };
            sessions.set(currentSessionId, session);
        }
        // Dil güncelle
        session.language = lang;
        // Kullanıcı mesajını ekle
        session.messages.push({
            role: 'user',
            content: message,
            timestamp: new Date().toISOString()
        });
        // Tercihler güncelle
        if (preferences) {
            session.preferences = { ...session.preferences, ...preferences };
        }
        // Kullanıcı mesajından kategori çıkar
        const detectedCategories = detectCategoriesFromMessage(message, lang);
        if (detectedCategories.length > 0) {
            session.preferences.categories = [
                ...(session.preferences.categories || []),
                ...detectedCategories
            ].filter((v, i, a) => a.indexOf(v) === i);
        }
        // Kullanıcı açıkça oda istedimi kontrol et
        const userWantsRooms = checkIfUserWantsRooms(message, lang);
        const messageCount = session.messages.filter(m => m.role === 'user').length;
        // AI'dan yanıt al
        const aiResponse = await groqService_1.groqService.chat(session.messages, session.preferences, lang // Dil bilgisi
        );
        if (aiResponse.success) {
            session.messages.push({
                role: 'assistant',
                content: aiResponse.message || '',
                timestamp: new Date().toISOString()
            });
            // AI'dan gelen kategorileri ekle
            if (aiResponse.suggestedCategories && aiResponse.suggestedCategories.length > 0) {
                session.preferences.categories = [
                    ...(session.preferences.categories || []),
                    ...aiResponse.suggestedCategories
                ].filter((v, i, a) => a.indexOf(v) === i);
            }
        }
        // Oda önerme kararı
        const shouldShowRooms = userWantsRooms || aiResponse.shouldRecommendRooms;
        let roomRecommendations = [];
        if (shouldShowRooms) {
            roomRecommendations = await generateRecommendations(session, userId, lang);
        }
        // Quick replies
        const quickReplies = generateQuickReplies(aiResponse.intent || 'general', session.preferences, roomRecommendations.length > 0, lang);
        return res.json({
            success: true,
            sessionId: currentSessionId,
            message: aiResponse.message,
            intent: aiResponse.intent,
            recommendations: roomRecommendations,
            quickReplies,
            suggestedCategories: session.preferences.categories,
            messageCount,
            usage: aiResponse.usage
        });
    }
    catch (error) {
        console.error('❌ Chat hatası:', error);
        const lang = req.body?.language === 'en' ? 'en' : 'tr';
        return res.status(500).json({
            success: false,
            error: lang === 'tr' ? 'Chat işlemi başarısız' : 'Chat operation failed',
            message: lang === 'tr' ? 'Bir sorun oluştu, tekrar dener misin? 🙏' : 'Something went wrong, can you try again? 🙏'
        });
    }
});
/**
 * POST /api/chat/start
 * Yeni sohbet başlat
 */
router.post('/start', async (req, res) => {
    try {
        const { userId, userName, language } = req.body;
        const lang = (language === 'en' ? 'en' : 'tr');
        const sessionId = (0, uuid_1.v4)();
        const hour = new Date().getHours();
        let greeting = '';
        let emoji = '';
        if (lang === 'tr') {
            if (hour >= 5 && hour < 12) {
                greeting = 'Günaydın';
                emoji = '☀️';
            }
            else if (hour >= 12 && hour < 18) {
                greeting = 'İyi günler';
                emoji = '👋';
            }
            else if (hour >= 18 && hour < 22) {
                greeting = 'İyi akşamlar';
                emoji = '🌆';
            }
            else {
                greeting = 'Selam';
                emoji = '🌙';
            }
        }
        else {
            if (hour >= 5 && hour < 12) {
                greeting = 'Good morning';
                emoji = '☀️';
            }
            else if (hour >= 12 && hour < 18) {
                greeting = 'Good afternoon';
                emoji = '👋';
            }
            else if (hour >= 18 && hour < 22) {
                greeting = 'Good evening';
                emoji = '🌆';
            }
            else {
                greeting = 'Hey';
                emoji = '🌙';
            }
        }
        const welcomeMessage = lang === 'tr'
            ? (userName
                ? `${greeting} ${userName}! ${emoji}\n\nBen Kontrol, senin AI asistanın. Bugün nasılsın?`
                : `${greeting}! ${emoji}\n\nBen Kontrol. Bugün nasılsın, neler yapmak istersin?`)
            : (userName
                ? `${greeting} ${userName}! ${emoji}\n\nI'm Control, your AI assistant. How are you doing today?`
                : `${greeting}! ${emoji}\n\nI'm Control. How are you today, what would you like to do?`);
        // Session oluştur
        sessions.set(sessionId, {
            messages: [{
                    role: 'assistant',
                    content: welcomeMessage,
                    timestamp: new Date().toISOString()
                }],
            preferences: {},
            createdAt: new Date(),
            recommendedRoomIds: [],
            language: lang
        });
        const quickReplies = lang === 'tr'
            ? [
                { text: '⚡ Enerjik hissediyorum', value: 'energetic', emoji: '⚡' },
                { text: '🧘 Sakin bir şeyler', value: 'calm', emoji: '🧘' },
                { text: '🎉 Sosyalleşmek istiyorum', value: 'social', emoji: '🎉' },
                { text: '🎮 Oyun oynayalım', value: 'gaming', emoji: '🎮' },
                { text: '💬 Sohbet edelim', value: 'chat', emoji: '💬' }
            ]
            : [
                { text: '⚡ Feeling energetic', value: 'energetic', emoji: '⚡' },
                { text: '🧘 Something calm', value: 'calm', emoji: '🧘' },
                { text: '🎉 Want to socialize', value: 'social', emoji: '🎉' },
                { text: '🎮 Let\'s play games', value: 'gaming', emoji: '🎮' },
                { text: '💬 Let\'s chat', value: 'chat', emoji: '💬' }
            ];
        return res.json({
            success: true,
            sessionId,
            message: welcomeMessage,
            quickReplies
        });
    }
    catch (error) {
        console.error('❌ Start chat hatası:', error);
        const lang = req.body?.language === 'en' ? 'en' : 'tr';
        return res.status(500).json({
            success: false,
            error: lang === 'tr' ? 'Sohbet başlatılamadı' : 'Could not start chat'
        });
    }
});
/**
 * POST /api/chat/mood
 * Mood analizi
 */
router.post('/mood', async (req, res) => {
    try {
        const { message, language } = req.body;
        const lang = (language === 'en' ? 'en' : 'tr');
        if (!message) {
            return res.status(400).json({
                success: false,
                error: lang === 'tr' ? 'message zorunlu' : 'message is required'
            });
        }
        const analysis = await groqService_1.groqService.analyzeMood(message, lang);
        return res.json({
            success: true,
            ...analysis
        });
    }
    catch (error) {
        console.error('❌ Mood analizi hatası:', error);
        return res.status(500).json({
            success: false,
            error: 'Mood analysis failed'
        });
    }
});
/**
 * GET /api/chat/session/:sessionId
 */
router.get('/session/:sessionId', async (req, res) => {
    const { sessionId } = req.params;
    const session = sessions.get(sessionId);
    if (!session) {
        return res.status(404).json({
            success: false,
            error: 'Session not found'
        });
    }
    return res.json({
        success: true,
        sessionId,
        messageCount: session.messages.length,
        preferences: session.preferences,
        createdAt: session.createdAt,
        language: session.language
    });
});
/**
 * DELETE /api/chat/session/:sessionId
 */
router.delete('/session/:sessionId', async (req, res) => {
    const { sessionId } = req.params;
    const deleted = sessions.delete(sessionId);
    return res.json({
        success: true,
        deleted
    });
});
// ============ HELPERS ============
/**
 * Kullanıcı oda istiyor mu?
 */
function checkIfUserWantsRooms(message, lang) {
    const lower = message.toLowerCase();
    const keywords = lang === 'tr'
        ? [
            'oda göster', 'oda bul', 'oda öner', 'odaları göster',
            'yönlendir', 'öneri yap', 'katılayım', 'girmek istiyorum',
            'hadi göster', 'tamam göster', 'göster bakalım',
            'evet göster', 'olur göster', 'bul bana'
        ]
        : [
            'show rooms', 'find rooms', 'recommend rooms', 'show me rooms',
            'suggest rooms', 'find me', 'i want to join', 'show recommendations',
            'yes show', 'okay show', 'let me see', 'show some'
        ];
    return keywords.some(kw => lower.includes(kw));
}
/**
 * Mesajdan kategori çıkar
 */
function detectCategoriesFromMessage(message, lang) {
    const lower = message.toLowerCase();
    const detected = [];
    // Türkçe ve İngilizce keywords
    const categoryKeywords = {
        'gaming': ['oyun', 'game', 'oyna', 'ps', 'xbox', 'valorant', 'lol', 'cs', 'play'],
        'music': ['müzik', 'şarkı', 'dinle', 'rock', 'pop', 'rap', 'music', 'song', 'listen'],
        'sports': ['spor', 'futbol', 'basketbol', 'koşu', 'maç', 'sport', 'football', 'basketball', 'soccer'],
        'movie': ['film', 'dizi', 'izle', 'sinema', 'netflix', 'movie', 'series', 'watch', 'cinema'],
        'chat': ['sohbet', 'konuş', 'muhabbet', 'tanış', 'chat', 'talk', 'meet'],
        'study': ['ders', 'çalış', 'sınav', 'ödev', 'study', 'exam', 'homework', 'learn'],
        'coding': ['kod', 'yazılım', 'program', 'developer', 'code', 'programming', 'dev'],
        'food': ['yemek', 'yiyecek', 'tarif', 'food', 'recipe', 'cook', 'eat'],
        'yoga': ['yoga', 'meditasyon', 'rahatla', 'meditation', 'relax'],
        'art': ['sanat', 'resim', 'çizim', 'art', 'draw', 'paint']
    };
    for (const [category, keywords] of Object.entries(categoryKeywords)) {
        if (keywords.some(kw => lower.includes(kw))) {
            detected.push(category);
        }
    }
    return detected;
}
/**
 * Oda önerileri oluştur - ÇEŞİTLİLİK İLE
 */
async function generateRecommendations(session, userId, lang) {
    try {
        // Mood'a göre kategoriler
        let categories = session.preferences.categories || [];
        if (session.preferences.mood && categories.length === 0) {
            categories = types_1.MOOD_CATEGORIES[session.preferences.mood] || [];
        }
        // Daha önce önerilmemiş odaları al
        const rooms = await firestoreService_1.firestoreService.getActiveRoomsExcluding(session.recommendedRoomIds, {
            categories: categories.length > 0 ? categories : undefined,
            excludeUserId: userId,
            limit: 20
        });
        if (rooms.length === 0) {
            // Hiç oda yoksa, tüm odalardan al
            const allRooms = await firestoreService_1.firestoreService.getActiveRooms({
                excludeUserId: userId,
                limit: 10
            });
            if (allRooms.length === 0) {
                return [];
            }
            return scoreAndPrepareRooms(allRooms.slice(0, 5), session, [], lang);
        }
        // Skorla ve hazırla
        const recommendations = await scoreAndPrepareRooms(rooms.slice(0, 8), session, session.recommendedRoomIds, lang);
        // Önerilen odaları kaydet
        recommendations.forEach(r => {
            if (!session.recommendedRoomIds.includes(r.id)) {
                session.recommendedRoomIds.push(r.id);
            }
        });
        return recommendations.slice(0, 5);
    }
    catch (error) {
        console.error('❌ Öneri oluşturma hatası:', error);
        return [];
    }
}
/**
 * Odaları skorla ve hazırla
 */
async function scoreAndPrepareRooms(rooms, session, previouslyRecommended, lang) {
    const preferences = session.preferences;
    // AI'dan açıklamalar al
    const explanations = await groqService_1.groqService.generateRoomExplanations(rooms, preferences, lang);
    return rooms.map((room, index) => {
        let score = 50; // Base score
        // Kategori uyumu
        if (preferences.categories?.includes(room.category)) {
            score += 30;
        }
        // Mood uyumu
        if (preferences.mood) {
            const moodCategories = types_1.MOOD_CATEGORIES[preferences.mood] || [];
            if (moodCategories.includes(room.category)) {
                score += 20;
            }
        }
        // Aktif oda bonusu (1-5 kişi ideal)
        if (room.participantCount >= 1 && room.participantCount <= 5) {
            score += 15;
        }
        else if (room.participantCount > 5) {
            score += 10;
        }
        // Yeni oda bonusu
        if (room.participantCount === 0) {
            score += 5;
        }
        // Doluluk - çok dolu olmayanlar
        const fillRate = room.participantCount / room.maxParticipants;
        if (fillRate < 0.5) {
            score += 10;
        }
        // Daha önce önerilmişse ceza
        if (previouslyRecommended.includes(room.id)) {
            score -= 40;
        }
        // Rastgelelik ekle (çeşitlilik için)
        score += Math.random() * 20;
        return {
            ...room,
            score: Math.round(score),
            matchReason: getMatchReason(room, preferences, lang),
            aiExplanation: explanations.get(room.id) || (lang === 'tr' ? 'Senin için önerdik! ✨' : 'We recommend this for you! ✨')
        };
    })
        .sort((a, b) => b.score - a.score);
}
/**
 * Eşleşme nedeni
 */
function getMatchReason(room, preferences, lang) {
    if (lang === 'tr') {
        if (preferences.categories?.includes(room.category)) {
            return '✓ Tercihine uygun';
        }
        if (preferences.mood) {
            const moodCategories = types_1.MOOD_CATEGORIES[preferences.mood] || [];
            if (moodCategories.includes(room.category)) {
                return '🎯 Ruh haline uygun';
            }
        }
        if (room.participantCount > 5) {
            return '🔥 Popüler';
        }
        if (room.participantCount === 0) {
            return '🆕 Yeni açıldı';
        }
        return '💡 Öneri';
    }
    else {
        if (preferences.categories?.includes(room.category)) {
            return '✓ Matches your preference';
        }
        if (preferences.mood) {
            const moodCategories = types_1.MOOD_CATEGORIES[preferences.mood] || [];
            if (moodCategories.includes(room.category)) {
                return '🎯 Fits your mood';
            }
        }
        if (room.participantCount > 5) {
            return '🔥 Popular';
        }
        if (room.participantCount === 0) {
            return '🆕 Just opened';
        }
        return '💡 Suggested';
    }
}
/**
 * Quick replies oluştur
 */
function generateQuickReplies(intent, preferences, hasRooms, lang) {
    if (lang === 'tr') {
        if (hasRooms) {
            return [
                { text: '✨ Daha fazla göster', value: 'more_rooms', emoji: '✨' },
                { text: '🔄 Farklı kategoriler', value: 'change_category', emoji: '🔄' }
            ];
        }
        switch (intent) {
            case 'mood_inquiry':
                return [
                    { text: '⚡ Enerjik', value: 'energetic', emoji: '⚡' },
                    { text: '🧘 Sakin', value: 'calm', emoji: '🧘' },
                    { text: '🎉 Sosyal', value: 'social', emoji: '🎉' },
                    { text: '🎯 Odaklanmış', value: 'focused', emoji: '🎯' }
                ];
            case 'category_selection':
                return [
                    { text: '🎮 Oyun', value: 'gaming', emoji: '🎮' },
                    { text: '🎵 Müzik', value: 'music', emoji: '🎵' },
                    { text: '💬 Sohbet', value: 'chat', emoji: '💬' },
                    { text: '🎬 Film', value: 'movie', emoji: '🎬' }
                ];
            default:
                return [
                    { text: '🎯 Oda öner', value: 'recommend', emoji: '🎯' },
                    { text: '❓ Ne yapabilirim?', value: 'help', emoji: '❓' }
                ];
        }
    }
    else {
        if (hasRooms) {
            return [
                { text: '✨ Show more', value: 'more_rooms', emoji: '✨' },
                { text: '🔄 Different categories', value: 'change_category', emoji: '🔄' }
            ];
        }
        switch (intent) {
            case 'mood_inquiry':
                return [
                    { text: '⚡ Energetic', value: 'energetic', emoji: '⚡' },
                    { text: '🧘 Calm', value: 'calm', emoji: '🧘' },
                    { text: '🎉 Social', value: 'social', emoji: '🎉' },
                    { text: '🎯 Focused', value: 'focused', emoji: '🎯' }
                ];
            case 'category_selection':
                return [
                    { text: '🎮 Gaming', value: 'gaming', emoji: '🎮' },
                    { text: '🎵 Music', value: 'music', emoji: '🎵' },
                    { text: '💬 Chat', value: 'chat', emoji: '💬' },
                    { text: '🎬 Movies', value: 'movie', emoji: '🎬' }
                ];
            default:
                return [
                    { text: '🎯 Recommend rooms', value: 'recommend', emoji: '🎯' },
                    { text: '❓ What can I do?', value: 'help', emoji: '❓' }
                ];
        }
    }
}
exports.default = router;
//# sourceMappingURL=chat.js.map