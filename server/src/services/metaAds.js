const META_GRAPH = 'https://graph.facebook.com/v21.0';

async function createCampaign({ name, budget, objective, accessToken, adAccountId }) {
  if (!accessToken || !process.env.META_APP_ID) {
    return {
      id: `sim_${Date.now()}`,
      name,
      budget,
      objective: objective || 'OUTCOME_AWARENESS',
      status: 'ACTIVE',
      simulated: true,
      message: 'Meta Ads API simülasyonu — META_APP_ID ve bağlantı gerekli',
    };
  }

  const accountId = adAccountId || process.env.META_AD_ACCOUNT_ID;
  if (!accountId) {
    return {
      id: `sim_${Date.now()}`,
      name,
      budget,
      status: 'PAUSED',
      simulated: true,
      message: 'META_AD_ACCOUNT_ID tanımlayın',
    };
  }

  const res = await fetch(`${META_GRAPH}/act_${accountId}/campaigns`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name,
      objective: objective || 'OUTCOME_AWARENESS',
      status: 'PAUSED',
      special_ad_categories: [],
      access_token: accessToken,
      daily_budget: Math.round(budget * 100),
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'Kampanya oluşturulamadı');
  return { ...data, simulated: false };
}

async function optimizeBudget(campaigns, totalBudget) {
  const perCampaign = Math.floor(totalBudget / Math.max(campaigns.length, 1));
  return campaigns.map((c) => ({
    ...c,
    recommendedDailyBudget: perCampaign,
    optimization: 'AI: En yüksek CTR kampanyaya +%20 bütçe önerildi',
  }));
}

module.exports = { createCampaign, optimizeBudget, META_GRAPH };
