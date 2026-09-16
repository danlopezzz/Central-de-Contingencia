# Quiz de Qualificação — Trading Pro

Quiz interativo de pré-sell em **arquivo único** (`index.html`). Não depende de build,
framework, backend ou de qualquer outro projeto deste repositório.

---

## Como publicar na Vercel

### Opção 1 — arrastar a pasta (mais rápido)
1. Baixe **apenas a pasta `quiz/`**.
2. Acesse [vercel.com/new](https://vercel.com/new) e arraste a pasta para a área de upload.
3. Pronto: a Vercel devolve o link compartilhável.

### Opção 2 — conectar este repositório
1. Importe o repositório na Vercel.
2. Em **Settings → General → Root Directory**, escolha `quiz`.
   > Esse passo é obrigatório. Sem ele a Vercel publica o `index.html` da raiz,
   > que pertence a outro projeto.
3. Framework Preset: **Other**. Sem comando de build.

Depois é só apontar o domínio ou usar o link `.vercel.app` no anúncio.

---

## Como o quiz se monta

São 5 perguntas. Três são iguais para todo mundo, duas variam:

| # | Pergunta | Varia? |
| - | -------- | ------ |
| 1 | O que mais te chamou atenção no anúncio? | Fixa, é ela que define a trilha |
| 2 | Aprofunda o desejo que trouxe a pessoa | **Muda conforme a trilha** |
| 3 | Mede o contexto real | **Muda conforme a trilha** |
| 4 | Você já investiu? | Fixa |
| 5 | Você teria de R$ 100,00 a R$ 300,00 para iniciar hoje? | Fixa, é ela que decide o destino |

A pergunta 1 não pergunta a dor: pergunta o **desejo que fez a pessoa clicar**.
Por isso funciona para qualquer público que o anúncio traga, do leigo ao trader
experiente. É a pergunta 2 que desce ao nível de quem a pessoa é de fato.

A pergunta 5 carrega a oferta das 24 horas acima do enunciado e, abaixo das
alternativas, a explicação de por que o valor é necessário.

As 4 trilhas, conforme a resposta da pergunta 1:

| Respondeu na pergunta 1 | Perfil no resultado | Pergunta 2 | Pergunta 3 |
| ----------------------- | ------------------- | ---------- | ---------- |
| Ferramenta 100% automatizada | Movido por Automação | Como está sua relação com o mercado hoje | O que quer que a ferramenta resolva |
| Iniciar sem dinheiro e sem tempo | Começando do Zero Absoluto | O que mais te impede de começar | Tempo que conseguiria reservar |
| Operar sem olhar o mercado sempre | Em busca de Liberdade Operacional | O que te atrapalha por não acompanhar | Janela real por dia |
| Conquistar uma nova fonte de renda | Construindo uma Nova Fonte de Renda | O que espera dessa renda | Já teve experiência no mercado |

Cada alternativa das perguntas 2 a 5 carrega o próprio texto de resultado, então
o diagnóstico final é montado com as palavras da trilha que a pessoa percorreu.

## Regra de roteamento do lead

O destino é decidido **exclusivamente pela pergunta 5**:

| Resposta na pergunta 5              | Destino    |
| ----------------------------------- | ---------- |
| A: Sim, tenho de R$ 100,00 a R$ 300,00   | WhatsApp   |
| B: Sim, tenho de R$ 500,00 a R$ 1.000,00 | WhatsApp   |
| C: Não tenho nenhum investimento         | Comunidade |

A pergunta 4 (você já investiu) **não** muda o destino: ela alimenta o score e
personaliza o resultado. Quem já investiu R$ 100 mil mas não tem valor para
iniciar hoje vai para a comunidade, como qualquer outro.

Se a pessoa voltar e trocar a resposta da pergunta 1, a trilha é remontada e as
respostas seguintes são descartadas, porque pertenciam ao perfil antigo.

### Sobre o botão no resultado

O botão aparece **logo abaixo do nome do perfil**, antes do score e do
diagnóstico, para ninguém precisar rolar até achá-lo. É o único CTA da
página: o score, o texto e a recapitulação vêm depois dele e servem para
sustentar quem não clicou de primeira.

## Onde mexer

Tudo que você normalmente vai querer alterar está no bloco `CONFIG`, no topo do
`<script>` (por volta da linha 700 do `index.html`):

```js
var CONFIG = {
  redirectWhats:        'https://app.massflow.tech/api/r/vanessa',
  redirectComunidade:   'https://app.massflow.tech/api/go/comunidade-traderpro-tpnra3ppsd',
  repassarParametros:   true,   // repassa utm_source, utm_campaign etc. para o destino
  autoRedirectSegundos: 0,      // 0 = só redireciona no clique. Ex: 12 = redireciona sozinho
  tempoAnalise:         3400    // duração da tela "Analisando suas respostas..."
};
```

Outros pontos de edição, todos em estruturas de dados no início do `<script>`:

- **`PERGUNTA_1`** — a pergunta que define a trilha. Cada alternativa tem `valor`
  (a chave da trilha) e `pontos`.
- **`TRILHAS`** — as perguntas 2 e 3 de cada perfil, indexadas pelo `valor` da
  pergunta 1. Cada alternativa tem `titulo`, `sub` (a linha menor), `pontos` e
  `recap` — este último é a frase que vai para o resultado.
- **`PERGUNTA_CAPITAL`** — a pergunta 4. O atributo `destino` de cada alternativa
  (`'whats'` ou `'comunidade'`) é o que decide para onde o lead vai.
- **`PERFIS`** — nome, gargalo e texto de cada um dos 5 perfis do resultado.
- **Cores da marca**: variáveis CSS em `:root` (`--green`, `--green-bright`, `--bg`…).
- **Logo**: SVG no `<symbol id="logo-mark">`, desenhado em vetor — escala sem perder
  qualidade e não depende de arquivo de imagem externo.

Para acrescentar uma alternativa, basta adicioná-la ao array `opcoes`: as letras
(A, B, C…) são geradas sozinhas e a tela se monta a partir dos dados.

---

## Rastreamento — Meta Pixel

O Pixel **já está instalado** no `index.html`, com o ID `1057320473675949`:
o snippet fica no topo do `<head>` e a tag `<noscript>` logo após o `<body>`.
Não precisa colar nada.

Eventos disparados automaticamente:

| Evento | Tipo no Meta | Quando acontece |
| ------ | ------------ | --------------- |
| `PageView` | padrão | página carregou |
| `quiz_visualizado` | personalizado | página carregou |
| `quiz_iniciado` | personalizado | clique em "Começar agora" |
| `quiz_resposta` | personalizado | cada resposta (pergunta, valor e perfil) |
| `QuizCompleto` | personalizado | tela de resultado (destino, score, perfil e trilha) |
| **`Lead`** | **padrão** | **clique no botão final** |

**Use `Lead` como evento de otimização das campanhas.** É o único que marca
o lead chegando no WhatsApp ou na comunidade. Os personalizados servem para
públicos e para ver onde o funil perde gente — dá para criar um público de
quem completou o quiz e não clicou, por exemplo.

Para trocar o ID do Pixel, troque nos **dois** lugares: no `fbq('init', ...)`
dentro do `<head>` e no `src` da imagem no `<noscript>`.

### A espera antes do redirect

O clique no CTA sai da página imediatamente, e um navegador que troca de
página costuma cancelar requisições em andamento — inclusive a do `Lead`.
Resultado: a conversão acontece e não aparece no gerenciador.

Por isso o clique é segurado por 350 ms, tempo suficiente para a requisição
partir, e só então redireciona. Está em `CONFIG.esperaPixelMs` — baixe ou
suba se quiser, ou coloque `0` para desligar a espera.

A navegação nunca depende do Pixel: se ele estiver bloqueado por adblock ou
falhar ao carregar, o redirect acontece do mesmo jeito. Abrir o link em nova
aba (Ctrl/Cmd + clique) também continua funcionando normalmente.

Os mesmos eventos também vão para `window.dataLayer` (GTM) e `gtag` (GA4)
quando esses scripts existirem na página.

---

## Painel de rastreamento

Além do Pixel, o quiz grava cada passo num banco próprio e mostra tudo num
painel ao vivo, que fica na pasta `painel/` e é publicado como site separado. É opcional: com as credenciais em branco o quiz
funciona exatamente como antes e não faz nenhuma chamada de rede extra.

### Passo a passo para configurar

Siga na ordem. Leva uns 10 minutos.

**1. Crie o projeto no Supabase**

- Entre em [supabase.com](https://supabase.com) e clique em **New project**
- Nome: `quiz-trading-pro` (ou o que preferir)
- Escolha uma senha de banco e guarde. Você não vai precisar dela aqui, mas o
  Supabase exige
- Região: **South America (São Paulo)**, que é a mais perto do seu público
- Clique em **Create new project** e espere uns 2 minutos

> Crie um projeto **novo**. Não use o da Central de Contingência: este quiz é
> um projeto isolado e misturar os dois só traz confusão depois.

**2. Rode o SQL**

- No menu da esquerda, abra **SQL Editor**
- Clique em **New query**
- Abra o arquivo `supabase-tracking.sql` desta pasta, copie **tudo** e cole lá
- Clique em **Run** (ou Ctrl+Enter)
- Tem que aparecer *Success. No rows returned*

> Se aparecer erro, copie a mensagem e me mande. Não siga para o próximo passo
> com erro, senão o painel vai abrir vazio e você não vai saber o porquê.

**3. Confira se as tabelas nasceram**

- Menu **Table Editor**
- Devem existir duas tabelas: **quiz_eventos** (vazia) e **quiz_config** (com
  uma linha)

**4. Copie as credenciais**

- Menu **Project Settings** (a engrenagem) > **API**
- Copie o **Project URL**. Fica assim: `https://abcdefgh.supabase.co`
- Copie a chave **anon public**. É um texto longo que começa com `eyJ...`

> Use a **anon public**. Nunca a `service_role`: aquela dá acesso total ao
> banco e não pode aparecer em página nenhuma.

**5. Cole nos dois arquivos**

No `index.html`, procure `supabaseUrl` (fica no bloco `CONFIG`, no começo do
`<script>`):

```js
supabaseUrl:   'https://abcdefgh.supabase.co',
supabaseChave: 'eyJhbGciOi...',
```

No `painel/index.html`, procure `supabaseUrl` (logo no começo do `<script>`) e
cole **os mesmos dois valores**.

> É o erro mais comum: preencher só um dos arquivos. Se preencher só o quiz, o
> painel abre vazio. Se preencher só o painel, nada é gravado.

**6. Publique os dois sites, separados**

O quiz e o painel são **dois sites diferentes**, de propósito. O quiz é
divulgado no tráfego; se o painel morasse no mesmo endereço, qualquer pessoa
que recebesse o anúncio poderia tentar `/painel` e ver a lista de leads.

- Suba a pasta `quiz/` no site que você já usa para o quiz
- Suba a pasta `painel/` como um **site novo** na Netlify, com um nome que não
  tenha relação com o do quiz. As instruções estão no `painel/README.md`

**7. Teste antes de ligar o tráfego**

1. Abra o quiz e responda até o fim, clicando no botão final
2. Abra o painel
3. Em até 15 segundos sua sessão tem que aparecer na tabela, com as respostas
   que você deu

Deu certo? Pode ligar o tráfego.

### Se o painel mostrar erro

O painel diz na tela o que houve. Os três casos:

| O que aparece | O que fazer |
| ------------- | ----------- |
| *Faltam as credenciais do Supabase* | Você não colou a URL e a chave no `painel/index.html` (passo 5) |
| *A tabela quiz_eventos não existe nesse projeto* | O SQL não rodou, ou rodou em outro projeto (passo 2) |
| *A chave anon não tem permissão* | O SQL rodou pela metade. Rode de novo, inteiro |

Se o painel abrir sem erro mas vazio, é porque ninguém respondeu o quiz ainda
no período escolhido. Troque o período no seletor do topo.

### Conferir o painel sem ligar nada

Abra o painel com `?demo=1` no fim do endereço para ver o painel funcionando com dados gerados na
hora. Nada é salvo e nenhuma credencial é necessária. Serve para mostrar para a
diretoria antes de configurar.

### O que o painel mostra

- **Funil completo**, da abertura da página ao clique no botão, com a
  porcentagem que some em cada etapa. É aqui que você descobre qual pergunta
  está derrubando o quiz.
- **KPIs**: sessões, quantos começaram, quantos concluíram, cliques no CTA,
  quantos foram ao WhatsApp e o tempo médio até o fim.
- **Distribuição das respostas**, uma lista por pergunta. Como as perguntas 2
  e 3 mudam por trilha, elas aparecem separadas por trilha, nunca somadas.
- **Tabela de sessões**: cada pessoa, o que respondeu, onde parou, o perfil, a
  campanha e o aparelho. Atualiza sozinha a cada 15 segundos.
- **Filtro por campanha** e **download em CSV**.

### Webhook

O webhook se configura **dentro do Supabase**, não pelo painel. O motivo é
concreto: a chave que o painel usa é a mesma que fica no código do quiz, que é
uma página pública. Se desse para editar o webhook pelo painel, qualquer pessoa
que lesse o código-fonte do quiz poderia apontar os seus leads para o servidor
dela.

Como configurar, quando tiver a URL:

1. **Table Editor > quiz_config** > edite a única linha
   - `webhook_url`: a URL, começando com `https://`
   - `webhook_quando`: `nunca`, `resultado` (só quem conclui) ou `tudo`
2. **Database > Extensions** > habilite **pg_net**
3. **SQL Editor** > rode o bloco do `create trigger` que está comentado no fim
   do `supabase-tracking.sql`

O payload chega com o evento, o perfil, o score, o destino, **todas as
respostas da sessão** e a origem completa.

### Sobre o acesso ao painel

O painel **abre sem senha**: quem tiver o endereço vê os dados. Por isso ele
vive num site separado, com endereço que não tem relação com o do quiz, e é
`noindex`. Quem recebe o link do anúncio não tem como chegar nele. Ainda assim,
trate o endereço como interno.

Os dados são anônimos: nenhum nome, telefone ou e-mail é coletado. A sessão é
um identificador aleatório gerado no navegador de quem responde.

Se um dia quiser trancar, dá para religar uma tela de acesso.

### O que ele não faz

- **Abandono é inferido.** Quem fecha a aba dispara um evento de saída, mas
  navegador é imprevisível: o número é uma boa aproximação, não um relógio.
- **Bloqueadores existem.** Parte do tráfego bloqueia rastreamento. Como os
  dados vão para o seu Supabase e não para um domínio de anúncio, o bloqueio é
  bem menor que o do Pixel, mas não é zero.
- **O lead é anônimo até o WhatsApp.** Para casar a sessão do painel com a
  pessoa que chega na conversa, seria preciso o código curto no fim do quiz.

---

## Detalhes de implementação

- Fundo com candlesticks em `<canvas>`, gerados por código e em movimento contínuo.
- Radar animado na tela de análise + confete na tela de resultado.
- Perguntas montadas em tempo real a partir dos dados da trilha escolhida.
- Navegação por teclado: `A`–`E` ou `1`–`5` respondem, `Backspace` volta, `Enter` inicia.
- Vibração tátil no celular a cada resposta (onde o aparelho suporta).
- Botão "Voltar" preserva a resposta já marcada.
- `prefers-reduced-motion` respeitado: desliga canvas, confete e transições.
- A página é `noindex` por padrão (tráfego pago). Para permitir indexação, remova a
  meta tag `robots` do `index.html` e o header `X-Robots-Tag` do `vercel.json`.
