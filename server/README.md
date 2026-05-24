# Ekinciler AI Backend

Tüm iOS modüllerini destekleyen Node.js API sunucusu.

## Kurulum

```bash
cd server
cp .env.example .env
# .env dosyasına OPENAI_API_KEY ve diğer anahtarları ekleyin
npm install
npm start
```

Sunucu: `http://localhost:3000`

## API Uçları

| Modül | Endpoint |
|--------|----------|
| Giriş | `POST /auth/login`, `POST /auth/register` |
| AI Reklam | `POST /ai/ad-copy`, `/ai/campaign-plan` |
| AI Görsel | `POST /ai/image` |
| AI Video | `POST /ai/video-script`, `/ai/video-generate` |
| İçerik Takvimi | `POST /ai/content-calendar` |
| WhatsApp | `POST /whatsapp/send`, `GET/POST /whatsapp/webhook` |
| Meta OAuth | `GET /social/oauth/meta/start`, `/social/oauth/meta/callback` |
| Paylaşım | `POST /social/publish` |
| Müşteri | `GET/POST/DELETE /customers` |
| Zamanlama | `GET/POST /scheduling` |
| Marka | `GET/PUT /brand` |
| Analitik | `GET /analytics`, `POST /analytics/insight` |

## iOS Bağlantısı

Simülatörde varsayılan URL: `http://127.0.0.1:3000`

Gerçek iPhone'da Mac'inizin yerel IP adresini kullanın (Ayarlar → Backend Sunucu).
