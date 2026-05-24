const express = require('express');
const { v4: uuid } = require('uuid');
const store = require('../db/store');
const openai = require('../services/openai');
const video = require('../services/video');
const metaAds = require('../services/metaAds');
const competitor = require('../services/competitor');
const translate = require('../services/translate');
const whatsapp = require('../services/whatsapp');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Durum özeti
router.get('/status', authMiddleware, (req, res) => {
  res.json({
    videoRender: { active: true, replicate: !!process.env.REPLICATE_API_TOKEN },
    metaAds: { active: true, configured: !!process.env.META_APP_ID },
    whatsappBot: { active: true, configured: !!process.env.WHATSAPP_ACCESS_TOKEN },
    multiLanguage: { active: true, languages: translate.SUPPORTED_LANGUAGES.length },
    competitorBot: { active: true },
    crossPlatform: {
      ios: { active: true, version: '1.0' },
      android: { active: false, eta: 'Beta Q4 2026', progress: 35 },
      web: { active: false, eta: 'Beta Q2 2026', progress: 60 },
    },
  });
});

// 1. Video Render
router.post('/video/render', authMiddleware, async (req, res) => {
  try {
    const { prompt, style } = req.body;
    const fullPrompt = style ? `${prompt}. Stil: ${style}` : prompt;
    const result = await video.generateVideo(fullPrompt);
    const history = store.getVideoHistory(req.user.id);
    history.unshift({ id: uuid(), prompt: fullPrompt, ...result, createdAt: new Date().toISOString() });
    store.saveVideoHistory(req.user.id, history.slice(0, 20));
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/video/history', authMiddleware, (req, res) => {
  res.json(store.getVideoHistory(req.user.id));
});

// 2. Meta Ads API
router.get('/meta-ads/campaigns', authMiddleware, (req, res) => {
  res.json(store.getMetaCampaigns(req.user.id));
});

router.post('/meta-ads/campaigns', authMiddleware, async (req, res) => {
  try {
    const { name, budget, objective } = req.body;
    const social = store.getSocial(req.user.id);
    const token = social.meta?.accessToken;
    const created = await metaAds.createCampaign({
      name, budget: Number(budget), objective, accessToken: token,
    });
    const campaigns = store.getMetaCampaigns(req.user.id);
    const entry = {
      id: created.id || uuid(),
      name,
      budget: Number(budget),
      objective: objective || 'OUTCOME_AWARENESS',
      status: created.status || 'ACTIVE',
      simulated: created.simulated || false,
      message: created.message,
      createdAt: new Date().toISOString(),
    };
    campaigns.unshift(entry);
    store.saveMetaCampaigns(req.user.id, campaigns);
    res.status(201).json(entry);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/meta-ads/optimize', authMiddleware, async (req, res) => {
  try {
    const { totalBudget } = req.body;
    const campaigns = store.getMetaCampaigns(req.user.id);
    const optimized = await metaAds.optimizeBudget(campaigns, Number(totalBudget));
    const aiPlan = await openai.chat([
      { role: 'system', content: 'Meta Ads bütçe optimizasyon uzmanısın.' },
      { role: 'user', content: `Toplam bütçe: ${totalBudget} TL\nKampanyalar: ${JSON.stringify(campaigns)}\n\nOptimizasyon planı yaz.` },
    ]);
    store.saveMetaCampaigns(req.user.id, optimized);
    res.json({ campaigns: optimized, aiPlan });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 3. WhatsApp Bot
router.get('/whatsapp/bot-config', authMiddleware, (req, res) => {
  res.json(store.getWhatsAppBot(req.user.id));
});

router.put('/whatsapp/bot-config', authMiddleware, (req, res) => {
  store.saveWhatsAppBot(req.user.id, req.body);
  res.json(req.body);
});

router.post('/whatsapp/auto-reply', authMiddleware, async (req, res) => {
  try {
    const { enabled, greeting, businessHours } = req.body;
    const config = { enabled, greeting, businessHours, updatedAt: new Date().toISOString() };
    store.saveWhatsAppBot(req.user.id, config);

    if (req.body.testPhone && req.body.testMessage) {
      const reply = await openai.chat([
        { role: 'system', content: `WhatsApp bot. Karşılama: ${greeting}. Çalışma saatleri: ${businessHours}` },
        { role: 'user', content: req.body.testMessage },
      ]);
      try {
        await whatsapp.sendMessage(req.body.testPhone, reply);
        return res.json({ config, testReply: reply, sent: true });
      } catch {
        return res.json({ config, testReply: reply, sent: false, note: 'WhatsApp API yapılandırması gerekli' });
      }
    }
    res.json({ config, message: 'Bot yapılandırması kaydedildi' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/whatsapp/conversations', authMiddleware, (req, res) => {
  res.json(store.getWhatsAppChats(req.user.id));
});

// 4. Çoklu Dil
router.get('/languages', authMiddleware, (_, res) => {
  res.json(translate.SUPPORTED_LANGUAGES);
});

router.post('/translate', authMiddleware, async (req, res) => {
  try {
    const { text, targetLang, contentType, multiLang } = req.body;
    if (multiLang?.length) {
      const results = await translate.translateMulti(text, multiLang, contentType);
      return res.json({ translations: results });
    }
    const result = await translate.translateContent(text, targetLang, contentType);
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 5. Rakip Takip Botu
router.get('/competitors', authMiddleware, (req, res) => {
  res.json(store.getCompetitors(req.user.id));
});

router.post('/competitors', authMiddleware, (req, res) => {
  const list = store.getCompetitors(req.user.id);
  const entry = {
    id: uuid(),
    name: req.body.name,
    platform: req.body.platform || 'Instagram',
    handle: req.body.handle || '',
    industry: req.body.industry || '',
    addedAt: new Date().toISOString(),
  };
  list.push(entry);
  store.saveCompetitors(req.user.id, list);
  res.status(201).json(entry);
});

router.delete('/competitors/:id', authMiddleware, (req, res) => {
  const list = store.getCompetitors(req.user.id).filter((c) => c.id !== req.params.id);
  store.saveCompetitors(req.user.id, list);
  res.json({ ok: true });
});

router.post('/competitors/scan', authMiddleware, async (req, res) => {
  try {
    const list = store.getCompetitors(req.user.id);
    const industry = req.body.industry || Brand_default(req.user.id);
    const names = list.map((c) => c.name);
    const report = await competitor.generateMonitoringReport(names, industry);
    const scans = store.getCompetitorScans(req.user.id);
    scans.unshift({ id: uuid(), report, scannedAt: new Date().toISOString(), competitorCount: list.length });
    store.saveCompetitorScans(req.user.id, scans.slice(0, 10));
    res.json({ report, competitors: list });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/competitors/:id/analyze', authMiddleware, async (req, res) => {
  try {
    const list = store.getCompetitors(req.user.id);
    const comp = list.find((c) => c.id === req.params.id);
    if (!comp) return res.status(404).json({ error: 'Rakip bulunamadı' });
    const report = await competitor.analyzeCompetitorContent(
      comp.name, comp.industry || req.body.industry, req.body.recentPosts
    );
    res.json({ competitor: comp, report });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

function Brand_default(userId) {
  return store.getBrand(userId).companyName || 'Genel';
}

// 6. Çapraz Platform
router.get('/platforms', authMiddleware, (req, res) => {
  const sync = store.getPlatformSync(req.user.id);
  res.json({
    ios: { active: true, version: '1.0.0', lastSync: sync.iosLastSync || new Date().toISOString() },
    android: { active: sync.androidEnabled, progress: 35, eta: 'Q4 2026', downloadUrl: null },
    web: { active: sync.webEnabled, progress: 60, eta: 'Q2 2026', url: sync.webUrl || 'https://panel.ekinciler.ai' },
    syncEnabled: sync.autoSync,
    pendingChanges: sync.pendingChanges || 0,
  });
});

router.post('/platforms/sync', authMiddleware, (req, res) => {
  const sync = store.getPlatformSync(req.user.id);
  sync.iosLastSync = new Date().toISOString();
  sync.pendingChanges = 0;
  sync.lastSyncMessage = 'Tüm veriler iOS, Web ve Android arasında senkronize edildi (simülasyon).';
  store.savePlatformSync(req.user.id, sync);
  res.json(sync);
});

router.put('/platforms/settings', authMiddleware, (req, res) => {
  const sync = { ...store.getPlatformSync(req.user.id), ...req.body };
  store.savePlatformSync(req.user.id, sync);
  res.json(sync);
});

module.exports = router;
