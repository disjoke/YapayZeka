const REPLICATE = 'https://api.replicate.com/v1';

async function generateVideo(prompt) {
  const token = process.env.REPLICATE_API_TOKEN;
  if (!token) {
    return {
      status: 'simulated',
      message: 'REPLICATE_API_TOKEN tanımlı değil. Senaryo hazır; video render simüle edildi.',
      videoUrl: null,
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
