-- ============================================================
-- Quiz Trading Pro — QUIZ A — popup de captura
--
-- Rode DEPOIS do supabase-tracking.sql, no MESMO projeto do
-- quiz A (hdfkpepapdakqqbtekqw (o projeto do quiz A)). Aba nova no SQL Editor.
--
-- Dois lugares, de propósito:
--   quiz_leads   -> nome e WhatsApp (dado pessoal). Anon só ESCREVE.
--   quiz_eventos -> o evento 'lead', sem dado pessoal. Anon lê e escreve.
--
-- Por que separado: a chave anon fica visível no HTML do quiz, que é
-- público. Se ela pudesse LER quiz_leads, qualquer pessoa que abrisse o
-- código-fonte baixaria a lista de nomes e telefones dos seus leads.
-- Escrevendo mas não lendo, o popup grava e ninguém de fora tira nada.
-- Para ver os leads, use o Table Editor do Supabase, logado.
-- ============================================================

-- ------------------------------------------------------------
-- 1. LEADS: uma linha por popup preenchido
-- ------------------------------------------------------------
create table if not exists quiz_leads (
  id           bigserial primary key,
  sessao       text        not null,     -- mesma sessão do quiz_eventos
  nome         text        not null,
  whatsapp     text        not null,     -- só dígitos, com DDD
  fbclid       text,
  fbp          text,
  fbc          text,
  utm_source   text,
  utm_medium   text,
  utm_campaign text,
  utm_content  text,
  utm_term     text,
  dispositivo  text,
  referencia   text,
  criado_em    timestamptz not null default now(),

  constraint quiz_leads_nome_tam   check (char_length(nome) between 2 and 120),
  constraint quiz_leads_wpp_tam    check (char_length(whatsapp) between 10 and 11),
  constraint quiz_leads_wpp_digito check (whatsapp ~ '^[0-9]+$'),
  constraint quiz_leads_sessao_tam check (char_length(sessao) between 8 and 64)
);

create index if not exists quiz_leads_criado_idx   on quiz_leads (criado_em desc);
create index if not exists quiz_leads_sessao_idx   on quiz_leads (sessao);
create index if not exists quiz_leads_campanha_idx on quiz_leads (utm_campaign);
create index if not exists quiz_leads_wpp_idx      on quiz_leads (whatsapp);

alter table quiz_leads enable row level security;

-- ANON SÓ INSERE. Nenhuma policy de select, update ou delete: sem elas,
-- a RLS nega tudo. É essa ausência que protege os telefones.
drop policy if exists "anon grava lead" on quiz_leads;
create policy "anon grava lead"
  on quiz_leads for insert to anon
  with check (
    char_length(nome) between 2 and 120
    and whatsapp ~ '^[0-9]{10,11}$'
    and true
  );

-- ------------------------------------------------------------
-- 2. O evento 'lead' no funil (sem dado pessoal)
-- ------------------------------------------------------------
alter table quiz_eventos drop constraint if exists quiz_eventos_evento_valido;
alter table quiz_eventos add  constraint quiz_eventos_evento_valido check (evento in
  ('visualizou','lead','iniciou','respondeu','analisando','resultado','clicou_cta','saiu'));

-- ------------------------------------------------------------
-- 3. Resumo para o painel: só números, nunca nome ou telefone
-- ------------------------------------------------------------
create or replace function quiz_leads_resumo(desde timestamptz default (now() - interval '7 days'))
returns jsonb
language sql
security definer
set search_path = public
as $$
  with base as (
    select * from quiz_leads where criado_em >= desde
  )
  select jsonb_build_object(
    'total', (select count(*) from base),
    'por_dia', coalesce((
      select jsonb_object_agg(dia, n) from (
        select to_char(criado_em at time zone 'America/Sao_Paulo','YYYY-MM-DD') as dia,
               count(*) as n
        from base group by 1
      ) d
    ), '{}'::jsonb),
    'por_campanha', coalesce((
      select jsonb_object_agg(campanha, n) from (
        select coalesce(utm_campaign,'(sem campanha)') as campanha, count(*) as n
        from base group by 1
      ) c
    ), '{}'::jsonb)
  );
$$;

revoke all on function quiz_leads_resumo(timestamptz) from public;
grant execute on function quiz_leads_resumo(timestamptz) to anon;

-- ------------------------------------------------------------
-- Conferência
-- ------------------------------------------------------------
-- select * from quiz_leads order by criado_em desc limit 20;   -- aqui, logado
-- select quiz_leads_resumo(now() - interval '7 days');         -- o que o painel vê
