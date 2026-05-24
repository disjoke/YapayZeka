const express = require('express');
const meta = require('../services/meta');
const store = require('../db/store');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const pendingStates = new Map();

router.get('/oauth/meta/config', authMiddleware, (req, res) => {
  res.json({
    configured: !!(process.env.META_APP_ID && process.env.META_APP_SECRET),
    appIdSet: !!process.env.META_APP_ID,
    secretSet: !!process.env.META_APP_SECRET,
    redirectUri: meta.getRedirectUri(),
    appRedirect: process.env.META_APP_REDIRECT || 'ekinciler://oauth/meta',
    steps: [
      'developers.facebook.com → Uygulama oluştur',
      'Ürün ekle: Facebook Login + Instagram Graph API',
      'Geçerli OAuth Redirect URI kaydet (redirectUri alanı)',
      'server/.env dosyasına META_APP_ID ve META_APP_SECRET yaz',
      'Backend\'i yeniden başlat',
      'Instagram: İşletme hesabı + Facebook sayfasına bağlı olmalı',
    ],
  });
});

router.get('/oauth/meta/start', authMiddleware, (req, res) => {
  if (!process.env.META_APP_ID || !process.env.META_APP_SECRET) {
    return res.status(503).json({
      error: 'Meta yapılandırması eksik. server/.env dosyasına META_APP_ID ve META_APP_SECRET ekleyin.',
    });
  }
  const state = `${req.user.id}:${Date.now()}`;
  pendingStates.set(state, req.user.id);
  res.json({ authUrl: meta.getAuthURL(state), redirectUri: meta.getRedirectUri() });
});

router.delete('/oauth/meta', authMiddleware, (req, res) => {
  const social = store.getSocial(req.user.id);
  delete social.meta;
  store.saveSocial(req.user.id, social);
  res.json({ ok: true });
});

router.get('/oauth/meta/callback', async (req, res) => {
  const { code, state, error } = req.query;
  const redirect = process.env.META_APP_REDIRECT || 'ekinciler://oauth/meta';

  if (error) return res.redirect(`${redirect}?error=${encodeURIComponent(error)}`);
  if (!code || !state) return res.redirect(`${redirect}?error=missing_params`);

  const userId = pendingStates.get(state);
  pendingStates.delete(state);
  if (!userId) return res.redirect(`${redirect}?error=invalid_state`);

  try {
    const token = await meta.exchangeCode(code);
    const account = await meta.getInstagramAccount(token);
    const social = store.getSocial(userId);
    social.meta = {
      accessToken: token,
      facebookId: account.facebookId,
      facebookName: account.facebookName,
      pageId: account.pageId,
      pageName: account.pageName,
      instagramId: account.instagramId,
      instagramUsername: account.instagramUsername,
      connectedAt: new Date().toISOString(),
    };
    store.saveSocial(userId, social);
    const userLabel = encodeURIComponent(account.instagramUsername || account.facebookName || 'Baglandi');
    res.redirect(`${redirect}?success=1&platform=meta&username=${userLabel}`);
  } catch (e) {
    res.redirect(`${redirect}?error=${encodeURIComponent(e.message)}`);
  }
});

router.get('/connections', authMiddleware, (req, res) => {
  const social = store.getSocial(req.user.id);
  const platforms = ['Instagram', 'Facebook', 'TikTok', 'LinkedIn', 'WhatsApp', 'YouTube'];
  const connections = platforms.map((p) => {
    const key = p.toLowerCase();
    const hasMeta = !!social.meta?.accessToken;
    if (p === 'Instagram') {
      return {
        platform: p,
        isConnected: hasMeta && !!social.meta.instagramId,
        username: social.meta?.instagramUsername || social.meta?.pageName,
        connectedAt: social.meta?.connectedAt,
      };
    }
    if (p === 'Facebook') {
      return {
        platform: p,
        isConnected: hasMeta,
        username: social.meta?.facebookName || social.meta?.pageName,
        connectedAt: social.meta?.connectedAt,
      };
    }
    return {
      platform: p,
      isConnected: !!social[key]?.accessToken || !!social[key],
      username: social[key]?.username,
      connectedAt: social[key]?.connectedAt,
    };
  });
  res.json(connections);
});

router.post('/publish', authMiddleware, async (req, res) => {
  const { platform, content, imageUrl } = req.body;
  const social = store.getSocial(req.user.id);

  if (platform === 'Instagram' && social.meta?.instagramId) {
    const token = social.meta.accessToken;
    const igId = social.meta.instagramId;
    let creationId;

    if (imageUrl) {
      const containerRes = await fetch(
        `${meta.META_GRAPH}/${igId}/media?image_url=${encodeURIComponent(imageUrl)}&caption=${encodeURIComponent(content)}&access_token=${token}`,
        { method: 'POST' }
      );
      const container = await containerRes.json();
      if (!containerRes.ok) throw new Error(container.error?.message);
      creationId = container.id;
    } else {
      const containerRes = await fetch(
        `${meta.META_GRAPH}/${igId}/media?caption=${encodeURIComponent(content)}&access_token=${token}`,
        { method: 'POST' }
      );
      const container = await containerRes.json();
      creationId = container.id;
    }

    const publishRes = await fetch(
      `${meta.META_GRAPH}/${igId}/media_publish?creation_id=${creationId}&access_token=${token}`,
      { method: 'POST' }
    );
    const published = await publishRes.json();
    if (!publishRes.ok) return res.status(400).json({ error: published.error?.message });
    return res.json({ ok: true, postId: published.id });
  }

  res.json({ ok: true, simulated: true, message: `${platform} paylaşımı simüle edildi` });
});

module.exports = router;
