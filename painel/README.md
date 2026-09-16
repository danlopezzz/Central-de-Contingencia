# Painel do Quiz — Trading Pro

Este é um site **separado** do quiz, de propósito.

O quiz é divulgado no tráfego. Se o painel morasse no mesmo endereço, qualquer
pessoa que recebesse o anúncio poderia tentar `/painel` e ver a lista de leads.
Em dois sites, o endereço do painel não tem relação nenhuma com o do quiz e não
há como chegar nele a partir do link divulgado.

## Como publicar

Publique **esta pasta** como um site próprio na Netlify, separado do quiz.

1. Acesse [app.netlify.com](https://app.netlify.com) > **Add new site** > **Deploy manually**
2. Arraste **a pasta `painel/`** (não a do quiz)
3. O Netlify gera um endereço aleatório, tipo `dazzling-pastry-a1b2c3.netlify.app`
4. Em **Site configuration > Change site name**, troque para algo que ninguém
   adivinhe. Evite `painel-tradingpro` ou `quiztradingpro-painel`: o graça é
   justamente não ter relação com o nome do quiz

Guarde o endereço com a diretoria. Ele não é divulgado em lugar nenhum, não é
indexado pelo Google (`noindex` na página e no `_headers`) e não aparece em
nenhum link do quiz.

## Configuração

As credenciais do Supabase já estão no `index.html`, no bloco `CONFIG` do topo.
São as mesmas do quiz: os dois falam com o mesmo banco, o quiz escrevendo e o
painel lendo.

Para ver o painel funcionando sem banco nenhum, abra com `?demo=1` no fim.

## Quem consegue entrar

Qualquer pessoa com o endereço. Não há senha, foi uma escolha para simplificar.
O que protege é o endereço não ser divulgado nem indexado.

Se um dia quiser trancar de verdade, dá para religar uma tela de acesso.
