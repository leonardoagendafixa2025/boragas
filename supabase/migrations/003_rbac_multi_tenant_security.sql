-- =====================================================================
-- BORAGÁS MARKETPLACE - BANCO DE DADOS SUPABASE
-- Migração 003: RBAC Multi-Tenant, Proteção de Perfis e RLS Rigorosa
-- =====================================================================

-- 1. Adicionar valor 'courier' ao enum user_role se ainda não existir
DO $$ BEGIN
    ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'courier';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Garantir vínculo relacional estrito de courier_id em orders
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_orders_courier_id ON public.orders (courier_id);

-- 3. Trigger de Segurança: Impedir que qualquer usuário altere seu próprio papel (role)
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

-- 4. RLS Rigorosa para ORDERS: Separação de Responsabilidade
DROP POLICY IF EXISTS "Clientes veem apenas seus próprios pedidos" ON public.orders;
DROP POLICY IF EXISTS "Lojas veem apenas seus pedidos" ON public.orders;
DROP POLICY IF EXISTS "Entregadores veem pedidos atribuídos" ON public.orders;
DROP POLICY IF EXISTS "Admins auditam todos os pedidos" ON public.orders;

-- SELECT: Clientes veem os seus, Lojistas veem os da sua loja, Entregadores veem os atribuídos a eles, Admin audita
CREATE POLICY "Controle de Acesso de Leitura a Pedidos por Perfil"
    ON public.orders FOR SELECT
    USING (
        auth.uid() = customer_id OR
        courier_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.stores s 
            WHERE s.id = orders.store_id AND s.owner_id = auth.uid()
        ) OR
        public.is_admin()
    );

-- INSERT: Apenas Clientes autenticados podem criar pedidos
DROP POLICY IF EXISTS "Clientes criam novos pedidos" ON public.orders;
CREATE POLICY "Clientes criam novos pedidos com seu próprio customer_id"
    ON public.orders FOR INSERT
    WITH CHECK (
        auth.uid() = customer_id
    );

-- UPDATE:
-- - Lojistas podem atualizar status (pending -> preparing -> out_for_delivery) e associar entregador da sua loja
-- - Entregadores podem atualizar status (out_for_delivery -> delivered) após PIN
-- - Admin pode auditar e intervir
DROP POLICY IF EXISTS "Lojas atualizam status de seus pedidos" ON public.orders;
CREATE POLICY "Atualização controlada de pedidos por atores autorizados"
    ON public.orders FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.stores s 
            WHERE s.id = orders.store_id AND s.owner_id = auth.uid()
        ) OR
        courier_id = auth.uid() OR
        public.is_admin()
    );

-- 5. RLS Rigorosa para PRODUCTS: Apenas Lojistas donos de suas lojas cadastram ou alteram
DROP POLICY IF EXISTS "Lojistas gerenciam produtos da sua loja" ON public.products;
CREATE POLICY "Lojistas gerenciam produtos da sua loja"
    ON public.products FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.stores s 
            WHERE s.id = products.store_id AND s.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.stores s 
            WHERE s.id = products.store_id AND s.owner_id = auth.uid()
        )
    );

-- 6. Adicionar perfil de Entregador Mock nos Seeds para testes locais/homologação
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES 
  ('a0000000-0000-0000-0000-000000000005', 'entregador@boragas.com', crypt('Entregador@123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Marcos Oliveira Entregador"}', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, role, full_name, phone, avatar_url)
VALUES
  ('a0000000-0000-0000-0000-000000000005', 'courier', 'Marcos Oliveira (Entregador)', '(11) 97722-1199', 'assets/images/app_icon.png')
ON CONFLICT (id) DO UPDATE SET role = 'courier';
