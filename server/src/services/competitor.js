const openai = require('./openai');

async function analyzeCompetitorContent(competitorName, industry, recentPosts) {
  const posts = recentPosts?.length
    ? recentPosts.join('\n')
    : `Örnek içerik: ${competitorName} yeni kampanya, indirim, müşteri yorumları paylaşıyor.`;

  return openai.chat([
    { role: 'system', content: 'Sosyal medya rakip analiz uzmanısın. Türkçe rapor yaz.' },
    {
      role: 'user',
      content: `Rakip: ${competitorName}\nSektör: ${industry}\nSon paylaşımlar:\n${posts}\n\nİçerik stratejisi, paylaşım sıklığı, viral fırsatlar ve önerilen karşı hamleler sun.`,
    },
  ]);
}

async function generateMonitoringReport(competitors, industry) {
  return openai.chat([
    { role: 'system', content: 'Rakip izleme botu raporu oluştur. Türkçe, tablo formatında.' },
    {
      role: 'user',
      content: `Sektör: ${industry}\nİzlenen rakipler: ${competitors.join(', ')}\n\nHaftalık izleme özeti, trend hashtagler ve aksiyon listesi üret.`,
    },
  ]);
}

module.exports = { analyzeCompetitorContent, generateMonitoringReport };
