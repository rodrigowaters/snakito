# Snakito 🐍

Jogo educacional Android — snake-arena single-player contra bots, 100% jogável offline, com ranking global assíncrono. Parte da linha de apps educacionais (Trilha B: **Godot 4 + GDScript tipado**).

- **Documentação:** [`docs/snakito-instrucoes.md`](docs/snakito-instrucoes.md) — fonte de verdade. Nada se desenvolve sem estar documentado.
- **Contexto para agentes:** [`CLAUDE.md`](CLAUDE.md) — carregado automaticamente pelo Claude Code.
- **Trilhas da linha:** [`docs/emenda-instrucoes-globais.md`](docs/emenda-instrucoes-globais.md).

## Estado

Documentação aprovada → próximo passo: **spike de go/no-go** (export `.aab` com plugins Billing + AdMob, mini-arena com 30 bots a 60fps em aparelho mediano).

## Estrutura prevista

```
CLAUDE.md
project.godot    # projeto Godot 4.8 (mínimo; presets Android virão no spike)
assets/          # fontes (OFL), símbolos de daltonismo, futuros sprites/sons
docs/            # instruções, documentação, referência de design (.dc.html)
src/domain/      # lógica pura (RefCounted, sem cena) — testada com gdUnit4
src/scenes/      # arena e jogo
src/ui/          # telas Control (Home, Loja, Ranking, Configurações...)
tests/           # gdUnit4
tools/           # scripts de editor (ex.: gerar_tema.gd)
export/          # presets .aab
```
