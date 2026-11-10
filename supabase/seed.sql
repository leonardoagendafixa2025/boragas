-- =====================================================================
-- BORAGÁS MARKETPLACE - DADOS INICIAIS (SEED DATABASE)
-- Arquivo: supabase/seed.sql
-- =====================================================================

-- 1. Inserir Categorias do Catálogo
INSERT INTO public.catalog_categories (id, title, slug, icon_url, icon_name, sort_order, is_active, filter_type)
VALUES
    ('c1111111-1111-1111-1111-111111111111', 'P13 Residencial', 'p13', NULL, 'gas_cylinder', 1, true, 'product_type'),
    ('c2222222-2222-2222-2222-222222222222', 'Água Mineral 20L', 'water20l', NULL, 'water_drop', 2, true, 'product_type'),
    ('c3333333-3333-3333-3333-333333333333', 'P45 Industrial', 'p45', NULL, 'factory', 3, true, 'product_type'),
    ('c4444444-4444-4444-4444-444444444444', 'P20 Empilhadeira', 'p20', NULL, 'forklift', 4, true, 'product_type'),
    ('c5555555-5555-5555-5555-555555555555', 'Regulador & Mangueira', 'accessories', NULL, 'build_circle', 5, true, 'product_type'),
    ('c6666666-6666-6666-6666-666666666666', 'Menor Preço', 'lowest_price', NULL, 'savings', 6, true, 'promo'),
    ('c7777777-7777-7777-7777-777777777777', 'Entrega Grátis', 'free_delivery', NULL, 'local_shipping', 7, true, 'fast_delivery')
ON CONFLICT (slug) DO UPDATE 
SET title = EXCLUDED.title, icon_name = EXCLUDED.icon_name;

-- 2. Inserir Banners da Home
INSERT INTO public.home_banners (id, title, subtitle, badge_text, image_url, action_type, action_target_id, sort_order, is_active)
VALUES
    ('b1111111-1111-1111-1111-111111111111', 'Cupom de Boas-Vindas!', 'Use BORAGAS10 e ganhe R$ 10 OFF na primeira troca', 'ECONOMIZE HOJE', 'assets/images/brand_lockup.png', 'promo_code', 'BORAGAS10', 1, true),
    ('b2222222-2222-2222-2222-222222222222', 'Entrega Flash em 25 min ⚡', 'Botijões P13 lacrados e testados na sua porta', 'ULTRA RÁPIDO', 'assets/images/app_icon.png', 'open_category', 'p13', 2, true),
    ('b3333333-3333-3333-3333-333333333333', 'Combo Gás + Galão 20L', 'Frete grátis para compras combinadas de água e gás', 'FRETE GRÁTIS', 'assets/images/app_icon_v2.png', 'open_category', 'water20l', 3, true)
ON CONFLICT (id) DO NOTHING;

-- 3. Perfis Administrativos e de Demonstração
-- Super Admin
INSERT INTO public.profiles (id, role, full_name, phone, avatar_url)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'admin', 'Super Administrador BoraGás', '(11) 98888-0001', 'assets/images/app_icon.png'),
    ('a0000000-0000-0000-0000-000000000002', 'merchant', 'Gerente Ultragaz Paulistana', '(11) 98711-2233', 'assets/images/app_icon.png'),
    ('a0000000-0000-0000-0000-000000000003', 'merchant', 'Gerente Liquigás Central', '(11) 97654-3210', 'assets/images/app_icon_v2.png'),
    ('a0000000-0000-0000-0000-000000000004', 'customer', 'Carlos Eduardo Silva', '(11) 98122-3344', 'assets/images/app_icon.png')
ON CONFLICT (id) DO NOTHING;

-- 4. Inserir Lojas Parceiras (Distribuidoras com Geometria PostGIS)
INSERT INTO public.stores (
    id, owner_id, name, cnpj, phone, logo_url, cover_url, address, 
    lat, lng, delivery_radius_km, base_delivery_fee, estimated_time_min, 
    rating, reviews_count, is_open, is_verified, status, commission_rate_percent
) VALUES
    (
        's1111111-1111-1111-1111-111111111111',
        'a0000000-0000-0000-0000-000000000002',
        'Ultragaz Paulistana Express',
        '12.345.678/0001-90',
        '(11) 98711-2233',
        'assets/images/app_icon.png',
        'assets/images/brand_lockup.png',
        'Av. Paulista, 1200 - Bela Vista, São Paulo - SP',
        -23.561414, -46.655881,
        10.00, 0.00, 22, 4.90, 384, true, true, 'active', 8.00
    ),
    (
        's2222222-2222-2222-2222-222222222222',
        'a0000000-0000-0000-0000-000000000003',
        'Liquigás Central do Gás',
        '98.765.432/0001-11',
        '(11) 97654-3210',
        'assets/images/app_icon_v2.png',
        'assets/images/brand_lockup.png',
        'Rua Augusta, 850 - Consolação, São Paulo - SP',
        -23.553210, -46.652190,
        12.00, 5.00, 28, 4.80, 219, true, true, 'active', 8.00
    )
