-- =====================================================================
-- BORAGÁS MARKETPLACE - BANCO DE DADOS SUPABASE
-- Migração 005: Segurança de Alteração de Senha & Reforço de RLS em Perfis
-- =====================================================================

-- 1. Adicionar coluna password_changed_at em public.profiles para auditoria
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 2. Reforçar RLS Estrita em public.profiles:
--    Apenas o próprio usuário autenticado pode atualizar seu perfil e registrar alteração de credencial.
--    Nenhum usuário pode alterar o perfil ou registrar dados de credencial de terceiros.
DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios perfis" ON public.profiles;

CREATE POLICY "Usuários podem atualizar seus próprios perfis com verificação estrita"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 3. Documentação Arquitetural de Segurança GoTrue Auth & RLS:
--    No ecossistema Supabase, a tabela auth.users armazena senhas criptografadas (bcrypt).
--    O cliente executa 'supabase.auth.updateUser(UserAttributes(password: new_password))'
--    que transmite o Bearer JWT do usuário autenticado para a API do GoTrue.
--    O GoTrue valida automaticamente que auth.uid() coincide com a sessão ativa.
--    A política RLS acima em public.profiles garante que qualquer atualização de metadados
--    (como password_changed_at ou telefone) também seja 100% isolada para o id do usuário logado.

-- 4. Função auxiliar de auditoria segura para registrar alteração de senha
CREATE OR REPLACE FUNCTION public.record_password_change()
RETURNS void AS $$
BEGIN
    UPDATE public.profiles
    SET 
        password_changed_at = timezone('utc'::text, now()),
        updated_at = timezone('utc'::text, now())
    WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.record_password_change() TO authenticated;
