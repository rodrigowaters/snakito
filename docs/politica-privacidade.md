# Política de Privacidade do Snakito

**Última atualização:** 21 de agosto de 2026
**Aplicativo:** Snakito (`com.rodrigowaters.snakito`)
**Responsável:** Rodrigo Silva — contato: `<PREENCHER: e-mail de contato público>`

O Snakito é um jogo educacional para crianças a partir de 7 anos. Esta
política explica, em linguagem direta, **exatamente** quais dados o jogo
coleta, por quê, com quem eles são compartilhados e como apagá-los.

Princípio que guia o projeto: **coletar o mínimo**. O jogo é jogável
100% offline; nada do que você joga precisa sair do aparelho para o jogo
funcionar.

---

## 1. O que fica só no seu aparelho

Estes dados **nunca são enviados** para nenhum servidor. Ficam num
arquivo do próprio app e desaparecem se você desinstalar o jogo:

- Moedas e tickets
- Skin equipada e skins compradas
- Níveis dos buffs (velocidade, ímã, pontos iniciais)
- Ajustes: sons, música, vibração, lado do botão de turbo
- Recompensa diária (data da última coleta e dia da sequência)
- Estatísticas locais: recorde de pontos, total de cobras devoradas,
  melhor posição, desafios concluídos

## 2. O que é enviado quando você cria uma conta

A conta é opcional para jogar e obrigatória apenas para o **ranking
global**. Ela é criada com **Google Sign-In** — o jogo nunca vê nem
guarda a sua senha do Google.

**Dados da conta**

| Dado | Para quê |
|---|---|
| E-mail (do Google) | Identificar a conta. Fica no serviço de autenticação; o jogo não copia o e-mail para as tabelas do jogo |
| Apelido escolhido | Aparecer no ranking. É a **única** informação visível para outros jogadores |
| Data de criação da conta | Mostrar "jogando desde …" no seu perfil |
| Carimbo de consentimento do responsável | Registrar que um responsável autorizou o uso por criança menor de 13 anos. **A idade em si não é coletada** — guardamos apenas a data e hora da autorização |

**Dados de partida** (enviados ao fim de cada partida, para o ranking e
para a análise pós-partida)

Semente da arena, horário de início, duração, posição final, pontuação,
nível alcançado, número de cobras devoradas, comidas coletadas, qual
desafio foi jogado e se foi concluído, níveis dos seus buffs e a versão
do aplicativo.

Do ranking semanal, guardamos sua melhor pontuação, total de abates e
número de partidas na semana.

**O que NÃO é coletado:** localização, lista de contatos, fotos,
microfone, câmera, histórico de navegação, identificadores de
publicidade para perfilamento, e nenhum dado de pagamento.

## 3. Compras dentro do app

As compras são processadas **inteiramente pelo Google Play**. O jogo
**não vê e não recebe** dados de cartão, endereço ou cobrança.

Do Google Play recebemos apenas o **recibo** da compra, que é conferido
no nosso servidor para liberar o item. Guardamos: o identificador do
recibo, o produto comprado, o que foi liberado e a data. Isso existe
para que a mesma compra não seja liberada duas vezes e para que você
possa restaurar suas compras em outro aparelho.

## 4. Anúncios

O jogo exibe **anúncios recompensados** do Google AdMob: eles só
aparecem quando você **escolhe** assistir (por exemplo, para renascer
numa partida). Não há anúncios que interrompem o jogo.

Por ser um aplicativo dirigido a crianças, o jogo marca todas as
requisições de anúncio como **conteúdo dirigido a crianças**
(`tagForChildDirectedTreatment`) e para **usuário abaixo da idade de
consentimento** (TFUA), limitando o conteúdo à classificação **G**.
Consequência prática: os anúncios **não são personalizados** e não são
usados para criar um perfil de interesses.

O SDK do Google pode processar dados técnicos do aparelho (como modelo e
versão do sistema) para exibir o anúncio, limitar quantas vezes ele
aparece e prevenir fraude. Onde a lei exige, o formulário de
consentimento do Google (UMP) é apresentado, e você pode revê-lo em
**Configurações → Privacidade e responsáveis**.

Quem compra "Remover anúncios" deixa de ver anúncios — e o aplicativo
para de solicitá-los.

## 5. Relatórios de erro

Quando o jogo trava, enviamos um relatório técnico ao **Sentry** para
corrigir o problema. O relatório contém a pilha do erro, modelo do
aparelho, versão do Android e versão do jogo. **Não anexamos** seu
e-mail, seu apelido nem os registros do jogo.

## 6. Com quem os dados são compartilhados

Somente com os serviços necessários para o jogo funcionar:

| Serviço | Papel |
|---|---|
| **Google** (Sign-In, Play Billing, AdMob) | Login, compras e anúncios |
| **Supabase** | Banco de dados e servidor do ranking — dados hospedados em **São Paulo, Brasil** |
| **Sentry** | Relatórios de erro |

Nunca vendemos dados. Nunca compartilhamos dados para publicidade
direcionada ou perfilamento.

## 7. Crianças

O Snakito é feito para crianças e segue a **Política de Famílias do
Google Play**.

- Não existe chat, mensagem, comentário ou qualquer conteúdo escrito por
  um jogador para outro. A única informação visível a terceiros é o
  **apelido** — por isso, escolha um apelido que não seja seu nome
  completo
- Se a criança indicar ter menos de 13 anos, o jogo pede a autorização de
  um **responsável** antes de criar a conta; sem isso, a conta não é
  criada e o jogo segue funcionando offline
- Anúncios não personalizados, classificação G, como descrito acima

## 8. Seus direitos

- **Apagar tudo:** dentro do jogo, em **Configurações → Excluir conta e
  dados**. A exclusão remove a conta, o perfil, o histórico de partidas,
  a posição no ranking e os direitos de compra. É imediata e definitiva
- **Mudar o apelido:** em **Informações do jogador**, pelo ícone de lápis
- **Jogar sem conta:** basta não entrar; todo o jogo, exceto o ranking
  global, funciona offline
- **Pedidos e dúvidas:** escreva para o contato no topo desta página

Os dados ficam armazenados enquanto a conta existir. Ao excluí-la, são
removidos dos nossos bancos.

## 9. Mudanças nesta política

Se algo mudar no que coletamos, atualizamos esta página e a data no topo.
Mudanças relevantes serão avisadas dentro do jogo.
