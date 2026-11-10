-- =====================================================================
-- BORAGÁS MARKETPLACE - BANCO DE DADOS SUPABASE (POSTGRESQL + RLS + POSTGIS)
-- Migração 001: Esquema Inicial, Políticas de RLS, Triggers e Funções RPC
-- =====================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ---------------------------------------------------------------------
-- 1. PROFILES (Perfis de Usuários)
-- ---------------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('customer', 'merchant', 'admin');

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

CREATE POLICY "Perfis visíveis para o próprio usuário e Admins"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Usuários podem atualizar seus próprios perfis"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- ---------------------------------------------------------------------
-- 2. CUSTOMER_ADDRESSES (Endereços Salvos dos Clientes)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT 'Casa', -- 'Casa', 'Trabalho', etc.
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

CREATE POLICY "Clientes gerenciam apenas seus próprios endereços"
    ON public.customer_addresses FOR ALL
    USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 3. STORES (Distribuidoras de Gás & Água)
-- ---------------------------------------------------------------------
CREATE TYPE store_status AS ENUM ('pending_approval', 'active', 'suspended_for_non_payment');

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

CREATE INDEX idx_stores_geom ON public.stores USING GIST (geom);
CREATE INDEX idx_stores_status ON public.stores (status);

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Lojas ativas são públicas para todos os clientes
CREATE POLICY "Lojas ativas são visíveis para qualquer usuário"
    ON public.stores FOR SELECT
    USING (status = 'active' OR auth.uid() = owner_id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- Donos de loja podem editar seus próprios dados operacionais
CREATE POLICY "Donos de loja atualizam suas lojas"
    ON public.stores FOR UPDATE
    USING (auth.uid() = owner_id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- Apenas Super Admin cria ou deleta lojas
CREATE POLICY "Admin tem controle total de lojas"
    ON public.stores FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ---------------------------------------------------------------------
-- 4. STORE_PAYMENT_CONFIGS (BYOK - Bring Your Own Key & Smart POS)
-- ---------------------------------------------------------------------
CREATE TYPE gateway_provider AS ENUM ('mercadopago', 'asaas', 'pagbank', 'stripe');

CREATE TABLE IF NOT EXISTS public.store_payment_configs (
    store_id UUID PRIMARY KEY REFERENCES public.stores(id) ON DELETE CASCADE,
    gateway_provider gateway_provider NOT NULL DEFAULT 'mercadopago',
    public_key TEXT,
    access_token_encrypted TEXT, -- Armazenado com criptografia
    webhook_secret TEXT,
    pos_terminal_provider TEXT DEFAULT 'Mercado Pago Point Smart',
    pos_device_serial_id TEXT, -- ID Serial da Maquininha física
    accepts_online_pix BOOLEAN NOT NULL DEFAULT true,
    accepts_online_card BOOLEAN NOT NULL DEFAULT true,
    accepts_pos_on_delivery BOOLEAN NOT NULL DEFAULT true,
    accepts_cash_on_delivery BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.store_payment_configs ENABLE ROW LEVEL SECURITY;

-- RLS ESTRITO: Apenas o dono da loja e Edge Functions (service_role) podem acessar as chaves
CREATE POLICY "Apenas o dono da loja e Admin leem as chaves de API"
    ON public.store_payment_configs FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND (s.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
        ))
    ));

CREATE POLICY "Dono da loja atualiza suas chaves de API e POS"
    ON public.store_payment_configs FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ));

CREATE POLICY "Dono da loja insere sua configuração de pagamento"
    ON public.store_payment_configs FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ));

-- ---------------------------------------------------------------------
-- 5. CATALOG_CATEGORIES & HOME_MENU_ITEMS (Gerenciados pelo Super Admin)
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

CREATE POLICY "Categorias visíveis publicamente"
    ON public.catalog_categories FOR SELECT USING (true);

CREATE POLICY "Apenas Admin altera categorias"
    ON public.catalog_categories FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ---------------------------------------------------------------------
