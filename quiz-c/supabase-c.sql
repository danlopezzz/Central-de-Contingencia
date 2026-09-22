-- >>>>>>>>>>>>>>>>  INICIO DO ARQUIVO — ESTA E A LINHA 1  <<<<<<<<<<<<<<<<
--
-- Se a primeira linha que voce colou no Supabase NAO for esta, a colagem
-- veio incompleta. Apague tudo do editor e cole de novo: abra o arquivo,
-- Ctrl+A (ou Cmd+A) para selecionar TUDO, Ctrl+C, e cole.
-- No fim, o editor tem que mostrar cerca de 478 linhas.
--
-- ============================================================
-- Quiz Trading Pro — VARIAÇÃO C — banco completo
--
-- ARQUIVO ÚNICO. Rode uma vez, inteiro, no SQL Editor de um projeto
-- Supabase NOVO, exclusivo do quiz C. Não use o projeto do quiz A nem
-- o do quiz B: cada variação tem o seu banco, para nunca misturar os
-- números e para um SQL do C jamais poder quebrar o B.
--
-- COMO RODAR
--   1. Supabase → SQL Editor → New query
--   2. Cole este arquivo inteiro (Ctrl+A, Ctrl+C aqui; Ctrl+V lá)
--   3. Run
--   4. Tem que aparecer "Success". Se vier erro em vermelho, me mande
--      a mensagem antes de fazer qualquer outra coisa.
--
-- Rodar de novo é seguro: tudo aqui é "create if not exists" ou
-- "create or replace". Nada apaga dado.
--
-- O QUE ELE CRIA
--   quiz_eventos    o funil, passo a passo. Sem nome, sem telefone.
--   quiz_leads      nome e WhatsApp do popup. O anon SÓ ESCREVE.
--   quiz_depositos  os primeiros depósitos (FTD). O anon não toca.
--   quiz_config     o webhook, editável só por você, logado.
--   + as funções de resumo que o painel usa para ver números sem
--     nunca ver um nome ou um telefone.
--
-- A IDEIA DE SEGURANÇA, EM UMA FRASE
--   A chave anon fica visível no HTML do quiz, que é público. Então
--   ela pode escrever o que o quiz precisa escrever, e não pode ler
--   nada que seja dado pessoal. Quem lê o telefone é você, logado no
--   Supabase.
-- ============================================================


-- ============================================================
-- 1. NORMALIZAÇÃO DO TELEFONE
--
-- O mesmo número chega de jeitos diferentes:
--   5511987654321 (com 55)   11987654321 (com o 9)   1187654321 (sem o 9)
--   (021) 99887-7665 (com prefixo de operadora e pontuação)
-- Todos viram DDD + os 8 últimos dígitos. É por essa chave que o
-- depósito encontra o lead.
-- ============================================================
create or replace function fone_chave(bruto text)
returns text
language sql
immutable
as $$
  with d as (
    select regexp_replace(coalesce(bruto,''), '\D', '', 'g') as n
  ),
  -- tira zero de prefixo de operadora (021, 015, 0...) — DDD brasileiro
  -- nunca começa com zero, então isto é seguro
  z as (select regexp_replace(n, '^0+', '') as n from d),
  -- tira o 55 do país. Só quando sobra mais que um número nacional,
  -- para não comer o DDD 55 (Santa Maria)
  s as (select case when length(n) > 11 and left(n,2) = '55'
                    then substring(n from 3) else n end as n from z)
  select case when length(n) between 10 and 11
              then left(n,2) || right(n,8)
              else null end
  from s;
$$;

