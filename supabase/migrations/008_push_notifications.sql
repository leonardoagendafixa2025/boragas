-- ==============================================================================
-- MIGRAÇÃO 008: CENTRAL DE NOTIFICAÇÕES PUSH NATIVAS & PWA COM ONESIGNAL
-- Suporte a disparos transacionais de pedidos e campanhas de marketing em massa
-- ==============================================================================

-- 1. Tabela de Dispositivos e Subscrições Push (Android e PWA)
CREATE TABLE IF NOT EXISTS public.user_push_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    player_id TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'web_pwa', 'ios')),
    device_info JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_platform UNIQUE(user_id, platform)
);

CREATE INDEX IF NOT EXISTS idx_user_push_devices_user ON public.user_push_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_push_devices_platform ON public.user_push_devices(platform);

-- 2. Tabela de Histórico de Campanhas de Marketing Disparadas pelo Super Admin
CREATE TABLE IF NOT EXISTS public.push_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    coupon_code TEXT,
    target_audience TEXT NOT NULL DEFAULT 'all',
    recipients_count INTEGER NOT NULL DEFAULT 0,
    onesignal_id TEXT,
    status TEXT NOT NULL DEFAULT 'sent',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_push_campaigns_created ON public.push_campaigns(created_at DESC);

-- 3. Segurança e Políticas de RLS
ALTER TABLE public.user_push_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_campaigns ENABLE ROW LEVEL SECURITY;

-- Usuários gerenciam apenas seus próprios dispositivos
DROP POLICY IF EXISTS "Usuários gerenciam seus próprios dispositivos push" ON public.user_push_devices;
CREATE POLICY "Usuários gerenciam seus próprios dispositivos push"
    ON public.user_push_devices FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Apenas Super Admin pode consultar e disparar campanhas de marketing
DROP POLICY IF EXISTS "Apenas Super Admin gerencia campanhas push" ON public.push_campaigns;
CREATE POLICY "Apenas Super Admin gerencia campanhas push"
    ON public.push_campaigns FOR ALL
    TO authenticated
    USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
    WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');