-- 6. HOME_BANNERS (Carrossel Promocional Gerenciado pelo Super Admin)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.home_banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    badge_text TEXT DEFAULT 'DESTAQUE',
    image_url TEXT NOT NULL,
    action_type VARCHAR(30) NOT NULL DEFAULT 'promo_code', -- 'open_store', 'open_category', 'promo_code', 'external_link'
    action_target_id TEXT,
    sort_order INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.home_banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Banners ativos visíveis para todos"
    ON public.home_banners FOR SELECT
    USING (is_active = true OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Apenas Admin gerencia banners"
    ON public.home_banners FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ---------------------------------------------------------------------
-- 7. PRODUCTS (Catálogo de Botijões, Galões e Acessórios das Lojas)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    category_slug VARCHAR(50) NOT NULL,
    name TEXT NOT NULL,
    brand_name TEXT,
    description TEXT,
    image_url TEXT,
    refill_price NUMERIC(8, 2) NOT NULL, -- Preço Troca (somente recarga/conteúdo)
    shell_price NUMERIC(8, 2) NOT NULL,  -- Preço Casco Completo (sem vasilhame)
    stock_quantity INTEGER NOT NULL DEFAULT 100,
    is_available BOOLEAN NOT NULL DEFAULT true,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 4.90,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX idx_products_store ON public.products (store_id);
CREATE INDEX idx_products_category ON public.products (category_slug);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Produtos disponíveis visíveis publicamente"
    ON public.products FOR SELECT USING (true);

CREATE POLICY "Dono da loja gerencia seus produtos"
    ON public.products FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- ---------------------------------------------------------------------
-- 8. ORDERS & ORDER_ITEMS (Fluxo de Pedidos com Transparência BYOK)
-- ---------------------------------------------------------------------
CREATE TYPE order_status AS ENUM ('pending', 'accepted', 'preparing', 'out_for_delivery', 'delivered', 'cancelled');
CREATE TYPE payment_mode AS ENUM ('online_store_api', 'pos_machine_push', 'card_on_delivery', 'pix_on_delivery', 'cash_on_delivery');
CREATE TYPE payment_status AS ENUM ('awaiting_payment', 'paid_directly_to_store', 'failed', 'refunded');

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    store_id UUID NOT NULL REFERENCES public.stores(id),
    delivery_address_snapshot JSONB NOT NULL,
    status order_status NOT NULL DEFAULT 'accepted',
    payment_mode payment_mode NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'awaiting_payment',
    external_payment_id TEXT, -- ID retornado pela API do Mercado Pago / Gateway da loja
    change_for_amount NUMERIC(8, 2), -- Troco em dinheiro
    subtotal NUMERIC(8, 2) NOT NULL,
    delivery_fee NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    discount NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(8, 2) NOT NULL,
    commission_rate_applied NUMERIC(5, 2) NOT NULL DEFAULT 8.00,
    platform_commission_amount NUMERIC(8, 2) NOT NULL DEFAULT 0.00, -- Calculado via Trigger
    delivery_confirmation_code VARCHAR(6) NOT NULL, -- PIN de 4 dígitos para confirmação segura
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
    is_refill_only BOOLEAN NOT NULL DEFAULT true, -- Troca vs Compra de Casco
    unit_price NUMERIC(8, 2) NOT NULL,
    total_price NUMERIC(8, 2) NOT NULL
);

CREATE INDEX idx_orders_customer ON public.orders (customer_id);
CREATE INDEX idx_orders_store ON public.orders (store_id);
CREATE INDEX idx_orders_status ON public.orders (status);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clientes veem apenas seus próprios pedidos"
    ON public.orders FOR SELECT
    USING (auth.uid() = customer_id OR EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Clientes criam novos pedidos"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Lojas atualizam status de seus pedidos"
    ON public.orders FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.owner_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Itens de pedidos visíveis para os participantes do pedido"
    ON public.order_items FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.orders o WHERE o.id = order_id AND (
            o.customer_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.stores s WHERE s.id = o.store_id AND s.owner_id = auth.uid()
            ) OR EXISTS (
                SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
            )
        )
    ));

