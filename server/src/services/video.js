const REPLICATE = 'https://api.replicate.com/v1';
const openai = require('./openai');

async function buildProductionPlan(prompt) {
  try {
    return await openai.chat([
      {
        role: 'system',
        content:
          'Profesyonel video yapımcısısın. Türkçe, kısa ve uygulanabilir çekim planı yaz.',
      },
      {
        role: 'user',
        content: `Senaryo:\n${prompt}\n\nVer: 1) Sahne sahne çekim 2) Metin/alıtyazı 3) Müzik tonu 4) 15 sn Reels montaj notları`,
      },
    ]);
  } catch {
    return null;
  }
}

async function generateVideo(prompt) {
  const token = process.env.REPLICATE_API_TOKEN;
  if (!token) {
    const plan = await buildProductionPlan(prompt);
    return {
      status: 'simulated',
      message:
        'Gerçek video dosyası (MP4) için Replicate gerekir. Şimdilik AI çekim planı ve montaj rehberi oluşturuldu.',
      videoUrl: null,
      productionPlan: plan,
    };
  }

  const res = await fetch(`${REPLICATE}/predictions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Prefer: 'wait',
    },
    body: JSON.stringify({
      version: 'minimax/video-01-live',
      input: { prompt, prompt_optimizer: true },
    }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.detail || 'Video üretim hatası');

  return {
    status: data.status,
    videoUrl: data.output || null,
    message: 'Video üretildi',
  };
}

module.exports = { generateVideo };
