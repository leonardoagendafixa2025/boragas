-- =====================================================================
-- BORAGÁS MARKETPLACE - SCHEMA CONSOLIDADO COMPLETO (SUPABASE)
-- PostgreSQL + PostGIS + RLS + Triggers + Realtime Broadcast + RPC + Seed
-- Projeto: https://elkelrotleuyszmtkbye.supabase.co
-- =====================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ---------------------------------------------------------------------
-- 1. USERS MOCK NO AUTH (Satisfaz Foreign Keys de Perfis para Teste)
-- ---------------------------------------------------------------------
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES 
  ('a0000000-0000-0000-0000-000000000001', 'admin@boragas.com', crypt('Admin@123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Super Admin BoraGás"}', now(), now()),
  ('a0000000-0000-0000-0000-000000000002', 'loja1@boragas.com', crypt('Loja@123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Gerente Ultragaz"}', now(), now()),
  ('a0000000-0000-0000-0000-000000000003', 'loja2@boragas.com', crypt('Loja@123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Gerente Liquigás"}', now(), now()),
  ('a0000000-0000-0000-0000-000000000004', 'cliente@boragas.com', crypt('Cliente@123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Carlos Eduardo"}', now(), now())
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. PROFILES (Perfis de Usuários)
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'merchant', 'admin', 'courier');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'customer',
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Função de checagem de Admin com SECURITY DEFINER (evita recursão infinita no RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

DROP POLICY IF EXISTS "Perfis visíveis para o próprio usuário e Admins" ON public.profiles;
CREATE POLICY "Perfis visíveis para o próprio usuário e Admins"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios perfis" ON public.profiles;
CREATE POLICY "Usuários podem atualizar seus próprios perfis"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Trigger de Segurança: Somente admin ou service_role pode alterar role
CREATE OR REPLACE FUNCTION public.check_profile_role_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
        IF NOT (public.is_admin() OR auth.role() = 'service_role') THEN
            RAISE EXCEPTION 'Acesso negado: Somente administradores do sistema podem alterar o perfil de acesso (role).';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_protect_profile_role ON public.profiles;
CREATE TRIGGER trg_protect_profile_role
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.check_profile_role_update();

-- ---------------------------------------------------------------------
-- 3. CUSTOMER_ADDRESSES (Endereços Salvos dos Clientes)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT 'Casa',
    street TEXT NOT NULL,
    number TEXT NOT NULL,
    complement TEXT,
    neighborhood TEXT NOT NULL,
    city TEXT NOT NULL,
    state VARCHAR(2) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    lat NUMERIC(10, 7),
    lng NUMERIC(10, 7),
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clientes gerenciam apenas seus próprios endereços" ON public.customer_addresses;
CREATE POLICY "Clientes gerenciam apenas seus próprios endereços"
    ON public.customer_addresses FOR ALL
    USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 4. STORES (Distribuidoras de Gás & Água com Geometria PostGIS)
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE store_status AS ENUM ('pending_approval', 'active', 'suspended_for_non_payment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    logo_url TEXT,
    cover_url TEXT,
    address TEXT NOT NULL,
    lat NUMERIC(10, 7) NOT NULL,
    lng NUMERIC(10, 7) NOT NULL,
    geom geometry(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)) STORED,
    delivery_radius_km NUMERIC(5, 2) NOT NULL DEFAULT 8.00,
    base_delivery_fee NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    estimated_time_min INTEGER NOT NULL DEFAULT 25,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00,
    reviews_count INTEGER NOT NULL DEFAULT 0,
    is_open BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    status store_status NOT NULL DEFAULT 'active',
    commission_rate_percent NUMERIC(5, 2) NOT NULL DEFAULT 8.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_stores_geom ON public.stores USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_stores_status ON public.stores (status);

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lojas ativas são visíveis para qualquer usuário" ON public.stores;
CREATE POLICY "Lojas ativas são visíveis para qualquer usuário"
    ON public.stores FOR SELECT
    USING (status = 'active' OR auth.uid() = owner_id OR public.is_admin());

DROP POLICY IF EXISTS "Donos de loja atualizam suas lojas" ON public.stores;
CREATE POLICY "Donos de loja atualizam suas lojas"
    ON public.stores FOR UPDATE
    USING (auth.uid() = owner_id OR public.is_admin());

-- ---------------------------------------------------------------------
-- 5. STORE_PAYMENT_CONFIGS (BYOK - Bring Your Own Key)
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE gateway_provider AS ENUM ('mercadopago', 'abacatepay');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.store_payment_configs (
    store_id UUID PRIMARY KEY REFERENCES public.stores(id) ON DELETE CASCADE,
    gateway_provider gateway_provider NOT NULL DEFAULT 'mercadopago',
    public_key TEXT,
    access_token_encrypted TEXT,
    webhook_secret TEXT,
    pos_terminal_provider TEXT DEFAULT 'Mercado Pago Point Smart',
    pos_device_serial_id TEXT,
    accepts_online_pix BOOLEAN NOT NULL DEFAULT true,
    accepts_online_card BOOLEAN NOT NULL DEFAULT true,
    accepts_pos_on_delivery BOOLEAN NOT NULL DEFAULT true,
    accepts_cash_on_delivery BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.store_payment_configs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Apenas o dono da loja e Admin leem as chaves de API" ON public.store_payment_configs;
CREATE POLICY "Apenas o dono da loja e Admin leem as chaves de API"
    ON public.store_payment_configs FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND (s.owner_id = auth.uid() OR public.is_admin())
    ));

DROP POLICY IF EXISTS "Dono da loja gerencia suas chaves" ON public.store_payment_configs;
CREATE POLICY "Dono da loja gerencia suas chaves"
    ON public.store_payment_configs FOR ALL
    USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()));

-- ---------------------------------------------------------------------
-- 6. CATALOG_CATEGORIES & HOME_BANNERS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.catalog_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE,
    icon_url TEXT,
    icon_name TEXT DEFAULT 'local_fire_department',
    sort_order INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    filter_type VARCHAR(30) NOT NULL DEFAULT 'product_type',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.catalog_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Categorias visíveis publicamente" ON public.catalog_categories;
CREATE POLICY "Categorias visíveis publicamente"
    ON public.catalog_categories FOR SELECT USING (true);

CREATE TABLE IF NOT EXISTS public.home_banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    badge_text TEXT DEFAULT 'DESTAQUE',
    image_url TEXT NOT NULL,
    action_type VARCHAR(30) NOT NULL DEFAULT 'promo_code',
    action_target_id TEXT,
    sort_order INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.home_banners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Banners ativos visíveis para todos" ON public.home_banners;
CREATE POLICY "Banners ativos visíveis para todos"
    ON public.home_banners FOR SELECT USING (is_active = true);

-- ---------------------------------------------------------------------
-- 7. PRODUCTS (Catálogo de Botijões e Galões)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    category_slug VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    brand_name TEXT,
    description TEXT,
    image_url TEXT,
    refill_price NUMERIC(8, 2) NOT NULL,
    shell_price NUMERIC(8, 2) NOT NULL,
    stock_quantity INTEGER NOT NULL DEFAULT 100,
    is_available BOOLEAN NOT NULL DEFAULT true,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 4.90,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_products_store ON public.products (store_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products (category_slug);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Produtos disponíveis visíveis publicamente" ON public.products;
CREATE POLICY "Produtos disponíveis visíveis publicamente"
    ON public.products FOR SELECT USING (true);

-- ---------------------------------------------------------------------
-- 8. ORDERS & ORDER_ITEMS
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'accepted', 'preparing', 'out_for_delivery', 'delivered', 'cancelled');
    CREATE TYPE payment_mode AS ENUM ('online_store_api', 'pos_machine_push', 'card_on_delivery', 'pix_on_delivery', 'cash_on_delivery');
    CREATE TYPE payment_status AS ENUM ('awaiting_payment', 'paid_directly_to_store', 'failed', 'refunded');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    store_id UUID NOT NULL REFERENCES public.stores(id),
    delivery_address_snapshot JSONB NOT NULL,
    status order_status NOT NULL DEFAULT 'accepted',
    payment_mode payment_mode NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'awaiting_payment',
    external_payment_id TEXT,
    change_for_amount NUMERIC(8, 2),
    subtotal NUMERIC(8, 2) NOT NULL,
    delivery_fee NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    discount NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(8, 2) NOT NULL,
    commission_rate_applied NUMERIC(5, 2) NOT NULL DEFAULT 8.00,
    platform_commission_amount NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    delivery_confirmation_code VARCHAR(6) NOT NULL,
    courier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    courier_name TEXT,
    courier_phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    delivered_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    is_refill_only BOOLEAN NOT NULL DEFAULT true,
    unit_price NUMERIC(8, 2) NOT NULL,
    total_price NUMERIC(8, 2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_store ON public.orders (store_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders (status);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clientes veem apenas seus próprios pedidos" ON public.orders;
CREATE POLICY "Clientes veem apenas seus próprios pedidos"
    ON public.orders FOR SELECT
    USING (auth.uid() = customer_id OR EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ) OR public.is_admin());

DROP POLICY IF EXISTS "Clientes criam novos pedidos" ON public.orders;
CREATE POLICY "Clientes criam novos pedidos"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Lojas atualizam status de seus pedidos" ON public.orders;
CREATE POLICY "Lojas atualizam status de seus pedidos"
    ON public.orders FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ) OR public.is_admin());

