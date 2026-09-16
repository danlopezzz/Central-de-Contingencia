-- ============================================================
-- Desligar o webhook
-- Rode isto se precisar parar os disparos por qualquer motivo.
-- Nada é perdido: os eventos continuam sendo gravados normalmente.
-- ============================================================

drop trigger if exists quiz_eventos_webhook on quiz_eventos;

update quiz_config set webhook_quando = 'nunca', atualizado_em = now() where id = 1;

select webhook_url, webhook_quando from quiz_config where id = 1;
