"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.groqService = void 0;
const groq_sdk_1 = __importDefault(require("groq-sdk"));
const types_1 = require("../types");
const prompts_1 = require("../utils/prompts");
class GroqService {
    constructor() {
        this.model = 'llama-3.3-70b-versatile';
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) {
            console.error('❌ GROQ_API_KEY bulunamadı!');
        }
        this.client = new groq_sdk_1.default({
            apiKey: apiKey || 'dummy_key'
        });
    }
    /**
     * Ana chat fonksiyonu
     */
    async chat(messages, userPreferences, language = 'tr') {
        try {
            const prompts = (0, prompts_1.getPrompts)(language);
            let systemPrompt = prompts.assistant;
            if (userPreferences && Object.keys(userPreferences).length > 0) {
                const prefLabel = language === 'tr' ? 'Kullanıcı Tercihleri' : 'User Preferences';
                systemPrompt += `\n\n${prefLabel}: ${JSON.stringify(userPreferences)}`;
            }
            const completion = await this.client.chat.completions.create({
                model: this.model,
                messages: [
                    { role: 'system', content: systemPrompt },
                    ...messages.map(m => ({
                        role: m.role,
                        content: m.content
                    }))
                ],
                temperature: 0.8,
                max_tokens: 500,
                top_p: 0.9
            });
            const responseText = completion.choices[0]?.message?.content || '';
            const analysis = this.analyzeResponse(responseText, messages, language);
            return {
                success: true,
                message: responseText,
                intent: analysis.intent,
                suggestedCategories: analysis.categories,
                shouldRecommendRooms: analysis.shouldRecommend,
                usage: {
                    promptTokens: completion.usage?.prompt_tokens || 0,
                    completionTokens: completion.usage?.completion_tokens || 0,
                    totalTokens: completion.usage?.total_tokens || 0
                }
            };
        }
        catch (error) {
            console.error('❌ Groq API hatası:', error);
            if (error.status === 429) {
                return {
                    success: false,
                    message: language === 'tr'
                        ? 'Şu an çok yoğunum, biraz sonra tekrar dene! 😅'
                        : 'I\'m a bit busy right now, try again shortly! 😅',
                    error: 'RATE_LIMIT'
                };
            }
            return {
                success: false,
                message: language === 'tr'
                    ? 'Bir sorun oluştu, tekrar dener misin? 🙏'
                    : 'Something went wrong, can you try again? 🙏',
                error: error.message
            };
        }
    }
    /**
     * Mood analizi
     */
    async analyzeMood(userMessage, language = 'tr') {
        try {
            const prompts = (0, prompts_1.getPrompts)(language);
            const completion = await this.client.chat.completions.create({
                model: this.model,
                messages: [
                    { role: 'system', content: prompts.moodAnalyzer },
                    { role: 'user', content: userMessage }
                ],
                temperature: 0.3,
                max_tokens: 300,
                response_format: { type: 'json_object' }
            });
            const response = completion.choices[0]?.message?.content || '{}';
            return JSON.parse(response);
        }
        catch (error) {
            console.error('❌ Mood analizi hatası:', error);
            return {
                mood: 'neutral',
                energy: 'medium',
                socialLevel: 'small',
                suggestedCategories: ['chat', 'music']
            };
        }
    }
    /**
     * Oda önerisi açıklaması - HER ODA İÇİN FARKLI
     */
    async generateRoomExplanations(rooms, userPreferences, language = 'tr') {
        const explanations = new Map();
        const prompts = (0, prompts_1.getPrompts)(language);
        // Tüm odalar için tek bir prompt ile açıklama al
        const roomList = rooms.map((r, i) => `${i + 1}. "${r.name}" (${r.category}) - ${r.participantCount}/${r.maxParticipants} ${language === 'tr' ? 'kişi' : 'people'}`).join('\n');
        const systemContent = language === 'tr'
            ? `Her oda için 1 cümlelik FARKLI ve kişiselleştirilmiş açıklama yaz.
Kullanıcı tercihleri: ${JSON.stringify(userPreferences)}

Format (her satır için):
1: Açıklama
2: Açıklama
...

Kurallar:
- Her açıklama FARKLI olmalı, tekrar etme
- Max 15 kelime
- Emoji kullan
- Samimi dil
- TÜRKÇE yaz`
            : `Write 1 sentence DIFFERENT and personalized explanation for each room.
User preferences: ${JSON.stringify(userPreferences)}

Format (for each line):
1: Explanation
2: Explanation
...

Rules:
- Each explanation must be DIFFERENT, no repeats
- Max 15 words
- Use emojis
- Friendly tone
- Write in ENGLISH`;
        try {
            const completion = await this.client.chat.completions.create({
                model: 'llama-3.1-8b-instant', // Hızlı model
                messages: [
                    { role: 'system', content: systemContent },
                    { role: 'user', content: roomList }
                ],
                temperature: 0.9,
                max_tokens: 500
            });
            const response = completion.choices[0]?.message?.content || '';
            const lines = response.split('\n').filter(l => l.trim());
            lines.forEach((line, i) => {
                if (i < rooms.length) {
                    const explanation = line.replace(/^\d+[:.]\s*/, '').trim();
                    explanations.set(rooms[i].id, explanation);
                }
            });
        }
        catch (error) {
            console.error('❌ Açıklama oluşturma hatası:', error);
        }
        // Açıklama alınamayanlar için varsayılan
        rooms.forEach((room, i) => {
            if (!explanations.has(room.id)) {
                explanations.set(room.id, this.getDefaultExplanation(room, i, language));
            }
        });
        return explanations;
    }
    /**
     * Varsayılan açıklama
     */
    getDefaultExplanation(room, index, language) {
        const emoji = types_1.CATEGORIES[room.category]?.emoji || '✨';
        const defaults = language === 'tr'
            ? [
                `${emoji} Tam senin tarzın!`,
                `${emoji} Burayı seveceksin!`,
                `${emoji} Harika bir ortam!`,
                `${emoji} Yeni arkadaşlar edinebilirsin!`,
                `${emoji} Aktif ve eğlenceli!`
            ]
            : [
                `${emoji} Right up your alley!`,
                `${emoji} You'll love this place!`,
                `${emoji} Great atmosphere!`,
                `${emoji} Meet new friends here!`,
                `${emoji} Active and fun!`
            ];
        return defaults[index % defaults.length];
    }
    /**
     * Response analizi
     */
    analyzeResponse(text, messages, language) {
        const lowerText = text.toLowerCase();
        const userMessageCount = messages.filter(m => m.role === 'user').length;
        // Intent detection
        let intent = 'general_chat';
        if (language === 'tr') {
            if (lowerText.includes('nasıl') || lowerText.includes('ne yapmak')) {
                intent = 'mood_inquiry';
            }
            else if (lowerText.includes('kategori') || lowerText.includes('tür')) {
                intent = 'category_selection';
            }
        }
        else {
            if (lowerText.includes('how') || lowerText.includes('what would you like')) {
                intent = 'mood_inquiry';
            }
            else if (lowerText.includes('category') || lowerText.includes('type')) {
                intent = 'category_selection';
            }
        }
        // Category extraction from AI response
        const categories = [];
        Object.entries(types_1.CATEGORIES).forEach(([key, value]) => {
            if (value.keywords.some(kw => lowerText.includes(kw))) {
                categories.push(key);
            }
        });
        // Oda önerme kararı - DAHA AGRESIF
        const recommendKeywords = language === 'tr'
            ? [
                'getiriyorum', 'buluyorum', 'gösteriyorum', 'arıyorum',
                'odalar buldum', 'sana uygun oda', 'hemen bulayım',
                'bakıyorum', 'odaları getir', 'öneriyorum', 'önereceğim',
                'tam sana göre', 'sana harika', 'göstermek istiyorum'
            ]
            : [
                'finding', 'looking for', 'showing', 'searching',
                'found some rooms', 'rooms for you', 'let me find',
                'checking', 'getting rooms', 'recommend', 'suggesting',
                'perfect for you', 'great for you', 'want to show'
            ];
        const shouldRecommend = recommendKeywords.some(kw => lowerText.includes(kw));
        return { intent, categories, shouldRecommend };
    }
}
exports.groqService = new GroqService();
exports.default = GroqService;
//# sourceMappingURL=groqService.js.map