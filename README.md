# Central de Contingência

Sistema operacional de tráfego pago para Meta Ads em nicho sensível.
Projeto autônomo — sem vínculo com nenhum outro sistema.

## O que resolve

| Frente | Onde |
|---|---|
| Escalar campanhas | Hoje · Painel de Escala |
| Validar criativo antes de subir | Validar Criativo |
| Evitar strike | Health Score · Runbook |
| Contingência de malha | Malha de Estruturas |

## Como rodar

Arquivo único, sem build e sem dependência. Abra `index.html` no navegador,
ou publique a pasta em qualquer hospedagem estática.

## Onde ficam os dados

No `localStorage` do navegador que você usa. Isso significa:

- Use sempre o mesmo navegador, no mesmo aparelho.
- Gere o backup (Painel → Gerar backup) toda semana e guarde o texto.
- Limpar dados do navegador apaga tudo. O backup é a única rede.

Para compartilhar com o time e ter histórico que sobrevive ao cache,
rode `supabase.sql` num projeto Supabase próprio e conecte.

## Rotina

**Manhã (2 min)** — abre em Hoje, resolve os críticos de cima pra baixo,
clica em aplicar as subidas, replica os budgets no Gerenciador.

**Durante o dia** — conta caiu: botão `Caiu` na Malha.
Anúncio reprovado: botão `+` ao lado de "rej", escolhendo o motivo.

**Sexta (10 min)** — importa o CSV do Gerenciador na Malha e gera o backup.

## Importante

O sistema não escreve no Gerenciador de Anúncios. Ele decide e registra;
a execução na Meta é manual, de propósito.

## Arquivos

- `index.html` — o sistema inteiro
- `supabase.sql` — schema para o passo de banco compartilhado
- `modelo-estruturas.csv` / `modelo-informativos.csv` — modelos de importação
