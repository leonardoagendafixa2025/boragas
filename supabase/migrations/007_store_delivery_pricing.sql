-- ==============================================================================
-- MIGRAÇÃO 007: PRECIFICAÇÃO DINÂMICA DE FRETE DECIDIDA PELAS DISTRIBUIDORAS
-- Autonomia total para Lojistas definirem valores por KM, Raio Máx e Bairros
-- ==============================================================================

-- 1. Novos campos de regras de entrega na tabela stores
ALTER TABLE public.stores
    ADD COLUMN IF NOT EXISTS fee_per_km NUMERIC(8, 2) NOT NULL DEFAULT 1.50,
    ADD COLUMN IF NOT EXISTS max_delivery_radius_km NUMERIC(5, 2) NOT NULL DEFAULT 15.00,
    ADD COLUMN IF NOT EXISTS free_delivery_threshold NUMERIC(10, 2) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS neighborhood_fees JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS is_neighborhood_pricing_enabled BOOLEAN NOT NULL DEFAULT true;

-- Comentários descritivos dos campos
COMMENT ON COLUMN public.stores.fee_per_km IS 'Valor adicional cobrado por quilômetro rodado (R$/km)';
COMMENT ON COLUMN public.stores.max_delivery_radius_km IS 'Raio máximo de entrega em quilômetros atendido pela distribuidora';
COMMENT ON COLUMN public.stores.free_delivery_threshold IS 'Valor mínimo de pedido em R$ para isenção total de frete';
COMMENT ON COLUMN public.stores.neighborhood_fees IS 'Mapeamento em JSONB de bairros atendidos com valores fixos de entrega: {"Bairro": 5.00}';
COMMENT ON COLUMN public.stores.is_neighborhood_pricing_enabled IS 'Indica se a precificação prioritária por tabela de bairros está ativa';

-- 2. Habilitação de RLS e Políticas de Segurança Estritas
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Qualquer cliente pode visualizar as regras de frete de lojas ativas para calcular cotação
DROP POLICY IF EXISTS "Qualquer cliente pode consultar dados e fretes de lojas" ON public.stores;
CREATE POLICY "Qualquer cliente pode consultar dados e fretes de lojas"
    ON public.stores FOR SELECT
    USING (status = 'active' OR owner_id = auth.uid());

-- Apenas o lojista proprietário da loja ou Super Admin pode atualizar as taxas de frete
DROP POLICY IF EXISTS "Lojista atualiza regras de frete de sua própria loja" ON public.stores;
CREATE POLICY "Lojista atualiza regras de frete de sua própria loja"
    ON public.stores FOR UPDATE
    TO authenticated
    USING (
        owner_id = auth.uid() OR 
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
    )
    WITH CHECK (
        owner_id = auth.uid() OR 
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
    );
