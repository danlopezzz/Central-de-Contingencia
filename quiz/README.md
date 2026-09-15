# Quiz de Qualificação — Trader Pro

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

## Regra de roteamento do lead

O destino é decidido **exclusivamente pela pergunta 4** (capital):

| Resposta na pergunta 4        | Destino    |
| ----------------------------- | ---------- |
| A — R$ 50                     | WhatsApp   |
| B — R$ 100                    | WhatsApp   |
| C — R$ 200 ou mais            | WhatsApp   |
| D — Não tenho capital         | Comunidade |

As perguntas 1, 2 e 3 não mudam o destino — elas personalizam o texto do
resultado e alimentam o score, o que aumenta a percepção de diagnóstico real
antes do clique.

---

## Onde mexer

Tudo que você normalmente vai querer alterar está no bloco `CONFIG`, no topo do
`<script>` (por volta da linha 817 do `index.html`):

```js
var CONFIG = {
  redirectWhats:        'https://app.massflow.tech/api/go/whats-trading-pro-h91aeoh9k8',
  redirectComunidade:   'https://app.massflow.tech/api/go/comunidade-traderpro-tpnra3ppsd',
  repassarParametros:   true,   // repassa utm_source, utm_campaign etc. para o destino
  autoRedirectSegundos: 0,      // 0 = só redireciona no clique. Ex: 12 = redireciona sozinho
  tempoAnalise:         3400    // duração da tela "Analisando suas respostas..."
};
```

Outros pontos de edição:

- **Textos dos perfis e do resultado**: objeto `PERFIS`.
- **Pesos do score**: objeto `PONTOS`.
- **Perguntas e alternativas**: as seções `<section id="screen-q1">` … `screen-q4`.
  Para mudar o destino de uma alternativa, troque o atributo `data-destino`
  (`"whats"` ou `"comunidade"`).
- **Cores da marca**: variáveis CSS em `:root` (`--green`, `--green-bright`, `--bg`…).
- **Logo**: SVG no `<symbol id="logo-mark">`, desenhado em vetor — escala sem perder
  qualidade e não depende de arquivo de imagem externo.

---

## Rastreamento

O quiz já dispara eventos, sem precisar de configuração:

| Evento             | Quando acontece                                  |
| ------------------ | ------------------------------------------------ |
| `quiz_visualizado` | página carregou                                  |
| `quiz_iniciado`    | clique em "Começar agora"                        |
| `quiz_resposta`    | cada resposta (envia pergunta e valor escolhido)  |
| `quiz_finalizado`  | tela de resultado (envia destino, score e perfil) |
| `quiz_cta_clique`  | clique no botão final                            |

Eles vão para `window.dataLayer` (GTM), `gtag` (GA4) e `fbq` (Meta Pixel) quando
esses scripts existirem na página. Para ativar o Pixel, cole o snippet da Meta
dentro do `<head>` — o resto funciona sozinho. No Meta, `quiz_cta_clique` é
enviado como evento padrão **Lead**.

---

## Detalhes de implementação

- Fundo com candlesticks em `<canvas>`, gerados por código e em movimento contínuo.
- Radar animado na tela de análise + confete na tela de resultado.
- Navegação por teclado: `A`–`E` ou `1`–`5` respondem, `Backspace` volta, `Enter` inicia.
- Vibração tátil no celular a cada resposta (onde o aparelho suporta).
- Botão "Voltar" preserva a resposta já marcada.
- `prefers-reduced-motion` respeitado: desliga canvas, confete e transições.
- A página é `noindex` por padrão (tráfego pago). Para permitir indexação, remova a
  meta tag `robots` do `index.html` e o header `X-Robots-Tag` do `vercel.json`.