DROP POLICY IF EXISTS "Itens de pedidos visíveis para os participantes do pedido" ON public.order_items;
CREATE POLICY "Itens de pedidos visíveis para os participantes do pedido"
    ON public.order_items FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.orders o WHERE o.id = order_id AND (
            o.customer_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.stores s WHERE s.id = o.store_id AND s.owner_id = auth.uid()
            ) OR public.is_admin()
        )
    ));

-- ---------------------------------------------------------------------
-- 9. COMMISSION_LEDGER & COMMISSION_INVOICES (Modelo Zero Mensalidade)
-- ---------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE invoice_status AS ENUM ('open', 'paid', 'overdue');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.commission_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE UNIQUE,
    order_number VARCHAR(20) NOT NULL,
    store_id UUID NOT NULL REFERENCES public.stores(id),
    order_total_amount NUMERIC(8, 2) NOT NULL,
    commission_rate_applied NUMERIC(5, 2) NOT NULL,
    commission_amount NUMERIC(8, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.commission_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES public.stores(id),
    period TEXT NOT NULL,
    total_store_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    commission_percent NUMERIC(5, 2) NOT NULL DEFAULT 8.00,
    total_commission_due NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    due_date DATE NOT NULL,
    status invoice_status NOT NULL DEFAULT 'open',
    pix_copy_paste TEXT,
    payment_proof_url TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.commission_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lojas veem seus próprios registros no Ledger" ON public.commission_ledger;
CREATE POLICY "Lojas veem seus próprios registros no Ledger"
    ON public.commission_ledger FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND (s.owner_id = auth.uid() OR public.is_admin())
    ));

