-- ============================================================
-- Correção de segurança: fechar a escrita na configuração do webhook
--
-- A chave anon aparece no código-fonte do quiz, que é uma página pública.
-- Com a permissão de escrita aberta, qualquer pessoa que lesse esse código
-- poderia apontar o webhook para o próprio servidor e receber os seus leads.
--
-- Rode este arquivo uma vez no SQL Editor, em aba nova.
-- Depois disso o webhook se configura em Table Editor > quiz_config.
-- ============================================================

drop policy if exists quiz_config_leitura   on quiz_config;
drop policy if exists quiz_config_alteracao on quiz_config;

-- confirmação: não deve sobrar nenhuma linha
select policyname from pg_policies where tablename = 'quiz_config';
