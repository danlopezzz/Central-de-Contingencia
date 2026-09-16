-- ============================================================
-- Migração: ligar o painel ao Meta Pixel
--
-- Você já rodou o supabase-tracking.sql. Este arquivo só ACRESCENTA
-- as colunas que guardam os identificadores do Meta. Rode uma vez no
-- SQL Editor. Pode rodar de novo sem problema: nada é apagado.
-- ============================================================

alter table quiz_eventos add column if not exists fbclid text;  -- id do clique no anúncio
alter table quiz_eventos add column if not exists fbp    text;  -- cookie do navegador, criado pelo Pixel
alter table quiz_eventos add column if not exists fbc    text;  -- cookie do clique, criado pelo Pixel

create index if not exists quiz_eventos_fbclid_idx on quiz_eventos (fbclid);
