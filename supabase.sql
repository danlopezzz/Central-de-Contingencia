-- Central de Contingência — schema do banco
-- Rode no SQL Editor de um projeto Supabase NOVO (não reaproveite outro projeto).

create table if not exists cx_dados (
  id             bigserial primary key,
  operacao       text not null default 'principal',
  chave          text not null,          -- clientes | estruturas | informativos | incidentes | checks
  conteudo       jsonb not null,
  atualizado_em  timestamptz default now(),
  unique (operacao, chave)
);

-- Histórico diário: é o que transforma "chute" em taxa de queima e vida útil reais.
create table if not exists cx_snapshots (
  id        bigserial primary key,
  operacao  text not null default 'principal',
  dia       date not null,
  conteudo  jsonb not null,
  unique (operacao, dia)
);

-- SEGURANÇA: a chave publishable é pública por design.
-- Sem RLS, qualquer um com o link do sistema lê o banco.
alter table cx_dados     enable row level security;
alter table cx_snapshots enable row level security;

-- Ajuste as policies conforme quem precisa acessar.
-- Exemplo permissivo (só use enquanto o link não sair do seu controle):
-- create policy leitura  on cx_dados for select using (true);
-- create policy escrita  on cx_dados for insert with check (true);
-- create policy update_  on cx_dados for update using (true);
