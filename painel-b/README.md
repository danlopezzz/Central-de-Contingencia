# Painel de Rastreamento — Variação B

Painel em tempo real da variação B do quiz. Site **separado** do quiz e
separado do painel da versão A.

Lê direto do projeto Supabase da variação B. Nenhum dado das outras
variações aparece aqui.

---

## Publicar

1. Preencha as credenciais (passo 4 do `quiz-b/README.md`) antes de subir.
2. Netlify → **Add new site** → **Deploy manually**.
3. Arraste a pasta `painel-b/` **inteira** — o arquivo `_headers` precisa ir junto.
4. Guarde a URL. Não divulgue, não coloque em anúncio, não use como destino
   de link.

O `_headers` manda `noindex` pra não cair em busca do Google, bloqueia
carregamento dentro de iframe e não vaza a URL como referrer.

---

## O que o painel mostra

**Números do topo**
- visitas, quantos começaram, quantos terminaram
- taxa de conclusão
- leads que foram pro especialista e pra comunidade

**Funil vertical**
Quantas pessoas passaram por cada etapa e quantas caíram em cada uma.
É aqui que você vê em qual pergunta o pessoal desiste — o número que mais
importa pra comparar A e B.

**Ao vivo**
Quem está respondendo agora, em qual pergunta está, e de qual campanha veio.

**Trilhas e perfis**
Distribuição das quatro trilhas, pra saber qual público o criativo está trazendo.

**Campanhas**
Quebra por `utm_source`, `utm_campaign` e `utm_content`.

**Exportar CSV**
Baixa tudo, já com a coluna `variacao`, pra cruzar com o relatório da Meta
ou juntar com o CSV da versão A numa planilha só.

---

## Como comparar A e B

Abra os dois painéis lado a lado e olhe, na mesma janela de tempo:

1. **Taxa de conclusão** — qual layout segura mais gente até o fim.
2. **Onde cai** — se o B perde na pergunta 2 e o A na 4, o problema é a
   pergunta, não o layout.
3. **% que vai pro especialista** — qualidade do lead, não só volume.
4. **Conclusão por campanha** — às vezes uma variação vai melhor com um
   criativo específico e pior com outro.

Só compare períodos com volume parecido. Com menos de ~100 sessões de cada
lado, a diferença ainda é ruído.

---

## Atualização

O painel busca dados a cada 15 segundos e pede **só o que é novo** desde a
última busca, não a base inteira. Isso mantém o consumo baixo mesmo com o
painel aberto o dia todo.

Para testar o visual sem dados reais, abra a URL com `?demo=1` no final.
Ele gera sessões falsas só na tela, não grava nada no banco.

---

## Webhook

O disparo de webhook vem **desligado**. Se o diretor quiser receber os leads
no sistema dele, é preciso a URL que o sistema dele expõe pra receber —
aí a gente liga pelo Table Editor do Supabase, na tabela `quiz_config`.

A tabela `quiz_config` de propósito **não tem regra de acesso pública**: ela
só pode ser editada logado no painel do Supabase. Isso impede que alguém que
leia a chave anon no HTML do quiz (que é público, por natureza) redirecione
os seus leads pro servidor dele.

---

## Se o painel não mostrar nada

1. F12 → aba **Network** → recarregue.
2. Procure a chamada pro `supabase.co`:
   - **200** e o painel vazio → ainda não houve tráfego, ou o quiz está sem as credenciais.
   - **401** → a chave anon está errada ou incompleta.
   - **404** → a URL do projeto está errada, ou o SQL não foi rodado.
   - **nada aparece** → as credenciais estão em branco no `index.html`.
3. Confira que o `quiz-b/index.html` publicado tem as **mesmas** credenciais
   que o painel. É o erro mais comum: preencher num arquivo e esquecer do outro.
