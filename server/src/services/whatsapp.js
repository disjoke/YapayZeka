const WA_API = 'https://graph.facebook.com/v21.0';

async function sendMessage(to, text) {
  const token = process.env.WHATSAPP_ACCESS_TOKEN;
  const phoneId = process.env.WHATSAPP_PHONE_NUMBER_ID;
  if (!token || !phoneId) {
    throw new Error('WhatsApp API yapılandırması eksik (WHATSAPP_ACCESS_TOKEN, WHATSAPP_PHONE_NUMBER_ID)');
  }

  const res = await fetch(`${WA_API}/${phoneId}/messages`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to: to.replace(/\D/g, ''),
      type: 'text',
      text: { body: text },
    }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'WhatsApp mesajı gönderilemedi');
  return data;
}

module.exports = { sendMessage };
