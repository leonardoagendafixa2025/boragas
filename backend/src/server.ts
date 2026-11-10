import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config/env.js';
import { apiRouter } from './routes/index.js';
import { healthCheck } from './controllers/health.controller.js';
import { whatsappService } from './services/whatsapp.service.js';

const app = express();

// Segurança e Middlewares essenciais
app.use(helmet());
app.use(
  cors({
    origin: '*', // Em produção pode ser restringido ao config.frontendUrl
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  })
);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

if (config.nodeEnv !== 'test') {
  app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));
}

// Endpoint de Healthcheck Raiz (Render Probe)
app.get('/', (req, res) => {
  res.json({
    service: 'BoraGás Backend API',
    status: 'online',
    portal: config.frontendUrl,
    whatsapp: '/whatsapp',
    docs: '/api/v1/health',
  });
});

app.get('/health', healthCheck);
app.get('/whatsapp', (req, res) => res.redirect('/api/v1/whatsapp/qr'));

// Rotas da API v1
app.use('/api/v1', apiRouter);

// Tratamento de Rota 404
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint não encontrado',
    path: req.originalUrl,
  });
});

// Tratamento Global de Erros
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('[Unhandled Error]', err);
  res.status(err.status || 500).json({
    error: err.message || 'Erro interno no servidor',
  });
});

// Inicialização do Servidor
const server = app.listen(config.port, '0.0.0.0', () => {
  console.log(`🚀 BoraGás Backend rodando na porta ${config.port} [${config.nodeEnv}]`);
  console.log(`🔗 Healthcheck: http://localhost:${config.port}/health`);
  console.log(`📱 WhatsApp QR: http://localhost:${config.port}/whatsapp`);
  console.log(`📡 Conectado ao Supabase: ${config.supabase.url}`);

  // Inicia o socket do Baileys para WhatsApp
  whatsappService.initialize().catch((err) => {
    console.error('Falha ao inicializar Baileys WhatsApp:', err);
  });
});

export { app, server };
