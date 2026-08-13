class_name ChallengeRules
extends RefCounted
## Regras e metas dos 4 desafios progressivos (docs §2.5). Puro: avalia o
## estado do GameEngine e NUNCA o altera; a cena decide o que fazer quando
## o desafio se resolve.
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
	DEFESA,                # Desafio 3: sobreviva 3 min com 2 caçadores 100+
	INTEGRACAO_TOTAL,      # Desafio 4: termine no Top 3 com 20 bots
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

# --- Desafio 3 · defesa ---------------------------------------------------------
const SEED_DESAFIO_3: int = 303
const DURACAO_DESAFIO_3_SEG: int = 180

# --- Desafio 4 · integração total -----------------------------------------------
const SEED_DESAFIO_4: int = 404
const DURACAO_DESAFIO_4_SEG: int = 180
const META_POSICAO_DESAFIO_4: int = 3

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
			# Lição: caçar com critério — SENDO caçado. Calibrado em 5
			# iterações de playtest com validação estatística no simulador
			# (histórico completo no git). Os princípios que sobraram:
			# · presas alcançáveis (turbo_bots < jogador) e contidas (teto 8)
			# · 2 caçadores-ALFA nascem 10 e crescem até 30 — a ameaça escala
			#   com o jogador em vez de evaporar no tamanho 11
			# · arena aberta (~2 bots no enquadramento da câmera): respiro
			#   entre encontros, não "campo de batalha"
			# · comida contida: crescimento visível a partida inteira
			# RECALIBRADO com corte+velocidade por tamanho (§2.2/§2.7,
			# ago/2026): "maior = mais rápido" quebrou a premissa da paridade
			# e o D2 trivializou (24/24, 0 mortes). Alfas mais fortes
			# devolvem a ameaça: nascem 14, teto 40, turbo 1.4.
			config.semente = SEED_DESAFIO_2
			config.duracao_seg = DURACAO_DESAFIO_2_SEG
			config.tamanho_arena = Vector2(2000.0, 2000.0)
			config.qtd_comida = 50
			config.fazendeiros = 11
			config.cacadores = 2
			config.oportunistas = 2
			config.tamanho_min_bot = 1
			config.tamanho_max_bot = 5
			config.agressividade = 0.5
			config.turbo_bots = 1.4
			config.tamanho_teto_bot = 8
			config.tamanho_teto_cacador = 40
			config.tamanho_inicial_cacador = 14
			# Alfas nascem LONGE (playtest 11/08): morrer em 3s no início
			# frustra a criança — o desafio é para ser vencido pela leitura,
			# não sofrido na loteria do spawn.
			config.distancia_spawn_cacador = 1000.0
		Desafio.DEFESA:
			# Lição: fugir É estratégia. 2 caçadores GIGANTES (spec: 100+) que
			# o jogador jamais enfrenta — visão deles fica no teto (700), então
			# eles SEMPRE te acham; sobreviver exige turbo, rota e paciência.
			# A persistência de caça (5s/8s) é a janela de respiro que torna a
			# lição jogável; nascem longe (loteria de spawn frustra criança).
			config.semente = SEED_DESAFIO_3
			config.duracao_seg = DURACAO_DESAFIO_3_SEG
			config.tamanho_arena = Vector2(3000.0, 3000.0)
			config.qtd_comida = 130
			config.fazendeiros = 10
			config.cacadores = 2
			config.oportunistas = 6
			config.tamanho_min_bot = 1
			config.tamanho_max_bot = 5
			config.agressividade = 0.6
			# Gigante nível 100+ já anda no teto de velocidade (×1.35 = 243);
			# turbo 1.1 garante que o TURBO do jogador sempre escapa (270 vs
			# 267) — a lição é gestão de energia, não corrida perdida.
			config.turbo_bots = 1.1
			config.tamanho_teto_bot = 20
			config.tamanho_inicial_cacador = 100
			config.tamanho_teto_cacador = 130
			config.distancia_spawn_cacador = 2000.0
		Desafio.INTEGRACAO_TOTAL:
			# Lição: juntar tudo — farmar, caçar, fugir e ADMINISTRAR pontos.
			# Composição de Arcade honesta com exatamente 20 bots (spec).
			config.semente = SEED_DESAFIO_4
			config.duracao_seg = DURACAO_DESAFIO_4_SEG
			config.qtd_comida = 90
			config.fazendeiros = 8
			config.cacadores = 4
			config.oportunistas = 8
			config.tamanho_min_bot = 1
			config.tamanho_max_bot = 5
			config.agressividade = 0.5
			config.turbo_bots = 1.4
			config.tamanho_teto_bot = 20
			config.tamanho_teto_cacador = 35
			config.tamanho_inicial_cacador = 8
			config.distancia_spawn_cacador = 1000.0
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
		Desafio.DEFESA:
			# Sobreviver até o fim (relógio OU arena dominada — exterminar os
			# gigantes também é sobreviver, e que sobrevivência).
			if not jogador.viva:
				_falhar(Motivo.MORREU)
			elif motor.estado == GameEngine.Estado.ENCERRADA:
				_concluir()
		Desafio.INTEGRACAO_TOTAL:
			# "TERMINE no Top 3": morrer antes do fim falha — sem isso, morrer
			# cedo com a arena ainda empatada em pontos viraria vitória de
			# sorte. O rank vale no encerramento por tempo (ou domínio).
			if not jogador.viva:
				_falhar(Motivo.MORREU)
			elif motor.estado == GameEngine.Estado.ENCERRADA:
				if motor.posicao_no_ranking(jogador) <= META_POSICAO_DESAFIO_4:
					_concluir()
				else:
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
		Desafio.DEFESA:
			return mini(int(motor.segundos_decorridos()), DURACAO_DESAFIO_3_SEG)
		Desafio.INTEGRACAO_TOTAL:
			return motor.posicao_no_ranking(jogador)
	return 0


## Valor da meta (denominador da barra de progresso).
func progresso_meta() -> int:
	match desafio:
		Desafio.FARMING_PURO:
			return META_PONTOS_DESAFIO_1
		Desafio.AGRESSAO_CONTROLADA:
			return META_ABATES_DESAFIO_2
		Desafio.DEFESA:
			return DURACAO_DESAFIO_3_SEG
		Desafio.INTEGRACAO_TOTAL:
			return META_POSICAO_DESAFIO_4
	return 0


## O HUD deve mostrar a linha "META X/Y"? O D3 não: a meta é o próprio
## cronômetro (segundos contando "para cima" ao lado do relógio contando
## para baixo abriam a partida num confuso "META 0/180").
func mostra_meta_no_hud() -> bool:
	return desafio != Desafio.DEFESA


func _concluir() -> void:
	estado = Estado.CONCLUIDO
	motivo = Motivo.META_ATINGIDA


func _falhar(motivo_: Motivo) -> void:
	estado = Estado.FALHOU
	motivo = motivo_
