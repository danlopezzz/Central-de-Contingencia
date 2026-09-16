-- ============================================================
-- Ativar o webhook
--
-- ANTES DE RODAR:
--   1. Habilite a extensão pg_net no painel do Supabase, em
--      Database > Extensions (busque por "pg_net" e ligue a chave)
--   2. Troque a URL na linha marcada abaixo
--
-- Depois é só rodar este arquivo inteiro, em uma aba nova do SQL Editor.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Para onde mandar, e quando
-- ------------------------------------------------------------
update quiz_config
   set webhook_url    = 'COLE_A_SUA_URL_AQUI',   -- <<<<<< TROQUE ESTA LINHA
       webhook_quando = 'resultado',             -- 'resultado' | 'tudo' | 'nunca'
       atualizado_em  = now()
 where id = 1;


-- ------------------------------------------------------------
-- 2. Ligar o gatilho
-- ------------------------------------------------------------
drop trigger if exists quiz_eventos_webhook on quiz_eventos;

create trigger quiz_eventos_webhook
  after insert on quiz_eventos
  for each row execute function quiz_disparar_webhook();


-- ------------------------------------------------------------
-- 3. Conferência: deve mostrar a sua URL e 'resultado'
-- ------------------------------------------------------------
select webhook_url, webhook_quando, atualizado_em from quiz_config where id = 1;