-- Toda funcao nasce executavel por QUALQUER UM no Postgres, inclusive pela
-- chave anon que fica visivel no HTML do quiz. Aqui a gente tira o acesso
-- publico e devolve so para o anon, que PRECISA dela:
--
-- existe um indice por expressao em quiz_leads (fone_chave(whatsapp)), e o
-- Postgres checa EXECUTE na hora da insercao para manter esse indice. Sem o
-- grant abaixo, o popup falha com "permission denied for function
-- fone_chave" — e falha EM SILENCIO, porque o envio do quiz e a prova de
-- falha e nao mostra erro na tela. Testado: o lead simplesmente nao grava.
--
-- Dar EXECUTE aqui nao abre nada: a funcao e pura, so normaliza um texto,
-- nao le tabela nenhuma e nao muda nada.
revoke all on function fone_chave(text) from public;
grant  execute on function fone_chave(text) to anon, authenticated;


-- ============================================================
-- 2. EVENTOS — uma linha por passo que a pessoa dá no quiz
--    Nenhum dado pessoal mora aqui.
-- ============================================================
create table if not exists quiz_eventos (
  id           bigserial primary key,
  sessao       text        not null,          -- id anônimo, gerado no navegador
  variacao     text        not null default 'C',
  evento       text        not null,
  passo        smallint,                      -- 1 a 5, quando evento = 'respondeu'
  pergunta     text,                          -- o enunciado da pergunta
  valor        text,                          -- valor da alternativa escolhida
  rotulo       text,                          -- texto da alternativa, para leitura humana
  trilha       text,                          -- objetivo escolhido na pergunta 1
  perfil       text,
  score        smallint,
  destino      text,                          -- whats | comunidade
  tempo_ms     integer,
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

  constraint quiz_eventos_sessao_tam check (char_length(sessao) between 8 and 64)
);

-- A lista de eventos válidos fica fora do create table de propósito:
-- assim ela é corrigida também num banco que já existia.
alter table quiz_eventos drop constraint if exists quiz_eventos_evento_valido;
alter table quiz_eventos add  constraint quiz_eventos_evento_valido check (evento in
  ('visualizou','lead','iniciou','respondeu','analisando','resultado','clicou_cta','saiu'));

create index if not exists quiz_eventos_criado_idx   on quiz_eventos (criado_em desc);
create index if not exists quiz_eventos_sessao_idx   on quiz_eventos (sessao);
create index if not exists quiz_eventos_evento_idx   on quiz_eventos (evento);
create index if not exists quiz_eventos_campanha_idx on quiz_eventos (utm_campaign);
create index if not exists quiz_eventos_fbclid_idx   on quiz_eventos (fbclid);


