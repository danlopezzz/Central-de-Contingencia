# Painel de Rastreamento — Variação C

Painel em tempo real da variação C do quiz. Site **separado** do quiz e
separado dos painéis das versões A e B.

Lê direto do projeto Supabase **próprio** da variação C. Nenhum dado das
outras variações aparece aqui, e nada daqui toca no banco do B.

---

## Antes de subir: as credenciais

O `var CONFIG` no topo do script vem **em branco**, de propósito. Cole ali a
**Project URL** e a chave **anon public** do projeto novo do quiz C — as
mesmas duas que você colou no `quiz-c/index.html`.

O passo a passo completo de criar o projeto está no `quiz-c/README.md`.

Confira que não sobrou nenhum `gmfxivkgbldcngoarjtv` aqui: esse é o projeto
do quiz B, que está no tráfego pago e não deve ser tocado.

---

## Publicar

1. Preencha as credenciais antes de subir.
2. Cloudflare Pages (ou Netlify) → novo projeto → upload manual.
3. Suba a pasta `painel-c/` **inteira** — o arquivo `_headers` precisa ir junto.
4. Guarde a URL. Não divulgue, não coloque em anúncio, não use como destino
   de link.

O `_headers` manda `noindex` pra não cair em busca do Google, bloqueia
carregamento dentro de iframe e não vaza a URL como referrer.

---

## O que o painel mostra

**Números do topo**
Sessões, leads do popup, quantos começaram, quantos concluíram, cliques no
CTA, quem foi pro especialista e pra comunidade — cada um com a **variação
contra o período anterior** (▲/▼), do mesmo tamanho da janela escolhida.

**Funil vertical**
Quantas pessoas passaram por cada etapa, do "abriu a página" ao "clicou no
CTA", e quantas caíram em cada uma. É aqui que você vê em qual pergunta o
pessoal desiste.

**Por hora do dia**
24 barras com o pico destacado. Serve pra decidir janela de veiculação.

**Onde demoram**
Tempo mediano em cada pergunta. Pergunta muito mais lenta que as outras
costuma ser pergunta mal escrita, não pergunta difícil.

**Ao vivo**
Quem está respondendo agora, em qual pergunta está e de qual campanha veio.

**Trilhas e perfis**
Distribuição das quatro trilhas, pra saber qual público o criativo traz.

**Campanhas**
Quebra por `utm_source`, `utm_campaign` e `utm_content`.

**Conferência dos leads**
O funil conta o **evento**; a conferência conta a **linha gravada** em
`quiz_leads`. Se os dois não baterem, alguma gravação está falhando — e você
descobre no mesmo dia, não no fim do mês.

**FTD (primeiro depósito)**
Aparece só se o `supabase-ftd-c.sql` tiver sido rodado e houver depósito
gravado. Mostra leads, quantos viraram FTD, receita, ticket, horas até o
primeiro depósito e a quebra por campanha. O cruzamento lead ↔ depósito é
pelo **telefone normalizado**. Sem o SQL, o bloco simplesmente não aparece —
nada quebra.

**Exportar CSV**
Baixa tudo já com a coluna `variacao` = `C`, pra cruzar com o relatório da
Meta ou juntar com o CSV das outras variações numa planilha só.

---

## Privacidade

O painel **nunca** lê nome nem telefone. As duas consultas que tocam em dado
pessoal (`quiz_leads_resumo` e `quiz_ftd_resumo`) são funções `security
definer` no banco que devolvem **só números agregados**. A chave anon que
está aqui não consegue fazer `select` em `quiz_leads` nem em
`quiz_depositos` — a RLS nega.

Para ver os leads de verdade: Supabase → **Table Editor**, logado.

---

## Atualização

Busca a cada 15 segundos e pede **só o que é novo** desde a última busca, não
a base inteira. Dá pra deixar aberto o dia todo sem peso.

Para ver o visual sem dado real, abra a URL com `?demo=1` no final. Gera
sessões falsas só na tela, não grava nada no banco.

---

## Comparar B e C

Abra os dois painéis lado a lado, na mesma janela de tempo. O C tem as
perguntas do A com o layout do B, então:

1. **Taxa de conclusão** — as perguntas do A seguram mais gente que as do B?
2. **Onde cai** — se o C perde numa pergunta que o B não tinha, é a pergunta.
3. **% que vai pro especialista** — qualidade do lead, não só volume.
4. **FTD por campanha** — no fim, é o número que paga a conta.

Só compare períodos com volume parecido. Com menos de ~100 sessões de cada
lado, a diferença ainda é ruído.

---

## Se o painel não mostrar nada

1. F12 → aba **Network** → recarregue.
2. Procure a chamada pro `supabase.co`:
   - **200** e painel vazio → ainda não houve tráfego, ou o quiz está sem credenciais.
   - **401** → a chave anon está errada, incompleta, ou o SQL não rodou inteiro.
   - **404** → a URL do projeto está errada, ou o SQL não foi rodado.
   - **nada aparece** → as credenciais estão em branco aqui no `index.html`.
3. Confira que o `quiz-c/index.html` publicado tem as **mesmas** credenciais
   que o painel. É o erro mais comum: preencher num arquivo e esquecer do outro.
