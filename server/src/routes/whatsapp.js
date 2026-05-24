const express = require('express');
const whatsapp = require('../services/whatsapp');
const openai = require('../services/openai');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];
  if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
    return res.status(200).send(challenge);
  }
  res.sendStatus(403);
});

router.post('/webhook', async (req, res) => {
  res.sendStatus(200);
  try {
    const entry = req.body.entry?.[0];
    const change = entry?.changes?.[0];
    const message = change?.value?.messages?.[0];
    if (!message?.text?.body) return;

    const from = message.from;
    const text = message.text.body;
    const reply = await openai.chat([
      { role: 'system', content: 'WhatsApp müşteri temsilcisisin. Kısa Türkçe yanıt ver.' },
      { role: 'user', content: text },
    ]);
    await whatsapp.sendMessage(from, reply);
  } catch (e) {
    console.error('WhatsApp webhook:', e.message);
  }
});

router.post('/send', authMiddleware, async (req, res) => {
  try {
    const { to, message, autoReply } = req.body;
    let text = message;

    if (autoReply && req.body.customerMessage) {
      text = await openai.chat([
        { role: 'system', content: 'WhatsApp müşteri temsilcisisin.' },
        { role: 'user', content: `İşletme: ${req.body.context || ''}\nMüşteri: ${req.body.customerMessage}` },
      ]);
    }

    const result = await whatsapp.sendMessage(to, text);
    res.json({ ok: true, messageId: result.messages?.[0]?.id, text });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
