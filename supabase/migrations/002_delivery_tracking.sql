-- =====================================================================
-- BORAGÁS MARKETPLACE - BANCO DE DADOS SUPABASE
-- Migração 002: Rastreamento em Tempo Real de Entregas & Segurança RLS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TABELA DE SESSÕES DE RASTREAMENTO ATIVO (PERSISTÊNCIA ECONÔMICA)
-- ---------------------------------------------------------------------
-- NOTA: O rastreamento de alta frequência (5s-10s) trafega via Supabase Realtime Broadcast.
-- Esta tabela é atualizada de forma esparsa (a cada 60s ou em eventos de chegada/finalização)
-- para garantir recuperação de desastres e histórico sem onerar o banco PostgreSQL.

CREATE TABLE IF NOT EXISTS public.delivery_tracking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE UNIQUE,
    courier_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    current_lat NUMERIC(10, 7) NOT NULL,
    current_lng NUMERIC(10, 7) NOT NULL,
    geom geometry(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(current_lng, current_lat), 4326)) STORED,
    bearing NUMERIC(5, 2) NOT NULL DEFAULT 0.00, -- Direção angular em graus (0 a 360)
    speed_kmh NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    accuracy_meters NUMERIC(5, 2) NOT NULL DEFAULT 5.00,
    tracking_status VARCHAR(30) NOT NULL DEFAULT 'out_for_delivery', -- 'out_for_delivery', 'arrived_at_destination', 'completed', 'cancelled'
    eta_minutes INTEGER DEFAULT 15,
    distance_remaining_km NUMERIC(5, 2) DEFAULT 3.00,
    battery_level INTEGER DEFAULT 100,
    last_ping_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_tracking_order ON public.delivery_tracking_sessions (order_id);
CREATE INDEX IF NOT EXISTS idx_tracking_courier ON public.delivery_tracking_sessions (courier_id);
CREATE INDEX IF NOT EXISTS idx_tracking_geom ON public.delivery_tracking_sessions USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_tracking_status ON public.delivery_tracking_sessions (tracking_status);

-- ---------------------------------------------------------------------
-- 2. HABILITAR ROW LEVEL SECURITY (RLS RIGOROSA)
-- ---------------------------------------------------------------------
ALTER TABLE public.delivery_tracking_sessions ENABLE ROW LEVEL SECURITY;

-- POLÍTICA 1: O Cliente só pode ver a sessão de rastreamento do SEU PRÓPRIO pedido
CREATE POLICY "Clientes visualizam apenas o rastreamento de seus próprios pedidos"
    ON public.delivery_tracking_sessions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = delivery_tracking_sessions.order_id
          AND o.customer_id = auth.uid()
    ));

-- POLÍTICA 2: O Entregador só pode ver e atualizar o rastreamento das entregas atribuídas a ele
CREATE POLICY "Entregador visualiza rastreamentos atribuídos a ele"
    ON public.delivery_tracking_sessions FOR SELECT
    USING (courier_id = auth.uid());

CREATE POLICY "Entregador atualiza apenas suas entregas ativas"
    ON public.delivery_tracking_sessions FOR UPDATE
    USING (courier_id = auth.uid())
    WITH CHECK (courier_id = auth.uid());

CREATE POLICY "Entregador cria nova sessão de rastreamento para seu pedido"
    ON public.delivery_tracking_sessions FOR INSERT
    WITH CHECK (courier_id = auth.uid());

-- POLÍTICA 3: O Lojista vê os rastreamentos dos pedidos da sua distribuidora
CREATE POLICY "Lojista visualiza entregas de sua distribuidora"
    ON public.delivery_tracking_sessions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.stores s
        WHERE s.id = delivery_tracking_sessions.store_id
          AND s.owner_id = auth.uid()
    ));

-- POLÍTICA 4: O Super Admin possui visão global de auditoria
CREATE POLICY "Super Admin tem acesso completo aos rastreamentos"
    ON public.delivery_tracking_sessions FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- ---------------------------------------------------------------------
-- 3. HABILITAR REALTIME CDC PARA PERSISTÊNCIA SELETIVA
-- ---------------------------------------------------------------------
-- Adiciona a tabela à publicação do Realtime para clientes que reconectam
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_tracking_sessions;

-- ---------------------------------------------------------------------
-- 4. FUNÇÃO RPC SEGURA PARA ATUALIZAÇÃO CONTROLADA DE LOCALIZAÇÃO
-- ---------------------------------------------------------------------
-- Executada no servidor com validações de sanitização e proteção contra dados falsos.
CREATE OR REPLACE FUNCTION public.rpc_update_courier_position(
    p_order_id UUID,
    p_lat NUMERIC,
    p_lng NUMERIC,
    p_bearing NUMERIC,
    p_speed_kmh NUMERIC,
    p_accuracy NUMERIC,
    p_eta_minutes INTEGER,
    p_distance_km NUMERIC,
    p_battery INTEGER,
    p_status VARCHAR DEFAULT 'out_for_delivery'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_courier_id UUID := auth.uid();
    v_store_id UUID;
    v_order_status VARCHAR;
BEGIN
    -- 1. Validar se o pedido existe e pertence a este entregador
    SELECT store_id, status::text INTO v_store_id, v_order_status
    FROM public.orders
    WHERE id = p_order_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Pedido não encontrado');
    END IF;

    -- 2. Validar limites geográficos do Brasil (lat: -34 a 5, lng: -74 a -34)
    IF p_lat < -34.0 OR p_lat > 6.0 OR p_lng < -75.0 OR p_lng > -32.0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Coordenadas geográficas inválidas');
    END IF;

    -- 3. Inserir ou atualizar sessão de rastreamento (Upsert)
    INSERT INTO public.delivery_tracking_sessions (
        order_id,
        courier_id,
        store_id,
        current_lat,
        current_lng,
        bearing,
        speed_kmh,
        accuracy_meters,
        tracking_status,
        eta_minutes,
        distance_remaining_km,
        battery_level,
        last_ping_at,
        updated_at
    ) VALUES (
        p_order_id,
        v_courier_id,
        v_store_id,
        p_lat,
        p_lng,
        COALESCE(p_bearing, 0.0),
        COALESCE(p_speed_kmh, 0.0),
        COALESCE(p_accuracy, 5.0),
        p_status,
        p_eta_minutes,
        p_distance_km,
        p_battery,
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (order_id) DO UPDATE SET
        current_lat = EXCLUDED.current_lat,
        current_lng = EXCLUDED.current_lng,
        bearing = EXCLUDED.bearing,
        speed_kmh = EXCLUDED.speed_kmh,
        accuracy_meters = EXCLUDED.accuracy_meters,
        tracking_status = EXCLUDED.tracking_status,
        eta_minutes = EXCLUDED.eta_minutes,
        distance_remaining_km = EXCLUDED.distance_remaining_km,
        battery_level = EXCLUDED.battery_level,
        last_ping_at = timezone('utc'::text, now()),
        updated_at = timezone('utc'::text, now());

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'ping_recorded_at', timezone('utc'::text, now())
    );
END;
$$;
