# Emenda às Instruções Globais — Trilhas de Tecnologia

> **Como aplicar:** cole a seção abaixo nas *Instruções Globais — Linha de Apps Educacionais*, logo após a seção **2. Stack padrão**, e atualize a regra inegociável nº 1 e a tabela da seção 8 conforme indicado no final.

---

## 2-A. Trilhas de tecnologia (emenda)

A linha passa a ter **duas trilhas oficiais**. A escolha da trilha é feita na fase de documentação de cada app e registrada nas decisões de design.

### Trilha A — Apps de puzzle, conteúdo e interface (padrão)
- Stack original da seção 2: **TypeScript strict + React Native + Expo (SDK LTS mais recente) + Paper + NativeWind + Zustand**.
- Indicada para: puzzles por turno, apps de leitura/matemática/conteúdo, qualquer app dominado por telas, formulários e navegação.
- Exemplo: **Blokito**.

### Trilha B — Jogos de ação e tempo real
- **Godot 4 (versão estável mais recente — atual: 4.8) + GDScript**, com tipagem estática do GDScript ativada (`static typing`) e avisos de tipo tratados como erro.
- Indicada para: jogos que exigem simulação contínua, física, dezenas de entidades simultâneas e 60fps sustentados — cenário onde React Native não oferece garantias.
- Exemplo: **Snakito**.

### Tabela de equivalências entre trilhas

| Princípio da linha | Trilha A (Expo/TS) | Trilha B (Godot) |
|---|---|---|
| Lógica de domínio pura e testável | Pacote TS puro + vitest | Classes GDScript puras (sem nós de cena) + **gdUnit4** |
| UI funcional | React Native Paper | Nós `Control` + `Theme` centralizado |
| Design tokens centralizados | Tema NativeWind | Um único `Theme` resource + constantes de cor/espaçamento |
| i18n desde o dia 1 | i18next | Sistema nativo de tradução do Godot (CSV/PO), pt-BR padrão |
| Backend | Supabase (SDK JS) | Supabase via REST (`HTTPRequest`) + Edge Functions |
| Compras | react-native-iap | Plugin oficial **godot-google-play-billing** (godot-sdk-integrations) |
| Anúncios | AdMob RN | Plugin AdMob para Godot com tags COPPA/TFUA e consentimento UMP |
| Crashes | Sentry RN | **SDK oficial Sentry para Godot** |
| Analytics | Firebase Analytics (modo restrito) | Plugin comunitário Firebase Analytics (aceito o custo de manutenção; avaliar alternativa a cada app) |
| Offline-first | AsyncStorage/MMKV | `FileAccess`/`ConfigFile` local + fila de sincronização |

### Regras que NÃO mudam entre trilhas
As regras inegociáveis 2 a 5 valem integralmente nas duas trilhas: Android/Play Store com Google Play Billing; i18n com pt-BR padrão e nada hardcoded; conformidade total com a política de Famílias; documentação antes de código. Também permanecem obrigatórios: entitlements por conta no Supabase, RLS em todas as tabelas, onboarding sem texto, feedback rico, acessibilidade WCAG AA e ícone adaptativo.

---

## Alteração na regra inegociável nº 1

Substituir o texto da regra 1 por:

> 1. **Trilha A: TypeScript sempre**, com `strict: true`; nunca JavaScript puro; nunca `any` sem justificativa explícita. **Trilha B: GDScript com tipagem estática obrigatória**; nunca variáveis sem tipo sem justificativa explícita. A escolha da trilha é decisão de documentação, nunca improviso durante o desenvolvimento.

## Alteração na tabela da seção 8

| App | Trilha | Status | Instruções específicas |
|---|---|---|---|
| Blokito (lógica e raciocínio espacial) | A — Expo/TS | M1 entregue — correção de drag em andamento | `blokito-instrucoes.md` + `blokito-documentacao.md` |
| **Snakito** (estratégia, reação, gestão de risco) | **B — Godot** | **Documentado — pré-spike** | `snakito-instrucoes.md` |
| *(próximos apps)* | — | — | — |

---

**Versão da emenda:** 1.0 · **Data:** Ago 2026 · **Motivação registrada:** experiência de performance insatisfatória com gestos/render em React Native no Blokito; jogos de tempo real exigem engine dedicada. Godot escolhido sobre Cocos Creator após liberação da restrição de linguagem (comunidade maior, plugin de Billing mantido pela fundação, sem royalties).
