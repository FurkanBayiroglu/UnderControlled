# 🚀 UnderControl Backend v2 - Deployment Rehberi

## ✅ Bu Versiyon Ne İçeriyor?

- Firebase Service Account ile tam Firestore erişimi
- Gerçek odalar Firestore'dan çekilecek
- AI doğru oda önerileri yapacak

---

## 📦 1. Dosyaları Çıkar

```bash
# ZIP'i aç
unzip undercontrol-backend-v2.zip -d ai-backend
cd ai-backend
```

---

## 🔧 2. Local Test (Önerilen)

```bash
# Bağımlılıkları yükle
npm install

# .env dosyası zaten hazır, kontrol et
cat .env

# Server'ı başlat
npm run dev
```

**Test komutları:**
```bash
# Health check - Firestore bağlantısını gösterir
curl http://localhost:3000/api/health

# Detaylı health (Firestore test eder)
curl http://localhost:3000/api/health/detailed

# Chat başlat
curl -X POST http://localhost:3000/api/chat/start \
  -H "Content-Type: application/json" \
  -d '{"userId": "test123"}'
```

**Beklenen çıktı (Firestore bağlı):**
```json
{
  "status": "ok",
  "services": {
    "firestore": "connected",
    "groq": "configured"
  }
}
```

---

## ☁️ 3. AWS Deploy

### 3.1 Environment Variables Ayarla

**Linux/Mac:**
```bash
# .env dosyasından oku
export $(cat .env | xargs)

# Veya manuel:
export GROQ_API_KEY="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"
export FIREBASE_PROJECT_ID="undercontrolled-f1948"
export FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"undercontrolled-f1948",...}'
```

**Windows PowerShell:**
```powershell
$env:GROQ_API_KEY="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"
$env:FIREBASE_PROJECT_ID="undercontrolled-f1948"
# Service Account için dosyayı oku:
$env:FIREBASE_SERVICE_ACCOUNT = Get-Content -Raw -Path ".env" | Select-String "FIREBASE_SERVICE_ACCOUNT=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }
```

### 3.2 Deploy

```bash
# Build ve deploy
npm run deploy

# Veya staging'e
npm run deploy -- --stage staging
```

### 3.3 Deploy Çıktısı

```
endpoints:
  ANY - https://xxxxxxxxxx.execute-api.eu-central-1.amazonaws.com/dev
```

**Bu URL'yi kopyala!**

---

## 📱 4. Flutter'da URL'yi Güncelle

```dart
// lib/core/services/ai_service.dart
static const String _baseUrl = 'https://YOUR_URL.execute-api.eu-central-1.amazonaws.com/dev';
```

---

## 🔍 5. Test Et

```bash
# AWS'de health check
curl https://YOUR_URL.execute-api.eu-central-1.amazonaws.com/dev/api/health/detailed

# Oda listesi test
curl -X POST https://YOUR_URL.execute-api.eu-central-1.amazonaws.com/dev/api/recommend \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","categories":["gaming","chat"]}'
```

---

## ⚠️ Sorun Giderme

### "Firestore: disconnected"
- FIREBASE_SERVICE_ACCOUNT doğru set edilmedi
- JSON formatı bozuk olabilir

### "Permission denied"
- Service Account'un Firestore erişimi yok
- Firebase Console > IAM > Service Account'a "Cloud Datastore User" rolü ver

### Lambda Timeout
- Timeout'u 30 saniyeye çıkar (serverless.yml'de zaten var)

---

## 🔐 Güvenlik Notu

⚠️ **Service Account JSON'u gizli tutun!**
- `.env` dosyasını git'e commit etmeyin
- `.gitignore`'a ekleyin:
```
.env
*.json
!package.json
!tsconfig.json
```

---

## 📊 Maliyet

| Servis | Free Tier | 
|--------|-----------|
| AWS Lambda | 1M istek/ay ✅ |
| API Gateway | 1M istek/ay ✅ |
| Groq API | 14,400 istek/gün ✅ |
| Firebase | Spark plan ✅ |

**Toplam: $0/ay**
