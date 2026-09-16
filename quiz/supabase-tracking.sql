-- ============================================================
-- Quiz Trading Pro — rastreamento
-- Rode isto no SQL Editor de um projeto Supabase NOVO.
-- Não reaproveite o projeto da Central de Contingência.
-- ============================================================

-- ------------------------------------------------------------
-- 1. EVENTOS: uma linha por passo que a pessoa dá no quiz
-- ------------------------------------------------------------
create table if not exists quiz_eventos (
  id           bigserial primary key,
  sessao       text        not null,          -- id anônimo, gerado no navegador
  evento       text        not null,          -- ver a lista abaixo
  passo        smallint,                      -- 1 a 5, quando evento = 'respondeu'
  pergunta     text,                          -- identificador da pergunta
  valor        text,                          -- valor da alternativa escolhida
  rotulo       text,                          -- texto da alternativa, para leitura humana
  trilha       text,                          -- perfil definido na pergunta 1
  perfil       text,                          -- nome do perfil no resultado
  score        smallint,
  destino      text,                          -- whats | comunidade
  tempo_ms     integer,                       -- tempo gasto naquele passo
  utm_source   text,
  utm_medium   text,
  utm_campaign text,
  utm_content  text,
  utm_term     text,
  dispositivo  text,                          -- celular | tablet | computador
  referencia   text,                          -- de onde a pessoa veio
  criado_em    timestamptz not null default now(),

  constraint quiz_eventos_evento_valido check (evento in
    ('visualizou','iniciou','respondeu','analisando','resultado','clicou_cta','saiu')),
  constraint quiz_eventos_sessao_tam check (char_length(sessao) between 8 and 64)
);

create index if not exists quiz_eventos_criado_idx   on quiz_eventos (criado_em desc);
create index if not exists quiz_eventos_sessao_idx   on quiz_eventos (sessao);
create index if not exists quiz_eventos_evento_idx   on quiz_eventos (evento);
create index if not exists quiz_eventos_campanha_idx on quiz_eventos (utm_campaign);

-- ------------------------------------------------------------
-- 2. CONFIGURAÇÃO: chave do painel e webhook
-- ------------------------------------------------------------
create table if not exists quiz_config (
  id             int primary key default 1,
  chave_painel   text not null,
  webhook_url    text,
  webhook_quando text not null default 'resultado',  -- nunca | resultado | tudo
  atualizado_em  timestamptz default now(),
  constraint quiz_config_linha_unica check (id = 1),
  constraint quiz_config_quando_valido check (webhook_quando in ('nunca','resultado','tudo'))
);

-- TROQUE A SENHA ABAIXO ANTES DE RODAR.
insert into quiz_config (id, chave_painel)
values (1, 'troque-esta-senha')
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 3. SEGURANÇA
--    A chave anon do Supabase é pública: ela fica visível no
--    código do quiz. Por isso o anônimo só pode INSERIR evento.
--    Ler os dados exige a senha do painel, e a leitura acontece
--    pelas funções abaixo, nunca direto na tabela.
-- ------------------------------------------------------------
alter table quiz_eventos enable row level security;
alter table quiz_config  enable row level security;

drop policy if exists quiz_eventos_insercao on quiz_eventos;
create policy quiz_eventos_insercao
  on quiz_eventos for insert to anon, authenticated
  with check (true);

-- Sem policy de select: ninguém lê a tabela direto, nem com a chave anon.
-- quiz_config não tem policy nenhuma: só as funções abaixo a acessam.

-- ------------------------------------------------------------
-- 4. LEITURA DO PAINEL
-- ------------------------------------------------------------
create or replace function quiz_painel(p_chave text, p_horas int default 168)
returns setof quiz_eventos
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from quiz_config where id = 1 and chave_painel = p_chave) then
    raise exception 'chave invalida' using errcode = '28000';
  end if;

  return query
    select * from quiz_eventos
    where criado_em >= now() - make_interval(hours => greatest(1, least(p_horas, 2160)))
    order by criado_em desc
    limit 50000;
end;
$$;

create or replace function quiz_config_ler(p_chave text)
returns table (webhook_url text, webhook_quando text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from quiz_config where id = 1 and chave_painel = p_chave) then
    raise exception 'chave invalida' using errcode = '28000';
  end if;
  return query select c.webhook_url, c.webhook_quando from quiz_config c where c.id = 1;
