const express = require('express');
const store = require('../db/store');
const openai = require('../services/openai');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.get('/', (req, res) => {
  res.json(store.getAnalytics(req.user.id));
});

router.post('/insight', async (req, res) => {
  try {
    const snapshot = store.getAnalytics(req.user.id);
    const metrics = `Gösterim: ${snapshot.impressions}\nTıklama: ${snapshot.clicks}\nEtkileşim: %${snapshot.engagementRate}\nHarcama: ${snapshot.adSpend} TL\nDönüşüm: ${snapshot.conversions}`;
    const text = await openai.chat([
      { role: 'system', content: 'Performans analistisin. Türkçe özet ve 5 öneri sun.' },
      { role: 'user', content: metrics },
    ]);
    snapshot.aiInsight = text;
    store.saveAnalytics(req.user.id, snapshot);
    res.json({ text, snapshot });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
