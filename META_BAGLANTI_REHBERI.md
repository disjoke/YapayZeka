# Facebook & Instagram Gerçek Hesap Bağlama Rehberi

## Neden bağlanamıyorum?

Uygulama **simülasyon yapmaz** — gerçek bağlantı için 3 şey şart:

1. **Backend sunucusu** çalışıyor olmalı (`npm start`)
2. **Meta Developer** uygulaması oluşturulmuş olmalı
3. **Instagram İşletme hesabı** bir **Facebook Sayfasına** bağlı olmalı

---

## Adım 1 — Backend'i başlat

```bash
cd server
cp .env.example .env
```

`.env` dosyasını düzenleyin (sonra Adım 2'de alacağınız değerlerle):

```env
META_APP_ID=1234567890123456
META_APP_SECRET=abcdef...
META_REDIRECT_URI=http://127.0.0.1:3000/social/oauth/meta/callback
META_APP_REDIRECT=ekinciler://oauth/meta
```

```bash
npm install
npm start
```

---

## Adım 2 — Meta Developer uygulaması

1. [developers.facebook.com/apps](https://developers.facebook.com/apps/) → **Uygulama Oluştur**
2. Tür: **İşletme** veya **Diğer**
3. **Ürün Ekle:**
   - **Facebook Login**
   - **Instagram Graph API**
4. **Facebook Login → Ayarlar → Geçerli OAuth Yönlendirme URI'leri** bölümüne **tam olarak** ekleyin:

   ```
   http://127.0.0.1:3000/social/oauth/meta/callback
   ```

5. **Uygulama Ayarları → Temel** → **Uygulama Kimliği** = `META_APP_ID`, **Uygulama Gizli Anahtarı** = `META_APP_SECRET`

6. **Roller → Test Kullanıcıları** veya **Geliştirme modunda** kendi Facebook hesabınızı test kullanıcısı olarak ekleyin.

---

## Adım 3 — Instagram hazırlığı

Instagram **kişisel hesap** doğrudan bağlanamaz. Şunlar gerekli:

1. Instagram → **Ayarlar → Hesap → Profesyonel hesaba geç** (İşletme veya İçerik Üreticisi)
2. [facebook.com/pages/create](https://www.facebook.com/pages/create) → bir **Facebook Sayfası** oluşturun
3. Instagram → **Ayarlar → Hesap → Bağlı hesaplar → Facebook** → sayfanızı bağlayın

---

## Adım 4 — iOS uygulaması

| Ortam | Ayarlar → Backend URL |
|--------|------------------------|
| Simülatör | `http://127.0.0.1:3000` |
| Gerçek iPhone | `http://MAC_IP_ADRESINIZ:3000` (ör. `http://192.168.1.10:3000`) |

Mac IP öğrenmek: Terminal → `ipconfig getifaddr en0`

**Gerçek iPhone** kullanıyorsanız `.env` içindeki redirect URI'yi de güncelleyin:

```env
META_REDIRECT_URI=http://192.168.1.10:3000/social/oauth/meta/callback
```

Aynı adresi Meta Developer panelindeki OAuth listesine de ekleyin.

---

## Adım 5 — Bağlan

1. Uygulamada giriş yapın (`admin` / `1234` veya kayıtlı hesap)
2. **Modüller → Sosyal Medya**
3. **Facebook ile Giriş Yap** veya Instagram/Facebook satırında **Bağlan**
4. Facebook'ta giriş yapın ve izinleri onaylayın
5. Uygulamaya dönünce hesap adınız görünmeli

---

## Sık hatalar

| Hata | Çözüm |
|------|--------|
| `META_APP_ID tanımlı değil` | `.env` dosyasını doldurup backend'i yeniden başlatın |
| `Backend aktif olmalı` | Ayarlar'da backend URL + sunucu çalışıyor mu kontrol edin |
| `Instagram İşletme hesabına bağlı değil` | Adım 3'ü tamamlayın |
| `invalid_state` | OAuth'u tekrar deneyin, backend açık kalsın |
| Redirect URI uyuşmuyor | Meta panelindeki URI ile `.env` birebir aynı olmalı |

---

## TikTok, LinkedIn, YouTube?

Bunlar **Meta ile bağlanmaz**. Her biri için ayrı geliştirici hesabı gerekir; uygulamada yakında eklenecek.