CREATE POLICY "Itens podem ser inseridos durante criação do pedido"
    ON public.order_items FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.customer_id = auth.uid()
    ));

-- ---------------------------------------------------------------------
-- 9. COMMISSION_LEDGER & COMMISSION_INVOICES (Modelo Zero Mensalidade)
-- ---------------------------------------------------------------------
CREATE TYPE invoice_status AS ENUM ('open', 'paid', 'overdue');

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
    period TEXT NOT NULL, -- Ex: '01/11 a 07/11'
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

CREATE POLICY "Lojas veem seus próprios registros no Ledger e Faturas"
    ON public.commission_ledger FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND (s.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
        ))
    ));

CREATE POLICY "Lojas veem suas faturas de comissão"
    ON public.commission_invoices FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.stores s WHERE s.id = store_id AND (s.owner_id = auth.uid() OR EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
        ))
    ));

CREATE POLICY "Super Admin tem controle total das faturas e ledger"
    ON public.commission_invoices FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ---------------------------------------------------------------------
-- 10. REMOTE_CONFIGS (Configurações Globais Sincronizadas em Tempo Real)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.remote_configs (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.remote_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Remote config é público para leitura de todos os apps"
    ON public.remote_configs FOR SELECT USING (true);

CREATE POLICY "Apenas Super Admin altera Remote Config"
    ON public.remote_configs FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ---------------------------------------------------------------------
-- 11. SUPPORT_TICKETS & SUPPORT_MESSAGES (Helpdesk em Tempo Real)
-- ---------------------------------------------------------------------
CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved');

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_number VARCHAR(20) NOT NULL UNIQUE,
    requester_id UUID NOT NULL REFERENCES public.profiles(id),
    store_id UUID REFERENCES public.stores(id),
    order_id UUID REFERENCES public.orders(id),
    category TEXT NOT NULL,
    subject TEXT NOT NULL,
    status ticket_status NOT NULL DEFAULT 'open',
    priority VARCHAR(10) NOT NULL DEFAULT 'normal',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    content TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários veem seus próprios chamados e Admin vê todos"
    ON public.support_tickets FOR SELECT
    USING (requester_id = auth.uid() OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Usuários criam chamados"
    ON public.support_tickets FOR INSERT
    WITH CHECK (requester_id = auth.uid());

CREATE POLICY "Mensagens de suporte visíveis aos participantes do ticket"
    ON public.support_messages FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND (
            t.requester_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
            )
        )
    ));

CREATE POLICY "Participantes enviam mensagens de suporte"
    ON public.support_messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- ---------------------------------------------------------------------
-- TRIGGERS E FUNÇÕES AUTOMATIZADAS
-- ---------------------------------------------------------------------

-- Trigger 1: Calcular comissão da plataforma automaticamente na criação do pedido
CREATE OR REPLACE FUNCTION public.fn_calculate_order_commission()
RETURNS TRIGGER AS $$
BEGIN
    -- Busca alíquota atual da loja se não informada
    IF NEW.commission_rate_applied IS NULL OR NEW.commission_rate_applied = 0 THEN
        SELECT commission_rate_percent INTO NEW.commission_rate_applied
        FROM public.stores
        WHERE id = NEW.store_id;
    END IF;

    -- Comissão = total * (aliquota / 100)
    NEW.platform_commission_amount := ROUND((NEW.total_amount * (NEW.commission_rate_applied / 100.0)), 2);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_order_commission
    BEFORE INSERT OR UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_calculate_order_commission();