-- ============================================================
-- 3. LEADS — nome e WhatsApp do popup
--
-- Separado de quiz_eventos de propósito. Se a chave anon pudesse LER
-- esta tabela, qualquer pessoa que abrisse o código-fonte do quiz
-- baixaria a lista de nomes e telefones dos seus leads.
-- ============================================================
create table if not exists quiz_leads (
  id           bigserial primary key,
  sessao       text        not null,     -- mesma sessão do quiz_eventos
  variacao     text        not null default 'C',
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

-- Índice pela chave do telefone, que é como o depósito acha o lead.
-- Recriado a cada execução: índice por expressão guarda o resultado da
-- função, e o Postgres confia que uma função immutable não mudou.
drop index if exists quiz_leads_fone_norm_idx;
create index quiz_leads_fone_norm_idx on quiz_leads (fone_chave(whatsapp));


-- ============================================================
-- 4. DEPÓSITOS (FTD) — o primeiro depósito de cada pessoa
--
-- O depósito acontece na corretora, dias depois, em outro site. O quiz
-- não tem como saber. Alguém (a ponte do diretor, ou você na mão) grava
-- aqui, e o cruzamento com o lead é pelo TELEFONE.
--
-- Esta parte é opcional: enquanto não houver depósito gravado, o painel
-- simplesmente mostra zero. Nada quebra.
-- ============================================================
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


-- ============================================================
-- 5. CONFIGURAÇÃO — o webhook
-- ============================================================
create table if not exists quiz_config (
  id             int primary key default 1,
  webhook_url    text,
  webhook_quando text not null default 'nunca',   -- nunca | resultado | tudo
  atualizado_em  timestamptz default now(),
  constraint quiz_config_linha_unica check (id = 1),
  constraint quiz_config_quando_valido check (webhook_quando in ('nunca','resultado','tudo'))
);

insert into quiz_config (id) values (1) on conflict (id) do nothing;


-- ============================================================
-- 6. PERMISSÕES — quem pode o quê
--
--   quiz_eventos    anon escreve e lê. São dados anônimos, e o painel
--                   abre sem senha, então a leitura fica liberada para
--                   quem tiver o link e a chave.
--   quiz_leads      anon SÓ ESCREVE. Sem policy de select, a RLS nega a
--                   leitura. É essa ausência que protege os telefones.
--   quiz_depositos  anon não faz NADA. Nenhuma policy. Sem isso, quem
--                   lesse o código do quiz poderia inventar depósito.
--   quiz_config     anon não faz NADA. Sem isso, quem lesse o código
--                   apontaria o webhook para o próprio servidor e
--                   passaria a receber os seus leads.
-- ============================================================
alter table quiz_eventos   enable row level security;
alter table quiz_leads     enable row level security;
alter table quiz_depositos enable row level security;
alter table quiz_config    enable row level security;

drop policy if exists quiz_eventos_insercao on quiz_eventos;
drop policy if exists quiz_eventos_leitura  on quiz_eventos;
create policy quiz_eventos_insercao on quiz_eventos
  for insert to anon, authenticated with check (true);
create policy quiz_eventos_leitura on quiz_eventos
  for select to anon, authenticated using (true);

-- Só insert, e só da variação C. Um lead marcado 'A' ou 'B' é recusado:
-- é a trava que garante que este banco é só do quiz C.
drop policy if exists "anon grava lead" on quiz_leads;
create policy "anon grava lead"
  on quiz_leads for insert to anon
  with check (
    char_length(nome) between 2 and 120
    and whatsapp ~ '^[0-9]{10,11}$'
    and variacao = 'C'
  );

-- quiz_depositos e quiz_config: nenhuma policy, de propósito.


-- ============================================================
-- 7. RESUMOS PARA O PAINEL
--
-- O painel nunca lê quiz_leads nem quiz_depositos direto — ele não
-- consegue. Ele chama estas duas funções, que rodam com privilégio do
-- dono e devolvem SÓ NÚMEROS. Nome e telefone não saem daqui.
-- ============================================================

-- 7a. Conferência dos leads: o funil conta o evento, isto conta a linha
--     realmente gravada. Se os dois não baterem, a gravação está falhando.
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


-- 7b. FTD: quantos leads viraram depósito, quanto entrou, em quanto tempo
--     e de qual campanha.
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
    -- o PRIMEIRO depósito de cada telefone, sem limite de data: o lead pode
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
    -- depósito que não casou com lead nenhum: telefone em formato estranho,
    -- ou cliente que veio de outro lugar. Se este número subir, a ponte
    -- está mandando telefone que a gente não consegue cruzar.
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


-- ============================================================
-- 8. WEBHOOK (opcional, vem desligado)
--
-- Para ligar: Database → Extensions → habilite pg_net, ponha a URL em
-- quiz_config pelo Table Editor, e descomente o create trigger abaixo.
-- ============================================================
create or replace function quiz_disparar_webhook()
returns trigger language plpgsql security definer
set search_path = public, extensions as $$
declare cfg record; corpo jsonb; resumo jsonb;
begin
  select webhook_url, webhook_quando into cfg from quiz_config where id = 1;
  if cfg.webhook_url is null or cfg.webhook_quando = 'nunca' then return new; end if;
  if cfg.webhook_quando = 'resultado'
     and new.evento not in ('resultado','clicou_cta') then return new; end if;

  select jsonb_agg(jsonb_build_object(
           'passo', e.passo, 'pergunta', e.pergunta,
           'valor', e.valor, 'rotulo', e.rotulo) order by e.passo)
    into resumo from quiz_eventos e
   where e.sessao = new.sessao and e.evento = 'respondeu';

  corpo := jsonb_build_object(
    'variacao', new.variacao, 'evento', new.evento, 'sessao', new.sessao,
    'trilha', new.trilha, 'perfil', new.perfil, 'score', new.score,
    'destino', new.destino, 'respostas', coalesce(resumo, '[]'::jsonb),
    'origem', jsonb_build_object(
      'utm_source', new.utm_source, 'utm_medium', new.utm_medium,
      'utm_campaign', new.utm_campaign, 'utm_content', new.utm_content,
      'utm_term', new.utm_term),
    'dispositivo', new.dispositivo, 'criado_em', new.criado_em);

  perform net.http_post(url := cfg.webhook_url,
    headers := jsonb_build_object('Content-Type','application/json'), body := corpo);
  return new;
exception when others then
  return new;   -- webhook com problema nunca derruba o registro
end;
$$;

-- Fora do alcance publico. Funcao de trigger nao roda chamada direto, mas
-- nao ha motivo para ela ficar listada como executavel pela chave do quiz.
revoke all on function quiz_disparar_webhook() from public;

-- Descomente para ativar:
-- drop trigger if exists quiz_eventos_webhook on quiz_eventos;
-- create trigger quiz_eventos_webhook
--   after insert on quiz_eventos
--   for each row execute function quiz_disparar_webhook();


-- ============================================================
-- 9. LIMPEZA (opcional)
-- ============================================================
create or replace function quiz_limpar_antigos()
returns void language sql security definer set search_path = public as $$
  delete from quiz_eventos where criado_em < now() - interval '180 days';
$$;

-- IMPORTANTE. Esta funcao APAGA linha, e roda com privilegio do dono. Sem o
-- revoke abaixo ela fica executavel pela chave anon, que esta visivel no HTML
-- publico do quiz: qualquer pessoa poderia chamar
--   POST /rest/v1/rpc/quiz_limpar_antigos
-- e apagar o seu historico. Quem limpa e voce, logado no SQL Editor:
--   select quiz_limpar_antigos();
revoke all on function quiz_limpar_antigos() from public;


-- ============================================================
-- 10. CONFERÊNCIA — rode estas linhas depois, se quiser checar
-- ============================================================
-- Table Editor deve mostrar: quiz_eventos, quiz_leads, quiz_depositos, quiz_config
--
-- select * from quiz_leads order by criado_em desc limit 20;  -- aqui, logado
-- select quiz_leads_resumo(now() - interval '7 days');        -- o que o painel vê
-- select quiz_ftd_resumo(now() - interval '30 days');         -- o FTD
--
-- Gravar um depósito na mão:
-- insert into quiz_depositos (telefone, valor, tipo, ocorrido_em, origem)
-- values ('5511987654321', 250.00, 'ftd', now(), 'manual');


-- ============================================================
-- 11. PROVA DE QUE RODOU INTEIRO
--
-- Este select roda por ultimo e aparece no painel Results la embaixo.
-- Se ele disser "4 de 4 tabelas", deu tudo certo.
-- Se nem aparecer, a colagem veio incompleta: recole o arquivo do inicio.
-- ============================================================
select 'Banco do quiz C pronto: '
       || count(*) || ' de 4 tabelas criadas ('
       || string_agg(tablename, ', ' order by tablename) || ')' as resultado
from pg_tables
where schemaname = 'public'
  and tablename in ('quiz_eventos','quiz_leads','quiz_depositos','quiz_config');

-- >>>>>>>>>>>>>>>>>>>>>>  FIM DO ARQUIVO  <<<<<<<<<<<<<<<<<<<<<<
