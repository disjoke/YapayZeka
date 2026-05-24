const OPENAI = 'https://api.openai.com/v1';

async function chat(messages, { model = 'gpt-4o-mini', temperature = 0.7 } = {}) {
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error('OPENAI_API_KEY sunucuda tanımlı değil');

  const res = await fetch(`${OPENAI}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model, messages, temperature }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'OpenAI hatası');
  return data.choices[0].message.content.trim();
}

async function generateImage(prompt, size = '1024x1024') {
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error('OPENAI_API_KEY sunucuda tanımlı değil');

  const res = await fetch(`${OPENAI}/images/generations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'dall-e-3', prompt, n: 1, size, quality: 'standard',
    }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'DALL-E hatası');
  return data.data[0].url;
}

module.exports = { chat, generateImage };
