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
  fbclid       text,                          -- id do clique no anúncio do Meta
  fbp          text,                          -- cookie do navegador, criado pelo Pixel
  fbc          text,                          -- cookie do clique, criado pelo Pixel
  criado_em    timestamptz not null default now(),

  constraint quiz_eventos_evento_valido check (evento in
    ('visualizou','iniciou','respondeu','analisando','resultado','clicou_cta','saiu')),
  constraint quiz_eventos_sessao_tam check (char_length(sessao) between 8 and 64)
);

create index if not exists quiz_eventos_criado_idx   on quiz_eventos (criado_em desc);
create index if not exists quiz_eventos_sessao_idx   on quiz_eventos (sessao);
create index if not exists quiz_eventos_evento_idx   on quiz_eventos (evento);
create index if not exists quiz_eventos_campanha_idx on quiz_eventos (utm_campaign);
create index if not exists quiz_eventos_fbclid_idx   on quiz_eventos (fbclid);

-- ------------------------------------------------------------
-- 2. CONFIGURAÇÃO: o webhook
-- ------------------------------------------------------------
create table if not exists quiz_config (
  id             int primary key default 1,
  webhook_url    text,
  webhook_quando text not null default 'nunca',      -- nunca | resultado | tudo
  atualizado_em  timestamptz default now(),
  constraint quiz_config_linha_unica check (id = 1),
  constraint quiz_config_quando_valido check (webhook_quando in ('nunca','resultado','tudo'))
);

insert into quiz_config (id) values (1) on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 3. PERMISSÕES
--
--    O painel abre sem senha, então a leitura fica liberada para
--    quem tiver o link e a chave anon (que é pública por natureza).
--    Quem souber o endereço do painel vê os dados.
--
--    Os dados são anônimos: nenhum nome, telefone ou e-mail é
--    coletado, só o comportamento no quiz.
--
--    Se um dia quiser trancar, é só remover a policy de select
--    abaixo e me chamar para religar a tela de acesso.
-- ------------------------------------------------------------
alter table quiz_eventos enable row level security;
alter table quiz_config  enable row level security;

drop policy if exists quiz_eventos_insercao on quiz_eventos;
drop policy if exists quiz_eventos_leitura  on quiz_eventos;
create policy quiz_eventos_insercao on quiz_eventos
  for insert to anon, authenticated with check (true);
create policy quiz_eventos_leitura on quiz_eventos
  for select to anon, authenticated using (true);

-- ninguém pode alterar nem apagar evento pela chave pública

-- quiz_config fica SEM policy nenhuma, de propósito.
--
-- A chave anon aparece no codigo-fonte do quiz, que é uma pagina publica.
-- Se o anonimo pudesse escrever aqui, qualquer pessoa que lesse esse
-- codigo poderia trocar a URL do webhook e passar a receber os seus leads.
--
-- Por isso o webhook se configura pelo painel do Supabase, em
-- Table Editor > quiz_config. É uma vez só, e fica fora do alcance de quem
-- tem a chave publica.

-- ------------------------------------------------------------
-- 4. WEBHOOK (opcional, ligue quando quiser)
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
-- 5. LIMPEZA (opcional)
--    Mantém a base enxuta apagando evento com mais de 180 dias.
--    Agende em Database > Cron, se quiser.
-- ------------------------------------------------------------
create or replace function quiz_limpar_antigos()
returns void language sql security definer set search_path = public as $$
  delete from quiz_eventos where criado_em < now() - interval '180 days';
$$;
