# App Store — Kalıcı Bulut Çözümü

Kullanıcılar **Terminal veya npm kullanmaz**. Tüm iOS kullanıcıları otomatik olarak bulut API'ye bağlanır.

## Mimari

```
[iOS App Store]  ──HTTPS──►  [Bulut API - Render/Railway]
                                ├── OpenAI (sizin anahtarınız)
                                ├── Meta OAuth (Facebook/Instagram)
                                └── Kullanıcı verileri (JWT)
```

## Sizin yapmanız gerekenler (bir kez)

### 1) Backend'i buluta yükleyin

**Render.com (ücretsiz başlangıç):**

1. [render.com](https://render.com) → GitHub ile giriş
2. Repo'yu bağlayın veya `server/` klasörünü deploy edin
3. `render.yaml` dosyası otomatik ayarları kullanır
4. Environment Variables ekleyin:
   - `OPENAI_API_KEY`
   - `META_APP_ID`, `META_APP_SECRET`
   - `META_REDIRECT_URI` = `https://SIZIN-URL.onrender.com/social/oauth/meta/callback`
   - `JWT_SECRET` (güçlü rastgele metin)

5. Deploy URL'nizi alın: örn. `https://ekinciler-api.onrender.com`

### 2) iOS uygulamasında URL güncelleyin

`YapayZeka/Config/AppConfig.swift`:

```swift
static let productionAPIBaseURL = "https://SIZIN-URL.onrender.com"
```

### 3) Meta Developer

Facebook Login → OAuth Redirect URI:
```
https://SIZIN-URL.onrender.com/social/oauth/meta/callback
```

### 4) App Store Connect

- Gizlilik politikası URL (zorunlu)
- Uygulama açıklamasında: Facebook/Instagram OAuth kullanıldığı belirtilmeli
- `ekinciler://` URL scheme Info.plist'te kayıtlı (mevcut)

## Kullanıcı deneyimi (App Store)

1. Uygulamayı indirir
2. Kayıt olur veya giriş yapar (`admin` demo sadece geliştirmede)
3. **Sosyal Medya → Facebook ile Bağlan** (bulut otomatik)
4. OpenAI anahtarı **gerekmez** (sunucuda sizin anahtarınız kullanılır)

## Geliştirme vs App Store

| | DEBUG (Xcode) | RELEASE (App Store) |
|---|---------------|---------------------|
| API | localhost (ayarlanabilir) | `AppConfig.productionAPIBaseURL` |
| Terminal | npm start (geliştirici) | Gerekmez |
| OpenAI | Cihazda veya sunucuda | Sunucuda |

## Ölçeklendirme

- Render ücretsiz: uyku modu (ilk istek yavaş)
- Üretim için: Render Starter veya Railway Pro
- Veritabanı: şu an dosya tabanlı; büyüyünce PostgreSQL ekleyin