-- ---------------------------------------------------------------------
-- 10. DELIVERY_TRACKING_SESSIONS (Rastreamento GPS & Supabase Realtime)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.delivery_tracking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE UNIQUE,
    courier_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    current_lat NUMERIC(10, 7) NOT NULL,
    current_lng NUMERIC(10, 7) NOT NULL,
    geom geometry(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(current_lng, current_lat), 4326)) STORED,
    bearing NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    speed_kmh NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    accuracy_meters NUMERIC(5, 2) NOT NULL DEFAULT 5.00,
    tracking_status VARCHAR(30) NOT NULL DEFAULT 'out_for_delivery',
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

ALTER TABLE public.delivery_tracking_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clientes visualizam apenas o rastreamento de seus próprios pedidos" ON public.delivery_tracking_sessions;
CREATE POLICY "Clientes visualizam apenas o rastreamento de seus próprios pedidos"
    ON public.delivery_tracking_sessions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = delivery_tracking_sessions.order_id
          AND o.customer_id = auth.uid()
    ));

DROP POLICY IF EXISTS "Entregador atualiza apenas suas entregas ativas" ON public.delivery_tracking_sessions;
CREATE POLICY "Entregador atualiza apenas suas entregas ativas"
    ON public.delivery_tracking_sessions FOR ALL
    USING (courier_id = auth.uid());

