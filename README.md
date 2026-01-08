# 🤖 UnderControl AI Backend

Flutter UnderControl uygulaması için AI destekli öneri backend sistemi.

## 🏗️ Mimari

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│ Flutter App │────▶│ AWS API Gateway │────▶│ AWS Lambda   │
└─────────────┘     └─────────────────┘     │ (Node.js)    │
                                            └──────┬───────┘
                                                   │
                    ┌──────────────────────────────┼─────────────────┐
                    ▼                              ▼                 ▼
             ┌─────────────┐              ┌──────────────┐   ┌───────────┐
             │  Groq API   │              │  Firestore   │   │  Session  │
             │ (Llama 3.3) │              │   (Rooms)    │   │  Storage  │
             └─────────────┘              └──────────────┘   └───────────┘
```

## ✨ Özellikler

- 🤖 **AI Sohbet**: Llama 3.3 70B ile doğal Türkçe konuşma
- 🎯 **Akıllı Öneriler**: Kullanıcı tercihlerine göre oda önerileri
- 😊 **Mood Analizi**: Ruh hali tespiti ve uygun kategoriler
- 🔄 **Session Yönetimi**: Sohbet geçmişi ve tercih hatırlama
- ⚡ **Hızlı Yanıt**: Groq LPU ile 300+ token/saniye

## 📋 Gereksinimler

- Node.js 18+
- npm veya yarn
- AWS CLI (deployment için)
- Groq API Key
- Firebase Project

## 🚀 Hızlı Başlangıç

### 1. Kurulum

```bash
# Repo'yu klonla veya dosyaları kopyala
cd ai-backend

# Bağımlılıkları yükle
npm install

# Environment dosyasını oluştur
cp .env.example .env
```

### 2. API Anahtarlarını Al

#### Groq API Key:
1. https://console.groq.com adresine git
2. "API Keys" bölümüne tıkla
3. "Create API Key" ile yeni anahtar oluştur
4. `.env` dosyasına `GROQ_API_KEY=gsk_...` olarak ekle

#### Firebase:
1. Firebase Console'dan proje ayarlarına git
2. Service Account oluştur veya project ID'yi kullan
3. `.env` dosyasına `FIREBASE_PROJECT_ID=...` ekle

### 3. Local Çalıştırma

```bash
# Development mode
npm run dev

# Server http://localhost:3000'de çalışacak
```

### 4. Test

```bash
# Health check
curl http://localhost:3000/api/health

# Chat başlat
curl -X POST http://localhost:3000/api/chat/start \
  -H "Content-Type: application/json" \
  -d '{"userId": "test123", "userName": "Test User"}'

# Mesaj gönder
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test123",
    "sessionId": "session-id-from-start",
    "message": "Bugün oyun oynamak istiyorum"
  }'
```

## 🌐 AWS Deployment

### Otomatik Deployment (Önerilen)

```bash
# AWS CLI yapılandır
aws configure

# Deploy
npm run deploy

# Staging deploy
npm run deploy -- --stage staging
```

### Manuel Deployment

1. **Lambda Function Oluştur**:
   - Runtime: Node.js 18.x
   - Handler: dist/index.handler
   - Memory: 512 MB
   - Timeout: 30 saniye

2. **API Gateway Oluştur**:
   - REST API
   - Lambda Proxy Integration
   - ANY /{proxy+}

3. **Environment Variables**:
   - GROQ_API_KEY
   - FIREBASE_PROJECT_ID
   - NODE_ENV=production

## 📡 API Endpoints

### Chat

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/chat/start` | Yeni sohbet başlat |
| POST | `/api/chat` | Mesaj gönder |
| POST | `/api/chat/mood` | Mood analizi |
| GET | `/api/chat/session/:id` | Session bilgisi |
| DELETE | `/api/chat/session/:id` | Session sil |

### Recommendation

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/recommend` | Oda önerileri al |
| POST | `/api/recommend/quick` | Hızlı öneri |
| GET | `/api/recommend/categories` | Kategorileri listele |

### Health

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/health` | Health check |
| GET | `/api/health/detailed` | Detaylı durum |
| GET | `/api/health/ping` | Ping/Pong |

## 📱 Flutter Entegrasyonu

Flutter uygulamasında bu backend'i kullanmak için:

```dart
// lib/services/ai_service.dart dosyasını oluştur
// Detaylı kod aşağıda Flutter Integration bölümünde
```

## 💰 Maliyet Tahmini

| Servis | Free Tier | Tahmini Kullanım |
|--------|-----------|------------------|
| AWS Lambda | 1M istek/ay | ✅ Ücretsiz |
| API Gateway | 1M istek/ay | ✅ Ücretsiz |
| Groq API | 14,400 istek/gün | ✅ Ücretsiz |
| Firebase | Spark plan | ✅ Ücretsiz |

**Toplam: $0/ay** (Free tier limitleri içinde)

## 🔧 Yapılandırma

### Groq Modelleri

```typescript
// src/services/groqService.ts
private model: string = 'llama-3.3-70b-versatile'; // En iyi kalite
// Alternatifler:
// 'llama-3.1-8b-instant' - Daha hızlı, daha az token
// 'mixtral-8x7b-32768' - Uzun context
```

### Rate Limiting

Free tier limitleri:
- 30 istek/dakika
- ~14,400 istek/gün

## 🐛 Sorun Giderme

### "Groq API rate limit exceeded"
- Bekleme süresi ekle veya istekleri sıraya al
- Developer tier'a geçmeyi düşün

### "Firebase connection failed"
- Service account veya credentials kontrol et
- Project ID doğru mu kontrol et

### "Lambda timeout"
- Timeout süresini artır (max 30s önerilir)
- Cold start için provisioned concurrency düşün

## 📝 Lisans

MIT License - Özgürce kullanabilirsin!

## 🤝 Katkıda Bulunma

1. Fork et
2. Feature branch oluştur
3. Commit et
4. PR aç

---

Built with ❤️ for UnderControl App
