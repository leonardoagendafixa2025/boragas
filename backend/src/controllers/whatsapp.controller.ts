import { Request, Response } from 'express';
import { whatsappService } from '../services/whatsapp.service.js';
import { db, getSupabase } from '../services/supabase.service.js';

export async function getWhatsAppStatus(req: Request, res: Response) {
  const status = whatsappService.getStatus();
  return res.json({
    success: true,
    data: status,
  });
}

export async function sendWhatsAppMessage(req: Request, res: Response) {
  const { phone, message } = req.body;

  if (!phone || !message) {
    return res.status(400).json({ error: 'phone e message são obrigatórios' });
  }

  const success = await whatsappService.sendTextMessage(phone, message);

  if (!success) {
    return res.status(503).json({
      error: 'WhatsApp não está conectado ou falhou ao enviar. Verifique o status em /api/v1/whatsapp/status',
    });
  }

  return res.json({ success: true, message: 'Mensagem enviada com sucesso!' });
}

export async function triggerOrderWhatsAppNotification(req: Request, res: Response) {
  const { orderId } = req.body;

  if (!orderId) {
    return res.status(400).json({ error: 'orderId é obrigatório' });
  }

  const order = await db.getOrderById(orderId);
  if (!order) {
    return res.status(404).json({ error: 'Pedido não encontrado' });
  }

  const supabase = getSupabase();
  const { data: items } = await supabase.from('order_items').select('*').eq('order_id', orderId);
  const { data: store } = await supabase.from('stores').select('*').eq('id', order.store_id).maybeSingle();
  const { data: customerProfile } = await supabase.from('profiles').select('*').eq('id', order.customer_id).maybeSingle();

  const itemsSummary = (items || [])
    .map((item) => `• ${item.quantity}x ${item.product_name} - R$ ${Number(item.total_price).toFixed(2)}`)
    .join('\n');

  const customerPhone = customerProfile?.phone || '(11) 98122-3344';
  const customerName = customerProfile?.full_name || 'Cliente';
  const storeName = store?.name || 'Distribuidora BoraGás';
  const addressObj = order.delivery_address_snapshot || {};
  const formattedAddress = `${addressObj.street || ''}, ${addressObj.number || ''} - ${addressObj.neighborhood || ''}, ${addressObj.city || ''}`;

  const success = await whatsappService.notifyOrderCreated({
    customerPhone,
    customerName,
    orderNumber: order.order_number,
    storeName,
    itemsSummary,
    totalAmount: order.total_amount,
    deliveryAddress: formattedAddress,
    confirmationCode: order.delivery_confirmation_code,
    orderId: order.id,
  });

  return res.json({ success, message: success ? 'Notificação enviada!' : 'WhatsApp offline' });
}

export async function reconnectWhatsApp(req: Request, res: Response) {
  await whatsappService.reconnect();
  return res.json({ success: true, message: 'Reinicialização iniciada. Aguarde novo QR Code.' });
}

/**
 * Página Visual HTML interativa para escanear o QR Code no navegador
 */
export async function renderWhatsAppQrView(req: Request, res: Response) {
  const status = whatsappService.getStatus();

  const html = `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BoraGás - Conexão WhatsApp Baileys</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
    body { background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
    .card { background: #1e293b; border-radius: 24px; padding: 36px; max-width: 480px; width: 100%; text-align: center; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); border: 1px solid #334155; }
    .logo { font-size: 28px; font-weight: 800; color: #ff6b00; margin-bottom: 8px; display: flex; align-items: center; justify-content: center; gap: 8px; }
    .subtitle { color: #94a3b8; font-size: 14px; margin-bottom: 24px; }
    .status-badge { display: inline-flex; align-items: center; gap: 8px; padding: 8px 16px; border-radius: 9999px; font-weight: 600; font-size: 14px; margin-bottom: 24px; }
    .status-connected { background: rgba(34, 197, 94, 0.2); color: #4ade80; border: 1px solid #22c55e; }
    .status-qr { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid #f59e0b; }
    .status-connecting { background: rgba(59, 130, 246, 0.2); color: #60a5fa; border: 1px solid #3b82f6; }
    .qr-container { background: #ffffff; padding: 16px; border-radius: 16px; display: inline-block; margin-bottom: 24px; }
    .qr-container img { width: 260px; height: 260px; display: block; }
    .instructions { text-align: left; background: #0f172a; padding: 16px; border-radius: 12px; margin-bottom: 24px; font-size: 13px; color: #cbd5e1; line-height: 1.6; }
    .instructions ol { padding-left: 20px; }
    .btn { background: #ff6b00; color: white; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 700; cursor: pointer; text-decoration: none; display: inline-block; transition: 0.2s; font-size: 14px; }
    .btn:hover { background: #e05e00; }
    .spinner { border: 3px solid rgba(255,255,255,0.1); border-top: 3px solid #ff6b00; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 20px auto; }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
  </style>
  <script>
    // Atualiza a página a cada 3 segundos se estiver aguardando conexão
    setTimeout(() => {
      window.location.reload();
    }, 4000);
  </script>
</head>
<body>
  <div class="card">
    <div class="logo">
      <span>🔥</span> BoraGás WhatsApp
    </div>
    <div class="subtitle">Integração Oficial com Baileys Multi-Device</div>

    ${
      status.status === 'connected'
        ? `
      <div class="status-badge status-connected">
        <span>●</span> Conectado com Sucesso (+${status.connectedPhone})
      </div>
      <p style="color: #cbd5e1; margin-bottom: 24px; font-size: 14px;">
        O bot do BoraGás está ativo e pronto para disparar notificações automáticas de pedidos e entregadores para clientes e distribuidores!
      </p>
      <form action="/api/v1/whatsapp/reconnect" method="POST" style="margin-top: 12px;">
        <button type="submit" class="btn" style="background: #334155;">Desconectar e Gerar Novo QR</button>
      </form>
    `
        : status.status === 'qr_ready' && status.qrCodeBase64
        ? `
      <div class="status-badge status-qr">
        <span>●</span> Escaneie o QR Code Abaixo
      </div>
      <div class="qr-container">
        <img src="${status.qrCodeBase64}" alt="WhatsApp QR Code" />
      </div>
      <div class="instructions">
        <ol>
          <li>Abra o <strong>WhatsApp</strong> no seu celular</li>
          <li>Toque em <strong>Aparelhos Conectados</strong></li>
          <li>Toque em <strong>Conectar um aparelho</strong></li>
          <li>Aponte a câmera para este QR Code</li>
        </ol>
      </div>
    `
        : `
      <div class="status-badge status-connecting">
        <span>●</span> Iniciando Baileys...
      </div>
      <div class="spinner"></div>
      <p style="color: #94a3b8; font-size: 13px;">Gerando credenciais seguras e conectando aos servidores do WhatsApp...</p>
    `
    }
  </div>
</body>
</html>
  `;

  res.setHeader('Content-Type', 'text/html');
  return res.send(html);
}
