# App Store — Kalıcı Bulut Çözümü

**Kullanıcılar Terminal/npm kullanmaz.** Release derlemesi otomatik: `https://ekinciler-api.onrender.com`

---

## Sizin yapmanız gereken (tek sefer, ~10 dk)

### 1. Render deploy

Detaylı: **`RENDER_TEK_TIK.md`**

Kısa yol:

1. [dashboard.render.com](https://dashboard.render.com) → **New +** → **Blueprint**
2. Repo: **`disjoke / YapayZeka`**
3. **`OPENAI_API_KEY`** girin (`sk-...`)
4. Deploy bitince test: https://ekinciler-api.onrender.com/health

### 2. Meta (Facebook) — isteğe bağlı

[developers.facebook.com](https://developers.facebook.com/apps/) → OAuth Redirect:

```
https://ekinciler-api.onrender.com/social/oauth/meta/callback
```

Render Environment'a `META_APP_ID` ve `META_APP_SECRET` ekleyin.

### 3. App Store

- iOS URL hazır: `YapayZeka/Config/AppConfig.swift`
- Xcode → **Product → Archive**
- Gizlilik politikası URL gerekli

---

## Kullanıcı deneyimi

1. App Store'dan indir
2. Kayıt ol / giriş
3. Sosyal Medya → Facebook ile Bağlan
4. OpenAI anahtarı gerekmez (sunucuda)

---

## Geliştirme vs App Store

| | DEBUG (Xcode) | RELEASE (App Store) |
|---|---------------|---------------------|
| API | localhost | `ekinciler-api.onrender.com` |
| Terminal | `cd server && npm start` | Yok |
| Demo | admin / 1234 | Kayıt zorunlu |

---

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `render.yaml` | Render Blueprint (otomatik ayar) |
| `RENDER_TEK_TIK.md` | Adım adım Render |
| `deploy/RENDER_ENV_ORNEK.env` | Ortam değişkenleri şablonu |
