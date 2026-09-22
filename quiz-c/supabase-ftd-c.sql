-- ============================================================
-- Quiz Trading Pro — VARIAÇÃO C — depósitos (FTD)
--
-- Rode DEPOIS do supabase-tracking-c.sql e do supabase-popup-c.sql,
-- no MESMO projeto novo do quiz C. Aba nova no SQL Editor.
--
-- O QUE ISTO FAZ
-- Cria a tabela onde os depósitos entram e a função que o painel usa para
-- ler só os números. O cruzamento com o lead é pelo TELEFONE, que é a chave
-- que o sistema do diretor já usa.
--
-- QUEM ESCREVE AQUI
-- Ninguém pelo navegador. De propósito: se a chave anon pudesse inserir
-- depósito, qualquer pessoa que lesse o HTML do quiz (que é público) poderia
-- inventar FTD e envenenar a sua otimização de campanha.
-- Só entra por: (a) Table Editor logado, ou (b) um servidor usando a chave
-- service_role, que nunca sai do painel do Supabase.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Normalização do telefone
--
-- O mesmo número chega de jeitos diferentes:
--   5511987654321  (com 55)      11987654321  (com o 9)      1187654321  (sem o 9)
-- Todos viram 1187654321 = DDD + os 8 últimos dígitos.
-- ------------------------------------------------------------
create or replace function fone_chave(bruto text)
returns text
language sql
immutable
as $$
  with d as (
    select regexp_replace(coalesce(bruto,''), '\D', '', 'g') as n
  ),
  -- tira zero de prefixo de operadora (021, 015, 0...) — DDD brasileiro
  -- nunca comeca com zero, entao isto e seguro
  z as (select regexp_replace(n, '^0+', '') as n from d),
  -- tira o 55 do pais. So quando sobra mais que um numero nacional,
  -- para nao comer o DDD 55 (Santa Maria)
  s as (select case when length(n) > 11 and left(n,2) = '55'
                    then substring(n from 3) else n end as n from z)
  select case when length(n) between 10 and 11
              then left(n,2) || right(n,8)
              else null end
  from s;
$$;

-- ------------------------------------------------------------
-- 2. A tabela de depósitos
-- ------------------------------------------------------------
create table if not exists quiz_depositos (
  id           bigserial primary key,
  telefone     text        not null,
  valor        numeric(12,2),
  moeda        text        not null default 'BRL',
  tipo         text        not null default 'ftd',   -- ftd | redeposito
  ocorrido_em  timestamptz not null default now(),
  origem       text,                                  -- massflow | broker | manual
  externo_id   text,                                  -- id no sistema de origem
  criado_em    timestamptz not null default now(),

  constraint quiz_depositos_tipo_valido check (tipo in ('ftd','redeposito')),
  constraint quiz_depositos_valor_ok    check (valor is null or valor >= 0)
);

-- Coluna derivada: é por ela que o cruzamento acontece.
--
-- ATENÇÃO: coluna gerada guarda o valor calculado NA INSERÇÃO. Se a função
-- fone_chave mudar, as linhas antigas ficam com o valor velho e param de
-- casar — em silêncio. Por isso a coluna é recriada toda vez que este script
-- roda, o que força o recálculo de tudo. Rodar de novo é sempre seguro.
alter table quiz_depositos drop column if exists fone_norm;
alter table quiz_depositos
  add column fone_norm text generated always as (fone_chave(telefone)) stored;

-- os índices caem junto com a coluna, então são recriados aqui
create index if not exists quiz_depositos_fone_idx     on quiz_depositos (fone_norm);
create index if not exists quiz_depositos_ocorrido_idx on quiz_depositos (ocorrido_em desc);

-- mandar o mesmo depósito duas vezes não duplica
create unique index if not exists quiz_depositos_externo_idx
  on quiz_depositos (origem, externo_id) where externo_id is not null;

-- Índice do lado do lead. Também é recriado: índice por expressão guarda o
-- resultado da função, e o Postgres confia que função immutable não muda.
drop index if exists quiz_leads_fone_norm_idx;
create index quiz_leads_fone_norm_idx on quiz_leads (fone_chave(whatsapp));

alter table quiz_depositos enable row level security;
-- NENHUMA policy: sem elas a RLS nega tudo para anon. É essa ausência que
-- impede alguém de inventar depósito usando a chave que está no HTML.

-- ------------------------------------------------------------
-- 3. Resumo para o painel: só números, nunca telefone nem nome
-- ------------------------------------------------------------
create or replace function quiz_ftd_resumo(desde timestamptz default (now() - interval '7 days'))
returns jsonb
language sql
security definer
set search_path = public
as $$
  with leads as (
    -- um lead por telefone: se a pessoa preencheu duas vezes, vale a primeira
    select distinct on (fone_chave(whatsapp))
           fone_chave(whatsapp) as fone, utm_campaign, criado_em
    from quiz_leads
    where criado_em >= desde and fone_chave(whatsapp) is not null
    order by fone_chave(whatsapp), criado_em asc
  ),
  primeiros as (
    -- o PRIMEIRO deposito de cada telefone, sem limite de data: o lead pode
    -- entrar hoje e depositar semana que vem, e continua sendo lead dessa campanha
    select distinct on (fone_norm) fone_norm, valor, ocorrido_em
    from quiz_depositos
    where tipo = 'ftd'
    order by fone_norm, ocorrido_em asc
  ),
  juncao as (
    select coalesce(l.utm_campaign,'(sem campanha)') as camp,
           (p.fone_norm is not null) as virou,
           p.valor,
           extract(epoch from (p.ocorrido_em - l.criado_em)) as segundos
    from leads l
    left join primeiros p on p.fone_norm = l.fone
  )
  select jsonb_build_object(
    'leads',   (select count(*) from juncao),
    'ftd',     (select count(*) from juncao where virou),
    -- deposito que nao casou com lead nenhum: telefone em formato estranho,
    -- ou cliente que veio de outro lugar. Se este numero subir, a ponte
    -- esta mandando telefone que a gente nao consegue cruzar.
    'ftd_sem_lead', (
      select count(*) from primeiros p
      where not exists (select 1 from leads l where l.fone = p.fone_norm)
    ),
    'receita', coalesce((select sum(valor) from juncao where virou), 0),
    'horas_ate_o_ftd', (
      select round((percentile_cont(0.5) within group (order by segundos) / 3600)::numeric, 1)
      from juncao where virou and segundos > 0
    ),
    'por_campanha', coalesce((
      select jsonb_object_agg(camp, jsonb_build_object('leads', nl, 'ftd', nf, 'receita', rec))
      from (
        select camp,
               count(*)                                        as nl,
               count(*) filter (where virou)                   as nf,
               coalesce(sum(valor) filter (where virou), 0)     as rec
        from juncao group by camp
      ) x
    ), '{}'::jsonb)
  );
$$;

revoke all on function quiz_ftd_resumo(timestamptz) from public;
grant execute on function quiz_ftd_resumo(timestamptz) to anon;

-- ------------------------------------------------------------
-- 4. Conferência
-- ------------------------------------------------------------
-- select quiz_ftd_resumo(now() - interval '30 days');
--
-- Inserir um depósito na mão (Table Editor, ou aqui logado):
-- insert into quiz_depositos (telefone, valor, tipo, ocorrido_em, origem)
-- values ('5511987654321', 250.00, 'ftd', now(), 'manual');
