# OpenAI anahtarı hâlâ hatalı — Render düzeltme

Hata: `Incorrect API key provided: sk-....`

Bu, Render'da **gerçek anahtar yerine örnek metin** (`sk-....`) kaldığı anlamına gelir.

---

## Adım adım

1. **https://platform.openai.com/api-keys** → **Create new secret key** (eskisini iptal ettiyseniz yeni oluşturun)

2. **https://dashboard.render.com** → **ekinciler-api** → **Environment**

3. **`OPENAI_API_KEY`** satırında:
   - Sağdaki **göz** veya **Edit** ile açın
   - İçinde `sk-....` veya `sk-BURAYA` görüyorsanız → **tamamını silin**
   - Yeni anahtarı **tek parça** yapıştırın (`sk-proj-...` ~ 160+ karakter)
   - Başında/sonunda **boşluk veya tırnak** olmasın

4. **Save Changes** → üstte **Deploying** bitsin → **Live**

5. Tarayıcı testi:
   ```
   https://ekinciler-api.onrender.com/health
   ```
   `"openai": true` olmalı (`false` ise anahtar hâlâ yanlış)

6. iPhone → uygulamayı kapat-aç → **Senaryo Oluştur**

---

## Sık hatalar

| Hata | Çözüm |
|------|--------|
| `sk-....` | Placeholder; gerçek anahtar yapıştırın |
| Anahtar sohbete yazıldı | OpenAI'de iptal + yeni anahtar |
| Save etmeden kapattı | Tekrar Environment → Save |
| Eski deploy | Live olana kadar 2–5 dk bekleyin |

**Anahtarı kimseyle paylaşmayın.**
