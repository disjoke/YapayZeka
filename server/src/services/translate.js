const openai = require('./openai');

const SUPPORTED_LANGUAGES = [
  { code: 'tr', name: 'Türkçe' },
  { code: 'en', name: 'English' },
  { code: 'de', name: 'Deutsch' },
  { code: 'fr', name: 'Français' },
  { code: 'es', name: 'Español' },
  { code: 'ar', name: 'العربية' },
  { code: 'ru', name: 'Русский' },
  { code: 'it', name: 'Italiano' },
  { code: 'nl', name: 'Nederlands' },
  { code: 'pt', name: 'Português' },
  { code: 'ja', name: '日本語' },
  { code: 'zh', name: '中文' },
];

async function translateContent(text, targetLang, contentType = 'social post') {
  const lang = SUPPORTED_LANGUAGES.find((l) => l.code === targetLang)?.name || targetLang;
  const result = await openai.chat([
    {
      role: 'system',
      content: `Profesyonel çevirmensin. Metni ${lang} diline çevir. Sosyal medya tonunu koru.`,
    },
    { role: 'user', content: `İçerik türü: ${contentType}\n\nMetin:\n${text}` },
  ]);
  return { language: targetLang, languageName: lang, translated: result };
}

async function translateMulti(text, languages, contentType) {
  const results = {};
  for (const lang of languages) {
    const r = await translateContent(text, lang, contentType);
    results[lang] = r.translated;
  }
  return results;
}

module.exports = { SUPPORTED_LANGUAGES, translateContent, translateMulti };
