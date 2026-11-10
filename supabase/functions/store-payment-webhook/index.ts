import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const url = new URL(req.url);
    const topic = url.searchParams.get("topic") || url.searchParams.get("type");
    const id = url.searchParams.get("data.id") || url.searchParams.get("id");

    const payload = await req.json().catch(() => ({}));
    const paymentId = id || payload?.data?.id || payload?.id;

    if (!paymentId) {
      return new Response(JSON.stringify({ received: true, note: "Sem id de pagamento" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Busca o pedido que possui esse external_payment_id ou consulta na loja
    const { data: order, error } = await supabase
      .from("orders")
      .select("id, order_number, store_id, status, payment_status")
      .eq("external_payment_id", String(paymentId))
      .single();

    if (order) {
      // Atualiza status para 'paid_directly_to_store'
      await supabase
        .from("orders")
        .update({
          payment_status: "paid_directly_to_store",
          updated_at: new Date().toISOString(),
        })
        .eq("id", order.id);

      // Dispara evento Realtime no canal público de pedidos
      const channel = supabase.channel(`order-${order.id}`);
      await channel.send({
        type: "broadcast",
        event: "payment_approved",
        payload: {
          order_id: order.id,
          order_number: order.order_number,
          status: "paid_directly_to_store",
        },
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Webhook de pagamento processado com sucesso",
        order_number: order?.order_number,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
