require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const aiRoutes = require('./routes/ai');
const customerRoutes = require('./routes/customers');
const schedulingRoutes = require('./routes/scheduling');
const brandRoutes = require('./routes/brand');
const analyticsRoutes = require('./routes/analytics');
const socialRoutes = require('./routes/social');
const whatsappRoutes = require('./routes/whatsapp');
const futureRoutes = require('./routes/future');

const app = express();
const PORT = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

if (isProduction) {
  app.set('trust proxy', 1);
}

const corsOrigin = process.env.CORS_ORIGIN || (isProduction ? false : true);
app.use(cors(typeof corsOrigin === 'string' ? { origin: corsOrigin.split(',') } : {}));
app.use(express.json());

app.get('/', (_, res) => {
  res.json({ service: 'Ekinciler AI API', version: '1.0', status: 'ok' });
});

app.get('/health', (_, res) => {
  res.json({
    status: 'ok',
    service: 'Ekinciler AI Backend',
    openai: !!process.env.OPENAI_API_KEY,
    meta: !!process.env.META_APP_ID,
    whatsapp: !!process.env.WHATSAPP_ACCESS_TOKEN,
    replicate: !!process.env.REPLICATE_API_TOKEN,
    futureFeatures: true,
  });
});

app.use('/auth', authRoutes);
app.use('/ai', aiRoutes);
app.use('/customers', customerRoutes);
app.use('/scheduling', schedulingRoutes);
app.use('/brand', brandRoutes);
app.use('/analytics', analyticsRoutes);
app.use('/social', socialRoutes);
app.use('/whatsapp', whatsappRoutes);
app.use('/future', futureRoutes);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Ekinciler AI Backend → http://localhost:${PORT}`);
  console.log(`Health check → http://localhost:${PORT}/health`);
});
