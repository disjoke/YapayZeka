const express = require('express');
const { v4: uuid } = require('uuid');
const openai = require('../services/openai');
const video = require('../services/video');
const store = require('../db/store');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.post('/chat', async (req, res) => {
  try {
    const { system, user, model, temperature } = req.body;
    const text = await openai.chat(
      [{ role: 'system', content: system }, { role: 'user', content: user }],
      { model, temperature }
    );
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/ad-copy', async (req, res) => {
  try {
    const { product, platform, tone } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'Profesyonel Türkçe dijital pazarlama uzmanısın.' },
      { role: 'user', content: `Platform: ${platform}\nTon: ${tone}\nÜrün: ${product}\n\nReklam metni, 3 başlık, 8 hashtag, CTA ve hedef kitle öner.` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/campaign-plan', async (req, res) => {
  try {
    const { budget, audience, goal } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'Meta ve Google Ads kampanya stratejistisin. Türkçe yanıt ver.' },
      { role: 'user', content: `Bütçe: ${budget} TL\nHedef: ${audience}\nAmaç: ${goal}\n\nDetaylı kampanya planı oluştur.` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/image', async (req, res) => {
  try {
    const url = await openai.generateImage(req.body.prompt);
    res.json({ url });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/video-script', async (req, res) => {
  try {
    const { topic, duration, style } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'Reels/TikTok senaristisin. Türkçe sahne sahne senaryo yaz.' },
      { role: 'user', content: `Konu: ${topic}\nSüre: ${duration}\nStil: ${style}` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/video-generate', async (req, res) => {
  try {
    const result = await video.generateVideo(req.body.prompt);
    const history = store.getVideoHistory(req.user.id);
    history.unshift({
      id: uuid(),
      prompt: req.body.prompt,
      ...result,
      createdAt: new Date().toISOString(),
    });
    store.saveVideoHistory(req.user.id, history.slice(0, 30));
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/video-history', authMiddleware, (req, res) => {
  res.json(store.getVideoHistory(req.user.id));
});

router.post('/content-calendar', async (req, res) => {
  try {
    const { brand, weeks } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'Sosyal medya içerik planlayıcısısın. Türkçe haftalık takvim formatında yanıt ver.' },
      { role: 'user', content: `Marka: ${brand}\nSüre: ${weeks} hafta\n\nHer gün platform, tür ve konu başlığı ver.` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/whatsapp-reply', async (req, res) => {
  try {
    const { message, context } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'WhatsApp müşteri temsilcisisin. Kısa, nazik Türkçe yanıtlar yaz.' },
      { role: 'user', content: `İşletme: ${context}\nMüşteri: ${message}` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/competitor-analysis', async (req, res) => {
  try {
    const { industry, competitors } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'Dijital pazarlama analistisin.' },
      { role: 'user', content: `Sektör: ${industry}\nRakipler: ${competitors}\n\nSWOT ve viral fırsatlar sun.` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/voice-ad', async (req, res) => {
  try {
    const { product, voiceStyle } = req.body;
    const text = await openai.chat([
      { role: 'system', content: 'Sesli reklam metin yazarısın.' },
      { role: 'user', content: `Ürün: ${product}\nSes: ${voiceStyle}\n\n30 sn sesli reklam metni yaz.` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/analytics-insight', async (req, res) => {
  try {
    const text = await openai.chat([
      { role: 'system', content: 'Performans pazarlama analistisin. Türkçe özet ve 5 öneri sun.' },
      { role: 'user', content: `Metrikler:\n${req.body.metrics}` },
    ]);
    res.json({ text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
