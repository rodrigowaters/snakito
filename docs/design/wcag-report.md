# Relatório de contraste WCAG 2.1 AA — tokens do Snakito

> Gerado na importação do Claude Design (projeto `Design System Snakito`, v1.0).
> Fonte dos valores: `docs/design/snakito-tokens.json` → `src/ui/theme/tokens.gd`.
> Método: luminância relativa WCAG 2.1; superfícies com alpha foram **compostas**
> sobre o fundo real antes do cálculo (o design informava só a cor translúcida).

Limiares: **4.5:1** texto normal · **3.0:1** texto grande (≥24px, ou ≥18.66px negrito)
e componentes gráficos (cobras, comida, bordas, ícones).

## A · Texto e ícones sobre fundos de app e arena

| token | mín. exigido | arena/bg | arena/duelBg | app/bg ini | app/bg fim | surface/1 | surface/2 | vidro/app | vidro/s1 | hud/arena | pior caso |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `text/primary` #F4F6FF | 4.5:1 (texto normal) | 16.67 | 15.01 | 17.00 | 16.45 | 15.15 | 13.42 | 14.11 | 12.81 | 17.44 | **12.81:1** (vidro/s1) |
| `text/secondary` #A6AECB | 4.5:1 (texto normal) | 8.17 | 7.35 | 8.33 | 8.06 | 7.42 | 6.57 | 6.91 | 6.28 | 8.54 | **6.28:1** (vidro/s1) |
| `text/muted` #7E88A8 | 3.0:1 (**só texto grande**) | 5.12 | 4.61 | 5.22 | 5.05 | 4.65 | 4.12 | 4.33 | 3.93 | 5.35 | **3.93:1** (vidro/s1) |
| `semantic/success` #4ADE80 | 4.5:1 (texto normal) | 10.32 | 9.29 | 10.52 | 10.18 | 9.38 | 8.30 | 8.73 | 7.93 | 10.80 | **7.93:1** (vidro/s1) |
| `semantic/dangerText` #FF9B9B | 4.5:1 (texto normal) | 8.92 | 8.03 | 9.09 | 8.79 | 8.10 | 7.18 | 7.54 | 6.85 | 9.33 | **6.85:1** (vidro/s1) |
| `semantic/dangerAction` #FF6B6B | 3.0:1 (borda/ícone) | 6.48 | 5.83 | 6.61 | 6.39 | 5.89 | 5.21 | 5.48 | 4.98 | 6.78 | **4.98:1** (vidro/s1) |
| `semantic/warning` #FFD43B | 4.5:1 (texto normal) | 12.61 | 11.36 | 12.86 | 12.44 | 11.46 | 10.15 | 10.67 | 9.69 | 13.20 | **9.69:1** (vidro/s1) |
| `semantic/info` #8ADCFF | 4.5:1 (texto normal) | 11.78 | 10.61 | 12.01 | 11.62 | 10.71 | 9.48 | 9.97 | 9.06 | 12.33 | **9.06:1** (vidro/s1) |
| `semantic/adOffer` #FF9F45 | 4.5:1 (texto normal) | 8.82 | 7.94 | 8.99 | 8.70 | 8.01 | 7.10 | 7.46 | 6.78 | 9.22 | **6.78:1** (vidro/s1) |
| `rarity/rara` #38BDF8 | 4.5:1 (texto normal) | 8.39 | 7.56 | 8.56 | 8.28 | 7.63 | 6.75 | 7.10 | 6.45 | 8.78 | **6.45:1** (vidro/s1) |
| `rarity/epica` #A78BFA | 4.5:1 (texto normal) | 6.61 | 5.95 | 6.74 | 6.52 | 6.00 | 5.32 | 5.59 | 5.08 | 6.91 | **5.08:1** (vidro/s1) |
| `rarity/lendaria` #FFD43B | 4.5:1 (texto normal) | 12.61 | 11.36 | 12.86 | 12.44 | 11.46 | 10.15 | 10.67 | 9.69 | 13.20 | **9.69:1** (vidro/s1) |

## B · Texto sobre CTAs e badges coloridos

| texto | fundo | razão | AA 4.5:1 |
|---|---|---|---|
| `text/onPrimary #0B2416` | cta/primary #4ADE80 | 9.43:1 | ✅ |
| `text/onPrimary #0B2416` | cta/primary tom médio | 8.12:1 | ✅ |
| `text/onPrimary #0B2416` | cta/primary #2FBF8F | 7.02:1 | ✅ |
| `text/onAdOffer #3A1F00` | cta/ad #FF9F45 | 7.48:1 | ✅ |
| `text/onAdOffer #3A1F00` | cta/ad tom médio | 6.81:1 | ✅ |
| `text/onAdOffer #3A1F00` | cta/ad #F5893B | 6.20:1 | ✅ |
| `text/onWarning #3A2E00` | badge #FFD43B | 9.38:1 | ✅ |
| `text/onWarning #3A2E00` | cta/vip tom médio | 7.86:1 | ✅ |
| `text/onWarning #3A2E00` | cta/vip #FF9F45 | 6.56:1 | ✅ |

