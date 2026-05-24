# Sunucuyu Başlatma (Facebook bağlantısı için)

Ekranda **"Sunucu kapalı"** yazıyorsa aşağıdaki adımları uygulayın.

## 1) Node.js kur (bir kez)

Mac’te Terminal açın:

```bash
brew install node
```

Homebrew yoksa: https://nodejs.org → **LTS İndir** → kur.

Kontrol:
```bash
node -v
npm -v
```

## 2) Sunucuyu başlat

```bash
cd /Users/hakanekinci/YapayZeka/server
npm install
npm start
```

**Bu pencereyi kapatmayın.**

Görmelisiniz: `Ekinciler AI Backend → http://localhost:3000`

## 3) .env dosyasını doldur

`server/.env` içine OpenAI ve Meta anahtarlarınızı yazın.

## 4) Uygulama

- Ayarlar → Backend: `http://127.0.0.1:3000`
- Sosyal Medya → sayfayı yenile → **Facebook / Instagram ile Bağlan**
