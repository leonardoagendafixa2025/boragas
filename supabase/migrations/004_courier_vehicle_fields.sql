-- ==============================================================================
-- BORAGÁS - MIGRAÇÃO 004: DADOS REAIS DE VEÍCULO E PLACA PARA ENTREGADORES
-- ==============================================================================

-- 1. Campos de Veículo e Distribuidora Vinculada na Tabela de Perfis
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS vehicle_model TEXT DEFAULT 'Honda Fan 160',
ADD COLUMN IF NOT EXISTS license_plate TEXT DEFAULT 'BRA-2024',
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE SET NULL;

-- 2. Campos de Snapshot de Veículo e Vinculação na Tabela de Pedidos
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS courier_vehicle_model TEXT DEFAULT 'Honda Fan 160',
ADD COLUMN IF NOT EXISTS courier_license_plate TEXT DEFAULT 'BRA-2024';

-- 3. Atualizar o Entregador Demonstração / Operacional
UPDATE public.profiles
SET vehicle_model = 'Honda Fan 160',
    license_plate = 'BRA-2024'
WHERE role = 'courier';

-- 4. Inserir Perfil Oficial do Entregador caso ainda não exista
INSERT INTO public.profiles (id, role, full_name, phone, vehicle_model, license_plate)
VALUES (
  'a0000000-0000-0000-0000-000000000005',
  'courier',
  'Marcos Oliveira',
  '(11) 97722-1199',
  'Honda Fan 160',
  'BRA-2024'
)
ON CONFLICT (id) DO UPDATE SET 
  vehicle_model = EXCLUDED.vehicle_model,
  license_plate = EXCLUDED.license_plate;
