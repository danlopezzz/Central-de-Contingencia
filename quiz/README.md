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

São sempre 4 perguntas, mas só duas são iguais para todo mundo:

| # | Pergunta | Varia? |
| - | -------- | ------ |
| 1 | O que mais te chamou atenção no anúncio? | Fixa — é ela que define a trilha |
| 2 | Aprofunda o desejo que trouxe a pessoa | **Muda conforme a trilha** |
| 3 | Mede o contexto real (tempo, experiência, meta…) | **Muda conforme a trilha** |
| 4 | Quanto de capital você pretende investir? | Fixa — é ela que decide o destino |

A pergunta 1 não pergunta a dor: pergunta o **desejo que fez a pessoa clicar**.
Por isso ela funciona para qualquer público que o anúncio traga, do leigo ao
trader experiente — todo mundo sabe responder o que chamou a sua atenção. É a
pergunta 2 que desce ao nível de quem a pessoa é de fato.

As 4 trilhas, conforme a resposta da pergunta 1:

| Respondeu na pergunta 1 | Perfil no resultado | Pergunta 2 | Pergunta 3 |
| ----------------------- | ------------------- | ---------- | ---------- |
| Ferramenta 100% automatizada | Movido por Automação | Como está sua relação com o mercado hoje | O que quer que a ferramenta resolva |
| Iniciar sem dinheiro e sem tempo | Começando do Zero Absoluto | O que mais te impede de começar | Tempo que conseguiria reservar |
| Operar sem olhar o mercado sempre | Em busca de Liberdade Operacional | O que te atrapalha por não acompanhar | Janela real por dia |
| Conquistar uma nova fonte de renda | Construindo uma Nova Fonte de Renda | O que espera dessa renda | Já teve experiência no mercado |

Cada alternativa das perguntas 2 e 3 carrega o próprio texto de resultado, então o
diagnóstico final é montado com as palavras da trilha que a pessoa percorreu — não
com um texto genérico. São **64 combinações de diagnóstico** (4 trilhas × 4 × 4).

## Regra de roteamento do lead

O destino é decidido **exclusivamente pela pergunta 4** (capital):

| Resposta na pergunta 4        | Destino    |
| ----------------------------- | ---------- |
| A — R$ 100 a R$ 200           | WhatsApp   |
| B — R$ 201 a R$ 500           | WhatsApp   |
| C — R$ 501 a R$ 1.000         | WhatsApp   |
| D — Não tenho capital         | Comunidade |

Nenhuma outra pergunta muda o destino: elas alimentam o score e personalizam o
resultado, para o lead chegar no CTA já tendo recebido um diagnóstico.

Se a pessoa voltar e trocar a resposta da pergunta 1, a trilha é remontada e as
respostas das perguntas 2 e 3 são descartadas — elas pertenciam ao perfil antigo.

## Onde mexer

Tudo que você normalmente vai querer alterar está no bloco `CONFIG`, no topo do
`<script>` (por volta da linha 700 do `index.html`):

```js
var CONFIG = {
  redirectWhats:        'https://app.massflow.tech/api/go/whats-trading-pro-h91aeoh9k8',
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

## Rastreamento

O quiz já dispara eventos, sem precisar de configuração:

| Evento             | Quando acontece                                  |
| ------------------ | ------------------------------------------------ |
| `quiz_visualizado` | página carregou                                  |
| `quiz_iniciado`    | clique em "Começar agora"                        |
| `quiz_resposta`    | cada resposta (envia pergunta, valor e perfil)   |
| `quiz_finalizado`  | tela de resultado (destino, score, perfil e trilha) |
| `quiz_cta_clique`  | clique no botão final                            |

Eles vão para `window.dataLayer` (GTM), `gtag` (GA4) e `fbq` (Meta Pixel) quando
esses scripts existirem na página. Para ativar o Pixel, cole o snippet da Meta
dentro do `<head>` — o resto funciona sozinho. No Meta, `quiz_cta_clique` é
enviado como evento padrão **Lead**.

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