Os dois extremos do gradiente **e** o tom médio passam — o botão é legível em toda a sua extensão.

## C · Cobras contra o fundo da arena

| cobra | base | vs arena | vs duelo | tom escuro vs arena | símbolo | AA 3.0:1 | alegado no design |
|---|---|---|---|---|---|---|---|
| `snake/verde` | #4ADE80 | 10.32:1 | 9.29:1 | 5.56:1 | circulo | ✅ | 8.7:1 |
| `snake/azul` | #38BDF8 | 8.39:1 | 7.56:1 | 4.56:1 | triangulo | ✅ | 7.2:1 |
| `snake/rosa` | #F472B6 | 6.79:1 | 6.11:1 | 3.96:1 | quadrado | ✅ | 5.5:1 |
| `snake/amarela` | #FFD43B | 12.61:1 | 11.36:1 | 7.36:1 | losango | ✅ | 11.4:1 |
| `snake/laranja` | #FF9F45 | 8.82:1 | 7.94:1 | 4.92:1 | estrela | ✅ | 7.6:1 |
| `snake/roxa` | #A78BFA | 6.61:1 | 5.95:1 | 3.46:1 | hexagono | ✅ | 5.7:1 |
| `snake/turquesa` | #2DD4BF | 9.66:1 | 8.70:1 | 5.17:1 | cruz | ✅ | 8.5:1 |
| `snake/lima` | #BEF264 | 13.76:1 | 12.39:1 | 7.81:1 | meia-lua | ✅ | 12.5:1 |

As razões medidas são **iguais ou superiores** às alegadas no design — as declarações do
JSON eram conservadoras, nenhuma estava inflada.

## D · Distinção entre cobras (achado relevante)

WCAG não exige contraste objeto×objeto, mas o jogo exige: o jogador precisa distinguir
a própria cobra dos bots em movimento. Os pares mais próximos em luminância:

| par | contraste entre si | símbolos |
|---|---|---|
| rosa × roxa | 1.03:1 | quadrado × hexagono |
| azul × laranja | 1.05:1 | triangulo × estrela |
| verde × turquesa | 1.07:1 | circulo × cruz |
| amarela × lima | 1.09:1 | losango × meia-lua |
| laranja × turquesa | 1.10:1 | estrela × cruz |
| azul × turquesa | 1.15:1 | triangulo × cruz |

`rosa × roxa` a **1.03:1** são praticamente idênticas em luminância. Isto **não é um defeito**:
é exatamente o motivo pelo qual o modo daltonismo é obrigatório, e por que o símbolo
geométrico é o canal redundante — não um enfeite opcional.

## E · Comida contra a arena

| token | cor | vs arena | AA 3.0:1 |
|---|---|---|---|
| `food/comum` | #FF6B6B | 6.48:1 | ✅ |
| `food/comumHighlight` | #FF9B9B | 8.92:1 | ✅ |
| `food/premium` | #FFD43B | 12.61:1 | ✅ |

## Resultado

**Nenhum par reprovado.** Todos os pares texto/fundo e objeto/fundo dos tokens
passam WCAG 2.1 AA nos limiares aplicáveis.

## Ressalvas e desvios registrados

1. **`text/muted` (#7E88A8) é o único token com restrição de uso.** Sobre vidro em cima de
   `surface/1` fica em **3.93:1** — abaixo de 4.5:1. O design já previa a restrição
   (`"mutedRule": "so >=18px ou bold"`), mas o limiar estava **frouxo**: WCAG 2.1 define
   texto grande como ≥24px normal ou ≥18.66px em negrito. Os tokens foram gravados com
   `TAM_MIN_TEXTO_MUTED_BOLD = 19` e `TAM_MIN_TEXTO_MUTED_REGULAR = 24`.

2. **Gradientes de CTA viram cor sólida no tema.** `StyleBoxFlat` do Godot não desenha
   gradiente; `snakito_theme.tres` usa o tom médio de cada gradiente. As três variantes
   (início, médio, fim) passam AA, então a aproximação não cria risco de acessibilidade —
   só perde o acabamento. O gradiente real exige `StyleBoxTexture` ou shader.

3. **Tamanho de chip fora da escala.** As telas do design usam 14px em chips de filtro;
   a escala tipográfica não tem 14. O tema usa `body` (15px), o token mais próximo.

4. **Bordas de 1.5px arredondadas para 2px.** `StyleBoxFlat.border_width` é inteiro.
