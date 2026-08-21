# Publicar o Snakito — passo a passo

> A ordem importa: o Play só libera a seção de **produtos no app** depois
> de receber um build assinado que contenha a biblioteca de Billing.
> Então: keystore → AAB → faixa interna → produtos.

## 1. Upload key (uma vez, na máquina do Rodrigo)

A senha da keystore **não passa pelo Claude e não entra no repositório**.
Rodar no terminal, escolhendo uma senha e guardando no gerenciador:

```bash
keytool -genkeypair -v \
  -keystore ~/.android/snakito-upload.keystore \
  -alias snakito-upload \
  -keyalg RSA -keysize 4096 -validity 10000
```

Guardar **arquivo + senha + alias**. Perder a upload key não é fatal (o
Google reemite, com espera), mas dá dor de cabeça.

Depois, exportar as variáveis que o Godot lê — conferidas no binário
4.7.1 (`GODOT_ANDROID_KEYSTORE_RELEASE_*`). No shell da sessão de build,
nunca em arquivo versionado:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/.android/snakito-upload.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="snakito-upload"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="<a senha>"
```

## 2. AAB de release

```bash
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
  godot --headless --path . --export-release "Android AAB" export/snakito.aab
```

`version/code` no `export_presets.cfg` sobe **a cada upload** (o Play
recusa código repetido). Hoje: 1.

## 3. Criar o app no Play Console

**Já criado (21/08).** Referências (não são segredo — só quem está na
conta abre):

- Conta de desenvolvedor: `5983884273304023551`
- App: `4975216188373581147`
- Painel: <https://play.google.com/console/u/0/developers/5983884273304023551/app/4975216188373581147/app-dashboard>
- Política de privacidade publicada:
  <https://rodrigowaters.github.io/snakito/politica-privacidade.html>

Valores usados na criação:

- Nome **Snakito** · idioma padrão **português (Brasil)** · **Jogo** · **Gratuito**
- Declarações: leis de exportação dos EUA + diretrizes do programa
- **Público-alvo e conteúdo**: faixa **6–8 anos** (o app é 7+). É isso que
  liga a **política de Famílias** — a mesma razão de o código mandar
  `tagForChildDirectedTreatment` + TFUA + classificação G no AdMob
- **Anúncios**: sim, o app contém anúncios
- **Política de privacidade**: URL obrigatória para Famílias
- **Segurança dos dados**: coleta = apelido, e-mail (só em `auth.users`) e
  estatísticas de partida; tudo em trânsito por HTTPS; o usuário pode
  pedir exclusão **dentro do app** (tela Conta faz isso de verdade)
- **Classificação de conteúdo**: questionário → deve sair "Livre"

## 4. Faixa interna

Enviar o AAB em **Teste interno**, adicionar o e-mail do Rodrigo como
testador e aceitar o convite no aparelho. Sem isso o Billing não responde
nem em build de debug.

## 5. Produtos no app

IDs **exatamente** estes — o servidor recusa id desconhecido (ver
`supabase/functions/validate_purchase/index.ts` e
`src/ui/loja/catalogo_produtos.gd`, mantidos em sincronia por teste):

| ID | Tipo | O que concede |
|---|---|---|
| `remover_anuncios` | Não consumível | entitlement `ads_removed` |
| `combo_turbinado` | Não consumível | `ads_removed` + 500 moedas |
| `combo_sem_interrupcao` | Não consumível | `ads_removed` + 10 tickets |
| `moedas_500` | Consumível | 500 moedas |
| `moedas_1200` | Consumível | 1.200 moedas |
| `moedas_3000` | Consumível | 3.000 moedas |
| `tickets_5` | Consumível | 5 tickets |
| `tickets_15` | Consumível | 15 tickets |
| `tickets_40` | Consumível | 40 tickets |

Os pacotes de skin (`pacote_neon`, `pacote_cosmico`) existem no catálogo
mas estão `vendavel = false` até o render de padrão em jogo existir —
criar no console pode esperar.

O **preço** é definido no console, por país; o app exibe o que o Play
devolver (nunca um valor fixo no código).

## 6. Validação de recibo (Supabase)

1. Play Console → Configurações → **Acesso à API**: vincular projeto do
   Google Cloud e criar uma **service account** com permissão de ver
   pedidos/dados financeiros
2. Baixar o JSON da conta de serviço
3. Guardar como secret da Edge Function: `GOOGLE_SERVICE_ACCOUNT_JSON`
   (o valor é o JSON inteiro)
4. Aplicar a migration `0007_compras.sql` e publicar `validate_purchase`

Sem o secret a função devolve **503** e nada é concedido — de propósito:
nunca conceder sem validar.

## 7. Ficha da loja (assets)

- Ícone 512×512: `assets/icone/png/loja_512.png`
- Gerar/atualizar todos os ícones: `godot --headless --quit-after 60 -s tools/gerar_icones.gd`
- Gráfico de destaque 1024×500: `assets/loja/destaque_1024x500.png`
  (gerar: `godot --path . --quit-after 90 -s tools/gerar_destaque.gd` —
  precisa de janela). Composto com os tokens do jogo, e a arte fica longe
  das bordas porque o Play recorta em algumas vitrines
- Screenshots (mínimo 2, temos 5): `assets/loja/screenshots/`
  — gerar: `godot --path . --quit-after 12000 -s tools/gerar_screenshots.gd`
  (precisa de janela). O 1º é **gameplay real**: a cena roda e um piloto
  persegue comida até a cobra crescer, porque cobra tamanho 1 em "30º de
  31" não vende. Para escolher o melhor instante:
  `... -s tools/gerar_screenshots.gd -- --candidatos` gera uma série e
  você promove a que preferir
- Cuidados que o script já resolve: esconde o botão "Crash de teste"
  (existe só em debug e pareceria bug), coleta a recompensa diária antes
  de fotografar a Home (senão a modal cobre a tela) e preenche
  `Sessao.moedas_ganhas` para a pós-partida não mostrar "+0" falso
