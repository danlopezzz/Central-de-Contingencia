# Quiz Trading Pro — Variação C

Cópia do quiz **B** (layout, animações, camuflagem, Pixel e popup) com as
**perguntas do quiz A** e um destino de especialista novo.

Nada do quiz A e nada do quiz B foi alterado. `quiz/`, `painel/`, `quiz-b/`
e `painel-b/` continuam exatamente como estavam — o B segue no tráfego pago
sem um único byte mexido.

---

## Banco de dados: projeto Supabase PRÓPRIO

O quiz C grava num projeto Supabase **novo, só dele**. Não compartilha banco
com o A nem com o B.

| Variação | Projeto Supabase | Painel |
|---|---|---|
| A | `hdfkpepapdakqqbtekqw` | `painel/` |
| B | `gmfxivkgbldcngoarjtv` | `painel-b/` |
| C | **o novo, que você vai criar** | `painel-c/` |

Três bancos separados significam: nenhum SQL rodado pro C pode quebrar o B,
nenhum número se mistura, e se o C der problema o B nem sente.

Por isso o `var CONFIG` do `index.html` vem com as credenciais **em branco**.
Enquanto estiverem em branco o quiz funciona igual — só não grava nada.
Rastreamento nunca derruba o funil.

---

## Passo a passo: criar o projeto novo

### 1. Criar o projeto

1. Entre em https://supabase.com e faça login.
2. **New project**.
3. Preencha:
   - **Name**: `trading-pro-quiz-c` (deixe claro que é o C)
   - **Database Password**: gere uma senha forte e guarde no seu gerenciador
     de senhas. Você **não** vai precisar dela pro quiz nem pro painel.
     Nunca cole essa senha em chat, e-mail ou arquivo do projeto.
   - **Region**: `South America (São Paulo)`
4. **Create new project** e espere uns 2 minutos até ficar verde.

### 2. Criar as tabelas — nesta ordem

Menu da esquerda → **SQL Editor**. Para cada arquivo: **New query** (aba
nova, nunca cole embaixo de outra coisa), cole o arquivo **inteiro**, **Run**.
Tem que aparecer *Success*. Se vier erro em vermelho, me manda a mensagem
antes de seguir.

| Ordem | Arquivo | O que cria |
|---|---|---|
| 1º | `supabase-tracking-c.sql` | `quiz_eventos` (o funil) e `quiz_config` |
| 2º | `supabase-popup-c.sql` | `quiz_leads` (nome e WhatsApp) e a função de resumo |
| 3º | `supabase-ftd-c.sql` | `quiz_depositos` e o resumo de FTD — **opcional** |

O 3º só faz sentido quando alguém for gravar os depósitos no banco. Sem ele
o painel funciona igual, só esconde o bloco de FTD.

Conferência: **Table Editor** → têm que existir `quiz_eventos`, `quiz_config`
e `quiz_leads`.

> **Por que os leads ficam numa tabela separada:** a chave anon fica visível
> no HTML do quiz, que é público. Se ela pudesse **ler** `quiz_leads`,
> qualquer pessoa que abrisse o código-fonte baixaria a lista de nomes e
> telefones dos seus leads. Por isso o anon só **escreve** ali e nunca lê.
>
> Para ver os leads: Supabase → **Table Editor** → `quiz_leads`, logado. Dá
> pra exportar CSV por lá. O painel mostra só a **contagem**, nunca o dado
> pessoal.

### 3. Pegar as credenciais

1. Menu → **Project Settings** (engrenagem) → **API**.
2. Copie os dois valores:
   - **Project URL** — algo como `https://xxxxxxxx.supabase.co`
   - **Project API keys → `anon` `public`** — a chave longa que começa com `eyJ...`

> **Atenção:** copie só a **anon public**. A `service_role` e a senha do banco
> nunca saem do painel do Supabase — elas dão acesso total e não podem entrar
> em arquivo nenhum do quiz.

### 4. Colar nos dois arquivos

Em **`quiz-c/index.html`**, no bloco `var CONFIG` (perto da linha 836):

```js
supabaseUrl: 'https://xxxxxxxx.supabase.co',
supabaseChave: 'eyJhbGciOi...'
```

Em **`painel-c/index.html`**, no `var CONFIG` do topo do script: os
**mesmos dois valores**.

Confira que não sobrou nenhum `gmfxivkgbldcngoarjtv` em nenhum dos dois —
esse é o projeto do B, e o C não deve tocar nele.

### 5. Publicar

Duas URLs separadas:

- **o quiz**: suba a pasta `quiz-c/` (ou só o `index.html`). É a URL do tráfego.
- **o painel**: suba a pasta `painel-c/` **inteira**, com o `_headers` junto.
  Essa URL é só de vocês.

Nunca junte os dois no mesmo site: a URL do anúncio é pública, a do painel não.

### 6. Testar antes de subir tráfego

1. Abra o quiz, preencha o popup e responda até o fim marcando a **opção 1**
   na última pergunta. O botão tem que levar pro `t.me/SuporteTradingPro`.
2. Faça de novo marcando a **opção 3** ("Não tenho nenhum investimento").
   Tem que levar pra comunidade.
3. Abra o painel. As duas sessões aparecem em até 15 segundos.
4. Se não aparecer: F12 → aba **Network**, recarregue e veja a chamada pro
   `supabase.co`. **401** = chave errada. **404** = URL errada ou SQL não rodado.

---

## O que muda em relação ao B

| | Quiz B | Quiz C |
|---|---|---|
| Layout, cores, animações, camuflagem | — | **idênticos** |
| Pixel e eventos | — | **idênticos** |
| Popup de captura | — | **idêntico** |
| Perguntas | as do B | **as do quiz A** |
| Destino do especialista | `app.massflow.tech/api/r/redirecionamento` | **`t.me/SuporteTradingPro`** |
| Destino da comunidade | — | **igual** |
| Banco | `gmfxivkgbldcngoarjtv` | **projeto próprio** |
| `variacao` nos dados | `B` | `C` |

---

## As 5 perguntas (as do quiz A)

**Pergunta 1 — define a trilha:**
"O que mais te chamou atenção no anúncio?"

| Trilha | Perfil no resultado |
|---|---|
| `automacao` | Movido por Automação |
| `comecar` | Começando do Zero Absoluto |
| `liberdade` | Em busca de Liberdade Operacional |
| `renda` | Construindo uma Nova Fonte de Renda |

As perguntas **2 e 3** mudam conforme a trilha.

**Pergunta 4** (igual pra todos): "Você já investiu?"

**Pergunta 5** (igual pra todos, é a única que decide o destino):
"Você teria de R$ 100,00 a R$ 300,00 para iniciar hoje?"

- "Sim, R$ 100 a R$ 300" → especialista (Telegram)
- "Sim, R$ 500 a R$ 1.000" → especialista (Telegram)
- "Não tenho nenhum investimento" → comunidade

---

## Pixel da Meta

Pixel `1598167835188754`, o mesmo do B, instalado do mesmo jeito.

```js
fbq('set', 'autoConfig', false, '1598167835188754');   // ANTES do init
fbq('init', '1598167835188754');
```

O `autoConfig: false` **antes** do `init` é obrigatório: sem ele o Pixel lê
sozinho o texto de todo botão clicado e manda pra Meta no
`SubscribedButtonClick` — e o texto do botão **é a resposta da pessoa**.

Só saem 4 eventos, todos **sem nenhum parâmetro**:

| Evento | Quando |
|---|---|
| `PageView` | abriu a página |
| `quiz_iniciado` | clicou em começar |
| `QuizCompleto` | chegou no resultado |
| `Lead` | clicou no CTA |

Resposta, perfil, score e destino ficam **só** no seu Supabase. Nada disso
vai pra Meta.

---

## Popup de captura

Liga e desliga no `var CONFIG`, sem mexer em mais nada:

```js
popupLigado: true,      // false desliga o popup inteiro
popupAtrasoMs: 0,       // 0 = abre junto com a página
popupLembrarDias: 0,    // 0 = trava sempre. 7 = lembra por 7 dias
popupAvisaMeta: false,  // a entrada do popup não vira evento na Meta
```

Onde cada coisa é gravada:

| | Onde | O anon pode |
|---|---|---|
| Nome e WhatsApp | `quiz_leads` | só escrever |
| Evento `lead` (sem dado pessoal) | `quiz_eventos` | escrever e ler |

Se o Supabase estiver fora do ar ou sem credencial, o popup espera no máximo
2 segundos e libera a pessoa assim mesmo.

---

## Arquivos

| Arquivo | O que é |
|---|---|
| `index.html` | o quiz inteiro, sem build, sem dependência |
| `supabase-tracking-c.sql` | 1º — tabelas de evento, índices e regras de acesso |
| `supabase-popup-c.sql` | 2º — tabela de leads do popup e o resumo do painel |
| `supabase-ftd-c.sql` | 3º, opcional — depósitos (FTD) e o resumo por telefone |
| `README.md` | este guia |