ON CONFLICT (cnpj) DO NOTHING;

-- 5. Configurações de Pagamento das Lojas (BYOK)
INSERT INTO public.store_payment_configs (
    store_id, gateway_provider, public_key, access_token_encrypted, 
    pos_terminal_provider, pos_device_serial_id, accepts_online_pix, 
    accepts_online_card, accepts_pos_on_delivery, accepts_cash_on_delivery
) VALUES
    (
        's1111111-1111-1111-1111-111111111111',
        'mercadopago',
        'APP_USR-782193-mock-key',
        'APP_USR-782193-mock-token-live',
        'Mercado Pago Point Smart',
        'MP-SMART-84920',
        true, true, true, true
    ),
    (
        's2222222-2222-2222-2222-222222222222',
        'asaas',
        'PUB_ASAAS_98213',
        'SEC_ASAAS_TOKEN_LIVE',
        'PagBank Moderninha Smart',
        'PAG-MOD-44120',
        true, true, true, true
    )
ON CONFLICT (store_id) DO NOTHING;

-- 6. Inserir Produtos
INSERT INTO public.products (
    id, store_id, category_slug, name, brand_name, description, 
    image_url, refill_price, shell_price, stock_quantity, is_available, rating
) VALUES
    ('p1111111-1111-1111-1111-111111111111', 's1111111-1111-1111-1111-111111111111', 'p13', 'Botijão de Gás P13 (13kg)', 'Ultragaz (Azul)', 'Botijão de cozinha tradicional com lacre de segurança e pesagem aferida.', 'assets/images/app_icon.png', 104.90, 289.00, 150, true, 4.90),
    ('p2222222-2222-2222-2222-222222222222', 's1111111-1111-1111-1111-111111111111', 'water20l', 'Galão de Água Mineral 20L', 'Lindoya Verão', 'Galão retornável 20 Litros, pH neutro, água leve e pura.', 'assets/images/app_icon_v2.png', 18.00, 42.00, 80, true, 4.90),
    ('p3333333-3333-3333-3333-333333333333', 's1111111-1111-1111-1111-111111111111', 'accessories', 'Kit Regulador de Gás + Mangueira INMETRO', 'Aliança', 'Válvula reguladora 1kg/h com mangueira de 1,25m e abraçadeiras certificadas.', 'assets/images/brand_lockup.png', 65.00, 65.00, 50, true, 4.80),
    ('p4444444-4444-4444-4444-444444444444', 's2222222-2222-2222-2222-222222222222', 'p13', 'Botijão P13 Liquigás (13kg)', 'Liquigás (Verde)', 'Botijão com chama forte e pura, lacre holográfico anti-fraude.', 'assets/images/app_icon.png', 99.90, 279.00, 200, true, 4.80),
    ('p5555555-5555-5555-5555-555555555555', 's2222222-2222-2222-2222-222222222222', 'p45', 'Cilindro Industrial P45 (45kg)', 'Liquigás Industrial', 'Ideal para condomínios, padarias, restaurantes e aquecimento central.', 'assets/images/app_icon_v2.png', 430.00, 890.00, 30, true, 4.80)
ON CONFLICT (id) DO NOTHING;

-- 7. Inserir Faturas de Exemplo no Ledger de Comissões
INSERT INTO public.commission_invoices (
    id, store_id, period, total_store_sales, commission_percent, 
    total_commission_due, due_date, status, pix_copy_paste
) VALUES
    ('i1111111-1111-1111-1111-111111111111', 's1111111-1111-1111-1111-111111111111', '01/11 a 07/11 (Semana 44)', 8940.00, 8.00, 715.20, CURRENT_DATE + INTERVAL '3 days', 'open', '00020126580014br.gov.bcb.pix0136boragas-faturas@plataforma.com5204000053039865406715.205802BR5915BoraGas Admin6009Sao Paulo62070503***6304'),
    ('i2222222-2222-2222-2222-222222222222', 's2222222-2222-2222-2222-222222222222', '25/10 a 31/10 (Semana 43)', 11250.00, 8.00, 900.00, CURRENT_DATE - INTERVAL '2 days', 'paid', 'pix-recibo-pago-892')
ON CONFLICT (id) DO NOTHING;
