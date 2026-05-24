# Gerçek AI Video (MP4) — Replicate

**Senaryo** OpenAI ile çalışır (şu an aktif).

**Video Üret** → MP4 dosyası için ek servis: [Replicate](https://replicate.com) (ücretli, kullandıkça öde).

---

## Şu an ne oluyor?

Replicate token yoksa uygulama:
- Senaryoyu kullanır
- **Çekim planı + montaj rehberi** (OpenAI) ekler
- MP4 üretmez (simüle mod)

Bu bir hata değil; senaryo modu çalışıyor.

---

## Gerçek MP4 istiyorsanız

1. [replicate.com](https://replicate.com) → hesap + ödeme yöntemi
2. **Account → API tokens** → token kopyala
3. Render → **ekinciler-api** → **Environment** → ekle:
   ```
   REPLICATE_API_TOKEN = r8_...
   ```
4. **Save** → redeploy
5. Uygulamada **Video Üret** → birkaç dakika sonra **Videoyu Aç** linki

---

## Alternatif

CapCut / Instagram Reels ile senaryo + çekim planını kullanarak kendi videonuzu monte edebilirsiniz.
