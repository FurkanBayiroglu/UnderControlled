"use strict";
// ============ CHAT TYPES ============
Object.defineProperty(exports, "__esModule", { value: true });
exports.MOOD_CATEGORIES = exports.CATEGORIES = void 0;
// ============ CATEGORIES ============
exports.CATEGORIES = {
    sports: { name: 'Spor', emoji: '⚽', keywords: ['spor', 'futbol', 'basketbol', 'voleybol', 'tenis'] },
    fitness: { name: 'Fitness', emoji: '💪', keywords: ['fitness', 'spor salonu', 'egzersiz', 'antrenman'] },
    yoga: { name: 'Yoga', emoji: '🧘', keywords: ['yoga', 'meditasyon', 'pilates', 'nefes'] },
    gaming: { name: 'Oyun', emoji: '🎮', keywords: ['oyun', 'game', 'ps5', 'xbox', 'pc', 'valorant', 'lol'] },
    esports: { name: 'E-Spor', emoji: '🏆', keywords: ['esports', 'turnuva', 'rekabetçi'] },
    music: { name: 'Müzik', emoji: '🎵', keywords: ['müzik', 'şarkı', 'enstrüman', 'gitar', 'piyano'] },
    art: { name: 'Sanat', emoji: '🎨', keywords: ['sanat', 'resim', 'çizim', 'heykel'] },
    photography: { name: 'Fotoğraf', emoji: '📷', keywords: ['fotoğraf', 'kamera', 'çekim'] },
    dance: { name: 'Dans', emoji: '💃', keywords: ['dans', 'salsa', 'hiphop', 'bale'] },
    study: { name: 'Çalışma', emoji: '📚', keywords: ['ders', 'çalışma', 'sınav', 'ödev', 'okul'] },
    language: { name: 'Dil', emoji: '🌍', keywords: ['dil', 'ingilizce', 'almanca', 'yabancı dil'] },
    coding: { name: 'Kodlama', emoji: '💻', keywords: ['kod', 'yazılım', 'program', 'developer', 'geliştirici'] },
    reading: { name: 'Okuma', emoji: '📖', keywords: ['kitap', 'okuma', 'roman', 'edebiyat'] },
    chat: { name: 'Sohbet', emoji: '💬', keywords: ['sohbet', 'konuşma', 'muhabbet', 'tanışma'] },
    networking: { name: 'Network', emoji: '🤝', keywords: ['network', 'iş', 'kariyer', 'profesyonel'] },
    movie: { name: 'Film', emoji: '🎬', keywords: ['film', 'sinema', 'dizi', 'izle'] },
    anime: { name: 'Anime', emoji: '🎌', keywords: ['anime', 'manga', 'japon'] },
    podcast: { name: 'Podcast', emoji: '🎙️', keywords: ['podcast', 'dinle', 'yayın'] },
    food: { name: 'Yemek', emoji: '🍕', keywords: ['yemek', 'tarif', 'mutfak', 'aşçı'] },
    cooking: { name: 'Yemek Yapma', emoji: '👨‍🍳', keywords: ['pişirme', 'tarif', 'mutfak'] },
    coffee: { name: 'Kahve', emoji: '☕', keywords: ['kahve', 'kafe', 'çay'] },
    travel: { name: 'Seyahat', emoji: '✈️', keywords: ['seyahat', 'gezi', 'tatil', 'tur'] },
    outdoor: { name: 'Açık Hava', emoji: '🏕️', keywords: ['doğa', 'kamp', 'yürüyüş', 'outdoor'] },
    tech: { name: 'Teknoloji', emoji: '📱', keywords: ['teknoloji', 'gadget', 'telefon', 'bilgisayar'] },
    crypto: { name: 'Kripto', emoji: '₿', keywords: ['kripto', 'bitcoin', 'blockchain'] },
    pets: { name: 'Evcil Hayvan', emoji: '🐕', keywords: ['kedi', 'köpek', 'evcil hayvan', 'pet'] },
    fashion: { name: 'Moda', emoji: '👗', keywords: ['moda', 'giyim', 'stil', 'kıyafet'] }
};
// Mood -> Kategori eşleştirmesi
exports.MOOD_CATEGORIES = {
    energetic: ['sports', 'fitness', 'dance', 'esports', 'outdoor', 'gaming'],
    calm: ['yoga', 'reading', 'art', 'coffee', 'podcast', 'music'],
    social: ['chat', 'food', 'movie', 'gaming', 'networking', 'coffee'],
    focused: ['study', 'coding', 'language', 'reading', 'tech'],
    creative: ['art', 'music', 'photography', 'cooking', 'fashion', 'dance'],
    bored: ['gaming', 'movie', 'chat', 'music', 'anime'],
    stressed: ['yoga', 'music', 'coffee', 'pets', 'outdoor'],
    happy: ['chat', 'music', 'dance', 'food', 'travel']
};
//# sourceMappingURL=index.js.map