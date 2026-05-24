# App Store — Kalıcı Çözüm (Tek Seferlik Kurulum)

Kullanıcılar **Terminal, npm veya Mac sunucusu kullanmaz**. App Store sürümü otomatik olarak bulut API'ye bağlanır.

## Nasıl çalışır?

| Kim | Ne yapar |
|-----|----------|
| **Siz (geliştirici)** | Backend'i bir kez Render'a yükler, Meta ve OpenAI anahtarlarını girersiniz |
| **App Store kullanıcısı** | Uygulamayı indirir → kayıt olur → Facebook bağlar → AI kullanır |

Release derlemesi (`Archive` → App Store) her zaman şu adrese gider:

`https://ekinciler-api.onrender.com`  
(URL'yi deploy sonrası `YapayZeka/Config/AppConfig.swift` içinde güncelleyin)

---

## Adım 1 — Backend'i Render'a yükleyin (15 dk)

1. [render.com](https://render.com) hesabı açın (GitHub ile giriş önerilir)
2. **New +** → **Web Service**
3. Repo bağlayın veya `server/` klasörünü yükleyin
4. Ayarlar:
   - **Root Directory:** `server`
   - **Runtime:** Docker (veya Node — `Dockerfile` mevcut)
   - **Health Check Path:** `/health`
5. **Environment Variables** ekleyin:

| Değişken | Değer |
|----------|--------|
| `NODE_ENV` | `production` |
| `JWT_SECRET` | Güçlü rastgele metin (32+ karakter) |
| `OPENAI_API_KEY` | `sk-...` |
| `META_APP_ID` | Facebook uygulama ID |
| `META_APP_SECRET` | Facebook gizli anahtar |
| `META_REDIRECT_URI` | `https://SIZIN-SERVIS.onrender.com/social/oauth/meta/callback` |
| `META_APP_REDIRECT` | `ekinciler://oauth/meta` |
| `CORS_ORIGIN` | `*` |

6. **Deploy** → URL alın (ör. `https://ekinciler-api.onrender.com`)
7. Tarayıcıda test: `https://SIZIN-SERVIS.onrender.com/health` → `{"status":"ok",...}` görmelisiniz

> **Not:** `ekinciler-api.onrender.com` şu an boş/404 dönebilir — sizin oluşturduğunuz servisin URL'sini kullanın.

---

## Adım 2 — iOS uygulamasında URL

`YapayZeka/Config/AppConfig.swift`:

```swift
static let productionAPIBaseURL = "https://SIZIN-SERVIS.onrender.com"
```

Xcode → **Product → Archive** → App Store Connect.

---

## Adım 3 — Meta Developer (Facebook / Instagram)

1. [developers.facebook.com](https://developers.facebook.com/apps/)
2. Uygulama → **Facebook Login** → **Valid OAuth Redirect URIs**
3. Ekleyin: `https://SIZIN-SERVIS.onrender.com/social/oauth/meta/callback`
4. Instagram: İşletme/Creator hesap + Facebook Sayfası bağlantısı gerekli

---

## Adım 4 — App Store Connect

- Gizlilik politikası URL (zorunlu)
- Uygulama açıklamasında: Facebook/Instagram OAuth kullanıldığı belirtilmeli
- `ekinciler://` URL scheme zaten kayıtlı

---

## Kullanıcı deneyimi (App Store)

1. Uygulamayı App Store'dan indirir
2. **Kayıt Ol** (veya giriş) — bulut hesabı oluşur
3. **Sosyal Medya → Facebook ile Bağlan** — resmi Facebook sayfası açılır
4. OpenAI anahtarı **gerekmez** (sunucudaki anahtarınız kullanılır)

`admin / 1234` demo hesabı **sadece Xcode DEBUG** derlemesinde çalışır; App Store sürümünde yoktur.

---

## Geliştirme vs App Store

| | Xcode DEBUG | App Store RELEASE |
|---|-------------|-------------------|
| API | localhost (Ayarlar'dan değiştirilebilir) | Bulut HTTPS (sabit) |
| Terminal | `cd server && npm start` | Gerekmez |
| Demo giriş | admin / 1234 | Yok — kayıt zorunlu |

---

## Sorun giderme

| Sorun | Çözüm |
|-------|--------|
| «Bulut sunucuya ulaşılamıyor» | Render servisi uyuyor olabilir; `/health` açın, ilk istek 30–60 sn sürebilir |
| Facebook bağlanmıyor | `META_REDIRECT_URI` Render URL ile birebir aynı mı? |
| Video çalışmıyor | `OPENAI_API_KEY` Render env'de tanımlı mı? |

Detaylı deploy: `APP_STORE_DEPLOY.md`
