class_name ChallengeRules
extends RefCounted
## Regras e metas dos desafios progressivos (docs §2.5) — Desafios 1 e 2;
## 3 e 4 chegam no M2. Puro: avalia o estado do GameEngine e NUNCA o altera;
## a cena decide o que fazer quando o desafio se resolve.
##
## Contratos (docs §2.4 e §2.6.3):
## - Seed FIXA por desafio → o mesmo desafio gera exatamente a mesma partida
##   ("aprender por comparação de decisões").
## - Buffs SEMPRE desligados (`aplicar_buffs = false`) — comparabilidade.
## - Nenhuma string aqui: a UI traduz `Desafio`/`Motivo` via i18n (M2).

## Desafios disponíveis (numeração do docs §2.5).
enum Desafio {
	FARMING_PURO,          # Desafio 1: 50 pontos em 1 min sem matar ninguém
	AGRESSAO_CONTROLADA,   # Desafio 2: devore 3 bots antes de 2 min
}

enum Estado { EM_ANDAMENTO, CONCLUIDO, FALHOU }

## Por que o desafio se resolveu — insumo da análise pós-partida ("por quê
## você perdeu", docs §1) e da tela de resultado.
enum Motivo { NENHUM, META_ATINGIDA, MATOU_ALGUEM, MORREU, TEMPO_ESGOTADO }

# --- Desafio 1 · farming puro -------------------------------------------------
const SEED_DESAFIO_1: int = 101
const DURACAO_DESAFIO_1_SEG: int = 60
const META_PONTOS_DESAFIO_1: int = 50

# --- Desafio 2 · agressão controlada ------------------------------------------
const SEED_DESAFIO_2: int = 202
const DURACAO_DESAFIO_2_SEG: int = 120
const META_ABATES_DESAFIO_2: int = 3

var desafio: Desafio
var estado: Estado = Estado.EM_ANDAMENTO
var motivo: Motivo = Motivo.NENHUM


func _init(desafio_: Desafio) -> void:
	desafio = desafio_


## Config da partida do desafio: seed fixa, sem buffs, composição pedagógica.
## A spec fixa meta e tempo; a composição é decisão nossa, documentada aqui.
static func config_do_desafio(desafio_: Desafio) -> GameEngine.ConfigPartida:
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.new()
	config.aplicar_buffs = false
	match desafio_:
		Desafio.FARMING_PURO:
			# Lição: colher sem conflito. ZERO caçadores; poucos oportunistas
			# mansos mantêm alguma tensão; comida abundante.
			config.semente = SEED_DESAFIO_1
			config.duracao_seg = DURACAO_DESAFIO_1_SEG
			config.qtd_comida = 100
			config.fazendeiros = 16
			config.cacadores = 0
			config.oportunistas = 4
			config.tamanho_min_bot = 1
			config.tamanho_max_bot = 4
			config.agressividade = 0.3
		Desafio.AGRESSAO_CONTROLADA:
			# Lição: caçar com critério. Arena COMPACTA (mais encontros,
			# menos deserto), muitas presas pequenas, 1 caçador para lembrar
			# o risco sem virar bola de neve, e presas com sprint mais fraco
			# — alcançáveis com esforço (calibrado no playtest de 08/08:
			# paridade de turbo tornava abater impossível).
			config.semente = SEED_DESAFIO_2
			config.duracao_seg = DURACAO_DESAFIO_2_SEG
			config.tamanho_arena = Vector2(1600.0, 1600.0)
			config.qtd_comida = 70
			config.fazendeiros = 20
			config.cacadores = 1
			config.oportunistas = 3
			config.tamanho_min_bot = 1
			config.tamanho_max_bot = 3
			config.agressividade = 0.35
			config.turbo_bots = 1.3
			config.tamanho_teto_bot = 12  # sem gigantes: o desafio é caçar, não fugir
	return config


## Avalia o desafio contra o estado atual do motor. Chamar 1x por tick,
## depois de `motor.avancar()`. TRAVA ao resolver: uma vez CONCLUIDO ou
## FALHOU, o resultado não muda mais (a cena encerra a partida a partir daí).
func avaliar(motor: GameEngine) -> Estado:
	if estado != Estado.EM_ANDAMENTO:
		return estado
	var jogador: SnakeModel = motor.jogador()
	match desafio:
		Desafio.FARMING_PURO:
			# Prioridade: violar a restrição ("sem matar ninguém") derrota o
			# desafio mesmo que os pontos do abate cruzem a meta no mesmo tick.
			if jogador.abates > 0:
				_falhar(Motivo.MATOU_ALGUEM)
			elif not jogador.viva:
				_falhar(Motivo.MORREU)
			elif jogador.pontos >= META_PONTOS_DESAFIO_1:
				_concluir()
			elif motor.estado == GameEngine.Estado.ENCERRADA:
				_falhar(Motivo.TEMPO_ESGOTADO)
		Desafio.AGRESSAO_CONTROLADA:
			# Prioridade: meta antes da morte — se o 3º abate e a morte caem
			# no mesmo tick, o abate aconteceu e a meta vale.
			if jogador.abates >= META_ABATES_DESAFIO_2:
				_concluir()
			elif not jogador.viva:
				_falhar(Motivo.MORREU)
			elif motor.estado == GameEngine.Estado.ENCERRADA:
				_falhar(Motivo.TEMPO_ESGOTADO)
	return estado


## Progresso atual rumo à meta, limitado a ela (para a barra do HUD).
func progresso_atual(motor: GameEngine) -> int:
	var jogador: SnakeModel = motor.jogador()
	match desafio:
		Desafio.FARMING_PURO:
			return mini(jogador.pontos, META_PONTOS_DESAFIO_1)
		Desafio.AGRESSAO_CONTROLADA:
			return mini(jogador.abates, META_ABATES_DESAFIO_2)
	return 0


## Valor da meta (denominador da barra de progresso).
func progresso_meta() -> int:
	match desafio:
		Desafio.FARMING_PURO:
			return META_PONTOS_DESAFIO_1
		Desafio.AGRESSAO_CONTROLADA:
			return META_ABATES_DESAFIO_2
	return 0


func _concluir() -> void:
	estado = Estado.CONCLUIDO
	motivo = Motivo.META_ATINGIDA


func _falhar(motivo_: Motivo) -> void:
	estado = Estado.FALHOU
	motivo = motivo_