-- Trigger 2: Inserir no Ledger quando o pedido mudar para 'delivered'
CREATE OR REPLACE FUNCTION public.fn_log_commission_on_delivery()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'delivered' AND (OLD.status IS DISTINCT FROM 'delivered') THEN
        INSERT INTO public.commission_ledger (
            order_id,
            order_number,
            store_id,
            order_total_amount,
            commission_rate_applied,
            commission_amount,
            created_at
        ) VALUES (
            NEW.id,
            NEW.order_number,
            NEW.store_id,
            NEW.total_amount,
            NEW.commission_rate_applied,
            NEW.platform_commission_amount,
            timezone('utc'::text, now())
        )
        ON CONFLICT (order_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_commission_on_delivery
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_log_commission_on_delivery();

-- ---------------------------------------------------------------------
-- FUNÇÃO RPC: BUSCA GEOESPACIAL E COMPARADOR DE PREÇOS
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_nearby_stores_and_products(
    user_lat NUMERIC,
    user_lng NUMERIC,
    category_slug_filter TEXT DEFAULT NULL,
    max_distance_km NUMERIC DEFAULT 15.0
)
RETURNS TABLE (
    product_id UUID,
    product_name TEXT,
    brand_name TEXT,
    category_slug VARCHAR,
    product_image_url TEXT,
    refill_price NUMERIC,
    shell_price NUMERIC,
    store_id UUID,
    store_name TEXT,
    store_logo_url TEXT,
    store_rating NUMERIC,
    store_reviews_count INTEGER,
    store_distance_km NUMERIC,
    store_delivery_fee NUMERIC,
    store_estimated_time_min INTEGER,
    total_effective_price NUMERIC
) AS $$
DECLARE
    user_geom geometry;
BEGIN
    user_geom := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326);

    RETURN QUERY
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        p.brand_name AS brand_name,
        p.category_slug AS category_slug,
        p.image_url AS product_image_url,
        p.refill_price AS refill_price,
        p.shell_price AS shell_price,
        s.id AS store_id,
        s.name AS store_name,
        s.logo_url AS store_logo_url,
        s.rating AS store_rating,
        s.reviews_count AS store_reviews_count,
        ROUND((ST_Distance(s.geom::geography, user_geom::geography) / 1000.0)::numeric, 1) AS store_distance_km,
        s.base_delivery_fee AS store_delivery_fee,
        s.estimated_time_min AS store_estimated_time_min,
        ROUND((p.refill_price + s.base_delivery_fee)::numeric, 2) AS total_effective_price
    FROM public.products p
    JOIN public.stores s ON p.store_id = s.id
    WHERE s.status = 'active'
      AND s.is_open = true
      AND p.is_available = true
      AND ST_DWithin(s.geom::geography, user_geom::geography, (max_distance_km * 1000.0))
      AND (category_slug_filter IS NULL OR category_slug_filter = 'all' OR p.category_slug = category_slug_filter)
    ORDER BY total_effective_price ASC;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- FUNÇÃO CRON: SUSPENSÃO AUTOMÁTICA DE LOJAS POR INADIMPLÊNCIA
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_overdue_invoices_and_suspend_stores()
RETURNS VOID AS $$
BEGIN
    -- Marca faturas vencidas
    UPDATE public.commission_invoices
    SET status = 'overdue'
    WHERE status = 'open' AND due_date < CURRENT_DATE;

    -- Suspende visibilidade das lojas com faturas vencidas há mais de 3 dias
    UPDATE public.stores
    SET status = 'suspended_for_non_payment'
    WHERE id IN (
        SELECT DISTINCT store_id 
        FROM public.commission_invoices 
        WHERE status = 'overdue' AND due_date < (CURRENT_DATE - INTERVAL '3 days')
    ) AND status = 'active';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- INSERÇÃO DE CONFIGURAÇÃO REMOTA INICIAL
-- ---------------------------------------------------------------------
INSERT INTO public.remote_configs (key, value, description)
VALUES 
    ('header_announcement', '{"text": "⚡ Entrega Turbo ativada em toda a sua região!", "active": true}'::jsonb, 'Banner de comunicado no topo da Home'),
    ('global_commission_default', '{"rate": 8.0}'::jsonb, 'Alíquota de comissão padrão para novos distribuidores'),
    ('maintenance_mode', '{"enabled": false}'::jsonb, 'Trava global para manutenções programadas')
ON CONFLICT (key) DO NOTHING;
