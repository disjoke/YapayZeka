# Render — 3 adımda deploy (hazır ayarlar)

Kod GitHub'da: **https://github.com/disjoke/YapayZeka**

iOS App Store URL'si hazır: **https://ekinciler-api.onrender.com**

---

## Yöntem A — Blueprint (en kolay, önerilen)

1. [dashboard.render.com](https://dashboard.render.com) → giriş (GitHub)
2. **New +** → **Blueprint**
3. Repo: **`disjoke / YapayZeka`** seçin
4. `render.yaml` otomatik okunur → **Apply**
5. Sadece şunu doldurmanız istenir:
   - **`OPENAI_API_KEY`** → `sk-...` (OpenAI anahtarınız)
   - (İsteğe bağlı) `META_APP_ID`, `META_APP_SECRET` — Facebook için
6. **Deploy** bekleyin (~5–10 dk)
7. Test: **https://ekinciler-api.onrender.com/health**

`JWT_SECRET` ve diğerleri otomatik gelir.

---

## Yöntem B — Manuel Web Service

| Alan | Değer |
|------|--------|
| Repo | `disjoke / YapayZeka` |
| Name | `ekinciler-api` |
| Language | **Node** |
| Root Directory | **`server`** |
| Build | `npm install` |
| Start | `npm start` |
| Plan | Free |

Environment → `deploy/RENDER_ENV_ORNEK.env` dosyasındaki satırları kopyalayın.

---

## Deploy sonrası

1. Tarayıcı: `https://ekinciler-api.onrender.com/health` → `status: ok`
2. Uygulama zaten bu URL'ye ayarlı (`AppConfig.swift`)
3. Meta Developer → OAuth Redirect:
   ```
   https://ekinciler-api.onrender.com/social/oauth/meta/callback
   ```
4. Xcode → **Release** build → App Store

---

## İlk giriş (bulut)

Kayıt ol veya sunucudaki demo:

- Kullanıcı: `admin`
- Parola: `1234`

(App Store Release'te kullanıcılar **Kayıt Ol** kullanır.)

---

## Sorun

| Belirti | Çözüm |
|---------|--------|
| 404 / health yok | Deploy bitmedi veya servis adı farklı — URL'yi Render panelinden kopyalayın, `AppConfig.swift` güncelleyin |
| AI çalışmıyor | Render → Environment → `OPENAI_API_KEY` |
| Facebook | `META_*` değişkenleri + Meta panel redirect URI |
