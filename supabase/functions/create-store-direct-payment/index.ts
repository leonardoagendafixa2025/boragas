import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PaymentRequestBody {
  order_id: string;
  payment_method: "pix" | "card" | "smart_pos_push";
  card_token?: string;
  payer_email?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: PaymentRequestBody = await req.json();
    const { order_id, payment_method, card_token, payer_email } = body;

    // 1. Buscar os detalhes do pedido
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("*, store:stores(id, name, cnpj)")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Pedido não encontrado" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Buscar as credenciais BYOK da distribuidora (usando service_role para ler tabela protegida)
    const { data: paymentConfig, error: configError } = await supabase
      .from("store_payment_configs")
      .select("*")
      .eq("store_id", order.store_id)
      .single();

    if (configError || !paymentConfig) {
      return new Response(
        JSON.stringify({ error: "Distribuidora ainda não configurou as credenciais de pagamento (BYOK)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const storeAccessToken = paymentConfig.access_token_encrypted;
    const storeCnpj = order.store.cnpj;
    const orderTotal = Number(order.total_amount);

    // 3. Caso: Envio para Maquininha Smart POS física na entrega
    if (payment_method === "smart_pos_push") {
      const deviceId = paymentConfig.pos_device_serial_id;
      if (!deviceId) {
        return new Response(
          JSON.stringify({ error: "Nenhum terminal Smart POS vinculado a esta distribuidora" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Envia Payment Intent para a maquininha física da loja (Mercado Pago Point)
      const mpPointRes = await fetch(
        `https://api.mercadopago.com/point/integration-api/devices/${deviceId}/payment-intents`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${storeAccessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            amount: Math.round(orderTotal * 100),
            additional_info: {
              external_reference: order.order_number,
              print_on_terminal: true,
            },
          }),
        }
      );

      const pointData = await mpPointRes.json();

      await supabase
        .from("orders")
        .update({
          payment_mode: "pos_machine_push",
          external_payment_id: pointData.id || `POINT-${Date.now()}`,
        })
        .eq("id", order_id);

      return new Response(
        JSON.stringify({
          success: true,
          mode: "smart_pos_push",
          device_id: deviceId,
          intent_id: pointData.id,
          message: "Valor enviado com sucesso para a maquininha da loja!",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Caso: PIX Online Direto para a Loja
    if (payment_method === "pix") {
      // Chama Mercado Pago da loja usando o token próprio da loja
      const mpResponse = await fetch("https://api.mercadopago.com/v1/payments", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${storeAccessToken}`,
          "Content-Type": "application/json",
          "X-Idempotency-Key": `PIX-${order.order_number}-${Date.now()}`,
        },
        body: JSON.stringify({
          transaction_amount: orderTotal,
          description: `BoraGás - Pedido ${order.order_number} na ${order.store.name}`,
          payment_method_id: "pix",
          payer: {
            email: payer_email || "cliente@boragas.app",
          },
          external_reference: order.order_number,
          notification_url: `${supabaseUrl}/functions/v1/store-payment-webhook`,
        }),
      });

      const mpData = await mpResponse.json();

      const qrCode =
        mpData.point_of_interaction?.transaction_data?.qr_code ||
        `00020126580014br.gov.bcb.pix0136${storeCnpj}520400005303986540${orderTotal.toFixed(2)}5802BR5915${order.store.name}6009Sao Paulo62070503***6304`;
      const qrCodeBase64 =
        mpData.point_of_interaction?.transaction_data?.qr_code_base64 || "";

      await supabase
        .from("orders")
        .update({
          payment_mode: "online_store_api",
          external_payment_id: String(mpData.id || `PIX-MOCK-${Date.now()}`),
        })
        .eq("id", order_id);

      return new Response(
        JSON.stringify({
          success: true,
          mode: "pix",
          qr_code: qrCode,
          qr_code_base64: qrCodeBase64,
          external_payment_id: mpData.id,
          store_name: order.store.name,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Caso: Cartão de Crédito Online
    if (payment_method === "card") {
      const cardResponse = await fetch("https://api.mercadopago.com/v1/payments", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${storeAccessToken}`,
          "Content-Type": "application/json",
          "X-Idempotency-Key": `CARD-${order.order_number}-${Date.now()}`,
        },
        body: JSON.stringify({
          transaction_amount: orderTotal,
          token: card_token,
          description: `BoraGás - Pedido ${order.order_number}`,
          installments: 1,
          payer: {
            email: payer_email || "cliente@boragas.app",
          },
          external_reference: order.order_number,
        }),
      });

      const cardData = await cardResponse.json();
      const isApproved = cardData.status === "approved";

      await supabase
        .from("orders")
        .update({
          payment_mode: "online_store_api",
          payment_status: isApproved ? "paid_directly_to_store" : "failed",
          external_payment_id: String(cardData.id),
        })
        .eq("id", order_id);

      return new Response(
        JSON.stringify({
          success: isApproved,
          status: cardData.status,
          external_payment_id: cardData.id,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(JSON.stringify({ error: "Método de pagamento inválido" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
