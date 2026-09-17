# Quiz Trading Pro — Variação B

Variação completa do quiz para rodar em paralelo com a versão A, com o
**mesmo funil e os mesmos redirects**, mas com layout, animações, tom de
verde e perguntas totalmente diferentes.

O objetivo é ter dois criativos de página distintos rodando ao mesmo tempo
para comparar parâmetros reais (taxa de conclusão, ponto de abandono,
qualidade do lead que chega no WhatsApp).

Nada da versão A foi alterado. `quiz/` e `painel/` continuam exatamente
como estavam.

---

## O que muda em relação à versão A

| | Versão A | Versão B |
|---|---|---|
| Verde | `#00E08A` neon | `#00D68F` esmeralda, fundo mais fechado |
| Fontes | Sora + Inter | Outfit + DM Sans |
| Estrutura | cartões centralizados | trilha vertical de etapas + linhas largas |
| Transição | vertical (sobe/desce) | horizontal (desliza pro lado) |
| Fundo | grade + partículas | arcos de sonar + linha de tendência |
| Análise | barra de progresso | log de terminal em fonte monoespaçada |
| Resultado | barra horizontal | anel/velocímetro em SVG |
| Perguntas | todas diferentes | todas diferentes |
| Capa (copy) | **igual** | **igual** |
| Redirects | **iguais** | **iguais** |

O que **não** muda, de propósito:

- headline e texto da capa
- os dois destinos (especialista e comunidade)
- a regra de roteamento: só a pergunta 5 decide o destino
- o Pixel da Meta e os eventos disparados
- a espera de 350 ms antes de navegar, pro Pixel sair antes

---

## As 5 perguntas

**Pergunta 1 (define a trilha) — igual para todo mundo:**
"O que faria mais diferença na sua vida financeira nos próximos 90 dias?"

As respostas abrem quatro trilhas, e as perguntas 2 e 3 mudam conforme a trilha:

| Trilha | Perfil no resultado |
|---|---|
| `tempo` | Quer Renda, Não Quer Outro Emprego |
| `processo` | Tem Vontade, Falta o Sistema |
| `passivo` | Pronto para Delegar a Execução |
| `zero` | Começando Agora, do Jeito Certo |

**Pergunta 4** (igual para todos): "Qual foi o maior valor que você já teve investido?"

**Pergunta 5** (igual para todos, é a que decide o destino):
"Você tem entre R$ 100 e R$ 300 disponíveis para começar hoje?"

- opção 1 e 2 → especialista (`/api/r/vanessa`)
- opção 3 (não tenho) → comunidade

---

## Passo a passo: criar o projeto novo no Supabase

Faça um projeto **separado** do que já existe. É o ponto central do teste:
os números das duas variações precisam ficar em bases diferentes, senão não
dá pra comparar nada.

### 1. Criar o projeto

1. Entre em https://supabase.com e faça login.
2. Clique em **New project**.
3. Preencha:
   - **Name**: `trading-pro-quiz-b` (qualquer nome serve, mas deixe claro que é o B)
   - **Database Password**: gere uma senha forte e **guarde no seu gerenciador de senhas**.
     Você não vai precisar dela pro quiz nem pro painel. Nunca cole essa senha
     em chat, e-mail ou arquivo do projeto.
   - **Region**: `South America (São Paulo)` — é a mais perto, responde mais rápido.
4. **Create new project** e espere uns 2 minutos até ficar verde.

### 2. Criar as tabelas

1. Menu da esquerda → **SQL Editor**.
2. Clique em **New query** (aba nova, não cole embaixo de nada que já exista).
3. Abra o arquivo `supabase-tracking-b.sql` desta pasta, copie **tudo** e cole.
4. Clique em **Run**.
5. Tem que aparecer *Success. No rows returned*. Se aparecer erro em vermelho,
   copie a mensagem e me mande antes de seguir.

Para conferir: menu → **Table Editor**. Devem existir `quiz_eventos` e `quiz_config`.

### 3. Pegar as credenciais

1. Menu → **Project Settings** (engrenagem) → **API**.
2. Copie os dois valores:
   - **Project URL** — algo como `https://xxxxxxxx.supabase.co`
   - **Project API keys → `anon` `public`** — a chave longa que começa com `eyJ...`

> **Atenção:** copie só a chave **anon public**. A chave `service_role` e a
> senha do banco nunca saem do painel do Supabase — elas dão acesso total e
> não podem ir pra dentro de arquivo nenhum do quiz.
>
> A `anon public` é feita pra ficar no navegador e por isso é segura aqui:
> as regras de RLS criadas pelo SQL só deixam ela **inserir** e **ler**
> eventos, nada mais.

### 4. Colar as credenciais nos dois arquivos

Abra **`quiz-b/index.html`**, procure o bloco `var CONFIG` (perto da linha 670)
e preencha:

```js
supabaseUrl: 'https://xxxxxxxx.supabase.co',
supabaseChave: 'eyJhbGciOi...'
```

Abra **`painel-b/index.html`**, procure o mesmo `var CONFIG` no topo do script
e preencha os **mesmos dois valores**.

Se você deixar em branco, o quiz continua funcionando normalmente — ele só
não registra nada. É de propósito: rastreamento nunca pode derrubar o funil.

### 5. Publicar

São **duas URLs separadas na Netlify**, igual você fez com a versão A:

- **Site 1 — o quiz**: arraste a pasta `quiz-b/` (ou só o `index.html`).
  Essa é a URL que vai no tráfego.
- **Site 2 — o painel**: arraste a pasta `painel-b/` inteira, com o arquivo
  `_headers` junto. Essa URL é só pra vocês dois.

Nunca junte os dois no mesmo site: a URL do anúncio é pública, a do painel não.

### 6. Testar antes de subir tráfego

1. Abra a URL do quiz e responda até o final escolhendo a opção **1** na
   pergunta 5. Confira que o botão leva pro especialista.
2. Faça de novo escolhendo a opção **3**. Confira que leva pra comunidade.
3. Abra a URL do painel. As duas sessões têm que aparecer em até 15 segundos.
4. Se não aparecer: abra o painel, aperte F12 → aba **Network**, recarregue e
   veja se a chamada pro `supabase.co` volta **200**. Se voltar 401, a chave
   está errada; se voltar 404, a URL está errada.

---

## Arquivos

| Arquivo | O que é |
|---|---|
| `index.html` | o quiz inteiro, sem build, sem dependência |
| `supabase-tracking-b.sql` | cria as tabelas, os índices e as regras de acesso |
| `README.md` | este guia |

---

## Pixel da Meta

O Pixel `1057320473675949` já está instalado, o mesmo da versão A. Todo evento
enviado leva `variacao: 'B'` junto, então dá pra separar as duas no Gerenciador
de Eventos sem precisar de um Pixel novo.

Eventos disparados: `PageView`, `IniciouQuiz`, `RespondeuPergunta` (um por
pergunta, com `eventID` próprio pra Meta não deduplicar), `VerResultado` e
`Lead` no clique do botão.
