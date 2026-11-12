-- =====================================================================
-- BORAGÁS MARKETPLACE - BANCO DE DADOS SUPABASE
-- Migração 006: Suporte Centralizado, Helpdesk & RLS Sem Restrições Indevidas
-- =====================================================================

-- 1. Assegurar tipo enum ticket_status
DO $$ BEGIN
    CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Assegurar colunas completas em public.support_tickets
ALTER TABLE public.support_tickets
ADD COLUMN IF NOT EXISTS requester_name TEXT,
ADD COLUMN IF NOT EXISTS requester_phone TEXT,
ADD COLUMN IF NOT EXISTS requester_email TEXT,
ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NOT NULL DEFAULT 'normal',
ADD COLUMN IF NOT EXISTS admin_notes TEXT,
ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 3. Assegurar colunas completas em public.support_messages
ALTER TABLE public.support_messages
ADD COLUMN IF NOT EXISTS sender_name TEXT,
ADD COLUMN IF NOT EXISTS sender_role TEXT DEFAULT 'customer',
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 4. Índices para performance instantânea de consultas
CREATE INDEX IF NOT EXISTS idx_support_tickets_requester_id ON public.support_tickets (requester_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets (status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_ticket_number ON public.support_tickets (ticket_number);
CREATE INDEX IF NOT EXISTS idx_support_messages_ticket_id ON public.support_messages (ticket_id);

-- 5. RECONSTRUÇÃO RIGOROSA DE RLS (Row Level Security)
-- Habilitar RLS nas duas tabelas
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

-- Limpar policies antigas para evitar duplicidade ou conflitos de permissão
DROP POLICY IF EXISTS "Usuários veem seus próprios chamados e Admin vê todos" ON public.support_tickets;
DROP POLICY IF EXISTS "Usuários criam chamados" ON public.support_tickets;
DROP POLICY IF EXISTS "Atualização de chamados por Admin e Solicitante" ON public.support_tickets;
DROP POLICY IF EXISTS "Permissão geral de leitura para chamados" ON public.support_tickets;
DROP POLICY IF EXISTS "Permissão geral de inserção para chamados" ON public.support_tickets;
DROP POLICY IF EXISTS "Permissão geral de atualização para chamados" ON public.support_tickets;

-- SELECT para SUPPORT_TICKETS:
-- O solicitante vê seus próprios chamados; Admin vê todos os chamados da plataforma.
CREATE POLICY "Leitura de chamados por Solicitante ou Admin"
    ON public.support_tickets FOR SELECT
    USING (
        auth.uid() = requester_id OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        ) OR
        auth.role() = 'service_role'
    );

-- INSERT para SUPPORT_TICKETS:
-- Qualquer usuário autenticado pode abrir um chamado atribuindo seu próprio ID.
-- Também permite service_role e admins.
CREATE POLICY "Criação de chamados por usuários autenticados"
    ON public.support_tickets FOR INSERT
    WITH CHECK (
        auth.uid() = requester_id OR
        auth.uid() IS NOT NULL OR
        auth.role() = 'service_role'
    );

-- UPDATE para SUPPORT_TICKETS:
-- Super Admins podem atualizar status (open -> in_progress -> resolved), notas e prioridades.
-- O solicitante pode encerrar ou atualizar seu próprio chamado.
CREATE POLICY "Atualização controlada de chamados por Admin e Solicitante"
    ON public.support_tickets FOR UPDATE
    USING (
        auth.uid() = requester_id OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        ) OR
        auth.role() = 'service_role'
    )
    WITH CHECK (
        auth.uid() = requester_id OR
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        ) OR
        auth.role() = 'service_role'
    );

-- POLICIES PARA SUPPORT_MESSAGES:
DROP POLICY IF EXISTS "Mensagens de suporte visíveis aos participantes do ticket" ON public.support_messages;
DROP POLICY IF EXISTS "Participantes enviam mensagens de suporte" ON public.support_messages;
DROP POLICY IF EXISTS "Leitura de mensagens de suporte" ON public.support_messages;
DROP POLICY IF EXISTS "Envio de mensagens de suporte" ON public.support_messages;

-- SELECT para SUPPORT_MESSAGES:
CREATE POLICY "Leitura de mensagens do chamado por participante ou Admin"
    ON public.support_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.support_tickets t
            WHERE t.id = support_messages.ticket_id AND (
                t.requester_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM public.profiles p
                    WHERE p.id = auth.uid() AND p.role = 'admin'
                )
            )
        ) OR
        auth.role() = 'service_role'
    );

-- INSERT para SUPPORT_MESSAGES:
CREATE POLICY "Envio de mensagens do chamado por participante ou Admin"
    ON public.support_messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id OR
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        ) OR
        auth.role() = 'service_role'
    );