end;
$$;

create or replace function quiz_config_salvar(p_chave text, p_url text, p_quando text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from quiz_config where id = 1 and chave_painel = p_chave) then
    raise exception 'chave invalida' using errcode = '28000';
  end if;
  if p_quando not in ('nunca','resultado','tudo') then
    raise exception 'valor de webhook_quando invalido';
  end if;
  if p_url is not null and p_url <> '' and p_url !~ '^https://' then
    raise exception 'o webhook precisa comecar com https://';
  end if;

  update quiz_config
     set webhook_url = nullif(p_url, ''),
         webhook_quando = p_quando,
         atualizado_em = now()
   where id = 1;
end;
$$;

revoke all on function quiz_painel(text,int)              from public;
revoke all on function quiz_config_ler(text)              from public;
revoke all on function quiz_config_salvar(text,text,text) from public;
grant execute on function quiz_painel(text,int)              to anon, authenticated;
grant execute on function quiz_config_ler(text)              to anon, authenticated;
grant execute on function quiz_config_salvar(text,text,text) to anon, authenticated;

-- ------------------------------------------------------------
-- 5. WEBHOOK (opcional, ligue quando quiser)
--
--    Dispara do servidor, não do navegador: a URL do webhook
--    nunca aparece no código do quiz e ninguém de fora consegue
--    disparar requisição em nome dele.
--
--    Antes de rodar este bloco, habilite a extensão pg_net em
--    Database > Extensions no painel do Supabase.
-- ------------------------------------------------------------

-- create extension if not exists pg_net with schema extensions;

create or replace function quiz_disparar_webhook()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  cfg      record;
  corpo    jsonb;
  resumo   jsonb;
begin
  select webhook_url, webhook_quando into cfg from quiz_config where id = 1;

  if cfg.webhook_url is null or cfg.webhook_quando = 'nunca' then
    return new;
  end if;

  -- 'resultado' manda só quem chegou ao fim; 'tudo' manda cada passo
  if cfg.webhook_quando = 'resultado'
     and new.evento not in ('resultado','clicou_cta') then
    return new;
  end if;

  -- junta as respostas da sessão, para o webhook chegar com o contexto inteiro
  select jsonb_agg(jsonb_build_object(
           'passo', e.passo, 'pergunta', e.pergunta,
           'valor', e.valor, 'rotulo', e.rotulo) order by e.passo)
    into resumo
    from quiz_eventos e
   where e.sessao = new.sessao and e.evento = 'respondeu';

  corpo := jsonb_build_object(
    'evento',    new.evento,
    'sessao',    new.sessao,
    'trilha',    new.trilha,
    'perfil',    new.perfil,
    'score',     new.score,
    'destino',   new.destino,
    'respostas', coalesce(resumo, '[]'::jsonb),
    'origem',    jsonb_build_object(
                   'utm_source',   new.utm_source,
                   'utm_medium',   new.utm_medium,
                   'utm_campaign', new.utm_campaign,
                   'utm_content',  new.utm_content,
                   'utm_term',     new.utm_term),
    'dispositivo', new.dispositivo,
    'criado_em',   new.criado_em
  );

  perform net.http_post(
    url     := cfg.webhook_url,
    headers := jsonb_build_object('Content-Type','application/json'),
    body    := corpo
  );

  return new;
exception when others then
  -- webhook com problema nunca pode derrubar o registro do evento
  return new;
end;
$$;

-- Descomente para ativar:
-- drop trigger if exists quiz_eventos_webhook on quiz_eventos;
-- create trigger quiz_eventos_webhook
--   after insert on quiz_eventos
--   for each row execute function quiz_disparar_webhook();

-- ------------------------------------------------------------
-- 6. LIMPEZA (opcional)
--    Mantém a base enxuta apagando evento com mais de 180 dias.
--    Agende em Database > Cron, se quiser.
-- ------------------------------------------------------------
create or replace function quiz_limpar_antigos()
returns void language sql security definer set search_path = public as $$
  delete from quiz_eventos where criado_em < now() - interval '180 days';
$$;