-- Realtime publication
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_tracking_sessions;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ---------------------------------------------------------------------
-- 11. RPC: ATUALIZAÇÃO CONTROLADA DE LOCALIZAÇÃO DO ENTREGADOR
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_update_courier_position(
    p_delivery_id TEXT,
    p_courier_id TEXT,
    p_latitude NUMERIC,
    p_longitude NUMERIC,
    p_bearing NUMERIC,
    p_speed_kmh NUMERIC,
    p_status TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_order_uuid UUID;
    v_courier_uuid UUID;
BEGIN
    BEGIN
        v_order_uuid := p_delivery_id::UUID;
        v_courier_uuid := p_courier_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid UUID format');
    END;

    UPDATE public.delivery_tracking_sessions
    SET 
        current_lat = p_latitude,
        current_lng = p_longitude,
        bearing = p_bearing,
        speed_kmh = p_speed_kmh,
        tracking_status = p_status,
        last_ping_at = timezone('utc'::text, now()),
        updated_at = timezone('utc'::text, now())
    WHERE order_id = v_order_uuid AND courier_id = v_courier_uuid;

    RETURN jsonb_build_object('success', true, 'updated_at', timezone('utc'::text, now()));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------------------------------------------------------------------
-- 12. REMOTE_CONFIGS
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.remote_configs (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.remote_configs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Remote config é público para leitura de todos os apps" ON public.remote_configs;
CREATE POLICY "Remote config é público para leitura de todos os apps"
    ON public.remote_configs FOR SELECT USING (true);

-- ---------------------------------------------------------------------
-- 13. SEED DATA (Categorias, Banners, Lojas e Produtos Iniciais)
-- ---------------------------------------------------------------------
INSERT INTO public.catalog_categories (id, title, slug, icon_url, icon_name, sort_order, is_active, filter_type)
VALUES
    ('c1111111-1111-1111-1111-111111111111', 'P13 Residencial', 'p13', NULL, 'gas_cylinder', 1, true, 'product_type'),
    ('c2222222-2222-2222-2222-222222222222', 'Água Mineral 20L', 'water20l', NULL, 'water_drop', 2, true, 'product_type'),
    ('c3333333-3333-3333-3333-333333333333', 'P45 Industrial', 'p45', NULL, 'factory', 3, true, 'product_type'),
    ('c4444444-4444-4444-4444-444444444444', 'P20 Empilhadeira', 'p20', NULL, 'forklift', 4, true, 'product_type'),
    ('c5555555-5555-5555-5555-555555555555', 'Regulador & Mangueira', 'accessories', NULL, 'build_circle', 5, true, 'product_type'),
    ('c6666666-6666-6666-6666-666666666666', 'Menor Preço', 'lowest_price', NULL, 'savings', 6, true, 'promo'),
    ('c7777777-7777-7777-7777-777777777777', 'Entrega Grátis', 'free_delivery', NULL, 'local_shipping', 7, true, 'fast_delivery')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.home_banners (id, title, subtitle, badge_text, image_url, action_type, action_target_id, sort_order, is_active)
VALUES
    ('b1111111-1111-1111-1111-111111111111', 'Cupom de Boas-Vindas!', 'Use BORAGAS10 e ganhe R$ 10 OFF na primeira troca', 'ECONOMIZE HOJE', 'assets/images/brand_lockup.png', 'promo_code', 'BORAGAS10', 1, true),
    ('b2222222-2222-2222-2222-222222222222', 'Entrega Flash em 25 min ⚡', 'Botijões P13 lacrados e testados na sua porta', 'ULTRA RÁPIDO', 'assets/images/app_icon.png', 'open_category', 'p13', 2, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, role, full_name, phone, avatar_url)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'admin', 'Super Administrador BoraGás', '(11) 98888-0001', 'assets/images/app_icon.png'),
    ('a0000000-0000-0000-0000-000000000002', 'merchant', 'Gerente Ultragaz Paulistana', '(11) 98711-2233', 'assets/images/app_icon.png'),
    ('a0000000-0000-0000-0000-000000000003', 'merchant', 'Gerente Liquigás Central', '(11) 97654-3210', 'assets/images/app_icon_v2.png'),
    ('a0000000-0000-0000-0000-000000000004', 'customer', 'Carlos Eduardo Silva', '(11) 98122-3344', 'assets/images/app_icon.png')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.stores (
    id, owner_id, name, cnpj, phone, logo_url, cover_url, address, 
    lat, lng, delivery_radius_km, base_delivery_fee, estimated_time_min, 
    rating, reviews_count, is_open, is_verified, status, commission_rate_percent
) VALUES
    ('e1111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000002', 'Ultragaz Paulistana Express', '12.345.678/0001-90', '(11) 98711-2233', 'assets/images/app_icon.png', 'assets/images/brand_lockup.png', 'Av. Paulista, 1200 - Bela Vista, São Paulo - SP', -23.561414, -46.655881, 10.00, 0.00, 22, 4.90, 384, true, true, 'active', 8.00),
    ('e2222222-2222-2222-2222-222222222222', 'a0000000-0000-0000-0000-000000000003', 'Liquigás Central do Gás', '98.765.432/0001-11', '(11) 97654-3210', 'assets/images/app_icon_v2.png', 'assets/images/brand_lockup.png', 'Rua Augusta, 850 - Consolação, São Paulo - SP', -23.553210, -46.652190, 12.00, 5.00, 28, 4.80, 219, true, true, 'active', 8.00)
ON CONFLICT (cnpj) DO NOTHING;

INSERT INTO public.products (
    id, store_id, category_slug, name, brand_name, description, 
    image_url, refill_price, shell_price, stock_quantity, is_available, rating
) VALUES
    ('d1111111-1111-1111-1111-111111111111', 'e1111111-1111-1111-1111-111111111111', 'p13', 'Botijão de Gás P13 (13kg)', 'Ultragaz (Azul)', 'Botijão de cozinha tradicional com lacre de segurança e pesagem aferida.', 'assets/images/app_icon.png', 104.90, 289.00, 150, true, 4.90),
    ('d2222222-2222-2222-2222-222222222222', 'e1111111-1111-1111-1111-111111111111', 'water20l', 'Água Mineral Galão 20L', 'Bonafont', 'Galão de 20 litros retornável com pH neutro e lacre inviolável.', 'assets/images/app_icon_v2.png', 14.90, 42.00, 80, true, 4.95),
    ('d3333333-3333-3333-3333-333333333333', 'e2222222-2222-2222-2222-222222222222', 'p13', 'Botijão de Gás P13 (13kg)', 'Liquigás (Verde)', 'Botijão residencial com chama azul de alto rendimento.', 'assets/images/app_icon.png', 99.90, 279.00, 120, true, 4.85)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.remote_configs (key, value, description)
VALUES 
    ('header_announcement', '{"text": "⚡ Entrega Turbo ativada em toda a sua região!", "active": true}'::jsonb, 'Banner de comunicado no topo da Home'),
    ('global_commission_default', '{"rate": 8.0}'::jsonb, 'Alíquota de comissão padrão para novos distribuidores'),
    ('maintenance_mode', '{"enabled": false}'::jsonb, 'Trava global para manutenções programadas')
ON CONFLICT (key) DO NOTHING;
