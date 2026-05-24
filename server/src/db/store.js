const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '../../data');

function ensureDir() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
}

function read(file, fallback) {
  ensureDir();
  const p = path.join(DATA_DIR, file);
  if (!fs.existsSync(p)) return fallback;
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function write(file, data) {
  ensureDir();
  fs.writeFileSync(path.join(DATA_DIR, file), JSON.stringify(data, null, 2));
}

module.exports = {
  getUsers: () => read('users.json', []),
  saveUsers: (u) => write('users.json', u),
  getCustomers: (userId) => read(`customers_${userId}.json`, []),
  saveCustomers: (userId, c) => write(`customers_${userId}.json`, c),
  getPosts: (userId) => read(`posts_${userId}.json`, []),
  savePosts: (userId, p) => write(`posts_${userId}.json`, p),
  getBrand: (userId) => read(`brand_${userId}.json`, {
    companyName: 'Ekinciler',
    tagline: 'Yapay Zeka Destekli Sosyal Medya Yönetimi',
    phone: '', email: '', website: '', address: '', primaryColorHex: '#5A38EB'
  }),
  saveBrand: (userId, b) => write(`brand_${userId}.json`, b),
  getSocial: (userId) => read(`social_${userId}.json`, {}),
  saveSocial: (userId, s) => write(`social_${userId}.json`, s),
  getAnalytics: (userId) => read(`analytics_${userId}.json`, {
    impressions: 128400, clicks: 9820, engagementRate: 4.7,
    adSpend: 24500, conversions: 312, aiInsight: ''
  }),
  saveAnalytics: (userId, a) => write(`analytics_${userId}.json`, a),
  getFuture: (userId) => read(`future_${userId}.json`, {
    videoJobs: [],
    metaCampaigns: [],
    whatsappBot: { enabled: false, welcomeMessage: 'Merhaba! Size nasıl yardımcı olabilirim?', rules: [] },
    competitors: [],
    translations: [],
    platformSync: { ios: true, android: false, web: false, lastSync: null },
  }),
  saveFuture: (userId, data) => write(`future_${userId}.json`, data),
  getVideoHistory: (userId) => read(`video_${userId}.json`, []),
  saveVideoHistory: (userId, v) => write(`video_${userId}.json`, v),
  getMetaCampaigns: (userId) => read(`meta_campaigns_${userId}.json`, []),
  saveMetaCampaigns: (userId, c) => write(`meta_campaigns_${userId}.json`, c),
  getWhatsAppBot: (userId) => read(`wa_bot_${userId}.json`, {
    enabled: false,
    greeting: 'Merhaba! Size nasıl yardımcı olabilirim?',
    businessHours: '09:00 - 18:00',
  }),
  saveWhatsAppBot: (userId, b) => write(`wa_bot_${userId}.json`, b),
  getWhatsAppChats: (userId) => read(`wa_chats_${userId}.json`, []),
  getCompetitors: (userId) => read(`competitors_${userId}.json`, []),
  saveCompetitors: (userId, c) => write(`competitors_${userId}.json`, c),
  getCompetitorScans: (userId) => read(`competitor_scans_${userId}.json`, []),
  saveCompetitorScans: (userId, s) => write(`competitor_scans_${userId}.json`, s),
  getPlatformSync: (userId) => read(`platform_sync_${userId}.json`, {
    autoSync: true, androidEnabled: false, webEnabled: false,
    webUrl: 'https://panel.ekinciler.ai', pendingChanges: 0,
  }),
  savePlatformSync: (userId, s) => write(`platform_sync_${userId}.json`, s),
};
