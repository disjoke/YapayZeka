const META_AUTH = 'https://www.facebook.com/v21.0/dialog/oauth';
const META_TOKEN = 'https://graph.facebook.com/v21.0/oauth/access_token';
const META_GRAPH = 'https://graph.facebook.com/v21.0';

function getRedirectUri() {
  return process.env.META_REDIRECT_URI || 'http://127.0.0.1:3000/social/oauth/meta/callback';
}

function getAuthURL(state) {
  const params = new URLSearchParams({
    client_id: process.env.META_APP_ID,
    redirect_uri: getRedirectUri(),
    state,
    scope: [
      'public_profile',
      'email',
      'pages_show_list',
      'pages_read_engagement',
      'pages_manage_posts',
      'instagram_basic',
      'instagram_content_publish',
      'business_management',
    ].join(','),
    response_type: 'code',
  });
  return `${META_AUTH}?${params}`;
}

async function exchangeCode(code) {
  const params = new URLSearchParams({
    client_id: process.env.META_APP_ID,
    client_secret: process.env.META_APP_SECRET,
    redirect_uri: getRedirectUri(),
    code,
  });
  const res = await fetch(`${META_TOKEN}?${params}`);
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'Token alınamadı');
  return data.access_token;
}

async function getFacebookProfile(accessToken) {
  const res = await fetch(
    `${META_GRAPH}/me?fields=id,name,email&access_token=${accessToken}`
  );
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'Facebook profili alınamadı');
  return data;
}

async function getInstagramAccount(accessToken) {
  const profile = await getFacebookProfile(accessToken);

  const res = await fetch(
    `${META_GRAPH}/me/accounts?fields=id,name,instagram_business_account{id,username}&access_token=${accessToken}`
  );
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'Facebook sayfaları alınamadı');

  const pages = data.data || [];
  const pageWithIG = pages.find((p) => p.instagram_business_account?.id);
  const firstPage = pages[0];

  if (!pages.length) {
    throw new Error(
      'Facebook sayfanız yok. facebook.com/pages/create adresinden bir İşletme Sayfası oluşturun ve tekrar deneyin.'
    );
  }

  if (!pageWithIG) {
    throw new Error(
      `Facebook sayfanız (${firstPage?.name || 'Sayfa'}) Instagram İşletme hesabına bağlı değil. ` +
      'Instagram uygulaması → Ayarlar → Hesap → Bağlı hesaplar → Facebook sayfanızı bağlayın. ' +
      'Hesabınız İşletme veya İçerik Üreticisi olmalıdır.'
    );
  }

  const ig = pageWithIG.instagram_business_account;
  return {
    facebookId: profile.id,
    facebookName: profile.name,
    pageId: pageWithIG.id,
    pageName: pageWithIG.name,
    instagramId: ig.id,
    instagramUsername: ig.username ? `@${ig.username}` : null,
    accessToken,
  };
}

module.exports = { getAuthURL, exchangeCode, getInstagramAccount, getRedirectUri, META_GRAPH };
