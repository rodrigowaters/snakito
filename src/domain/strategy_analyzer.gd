class_name StrategyAnalyzer
extends RefCounted
## Análise pós-partida v1 (docs §1 e §4.3): explica POR QUE a partida terminou
## como terminou e devolve sugestões concretas, tipadas — a UI traduz cada
## achado para texto (i18n no M2). Puro: só lê o estado do motor/regras.
##
## v1 = heurísticas sobre as estatísticas que o domínio já registra. O
## analyzer completo (padrões de movimento, mapa de calor) é M2.

## Sugestões possíveis. A ORDEM aqui é a prioridade de exibição.
enum Achado {
	DESAFIO_PROIBIA_MATAR,   # violou a restrição do farming puro
	GERENCIE_ENERGIA,        # morreu de tanque vazio — não tinha turbo p/ fugir
	FUJA_DOS_MAIORES,        # morreu muito cedo na partida
	CRESCA_ANTES_DE_CACAR,   # morreu caçando pequeno demais
	COLETE_MAIS_RAPIDO,      # D1: tempo esgotou sem ritmo de coleta
	CACE_PRESAS_CANSADAS,    # D2: tempo esgotou sem abates suficientes
	BOM_DESEMPENHO,          # meta atingida / top da arena
}

## Morrer com energia abaixo disto conta como "tanque vazio".
const ENERGIA_VAZIA: float = 15.0
## Morrer antes disto (em segundos) conta como "morte precoce".
const MORTE_PRECOCE_SEG: int = 30
## Caçar abaixo deste tamanho é imprudente (presas mínimas exigem ~2+).
const TAMANHO_MINIMO_CACA: int = 6
## Posição no ranking do Arcade que conta como bom desempenho.
const TOP_ARENA: int = 3
## Máximo de achados devolvidos (a tela de resultado não é um relatório).
const MAX_ACHADOS: int = 2


## Analisa a partida encerrada. `regras` = null para Arcade.
static func analisar(motor: GameEngine, regras: ChallengeRules = null) -> Array[Achado]:
	var achados: Array[Achado] = []
	var jogador: SnakeModel = motor.jogador()

	if regras != null:
		match regras.motivo:
			ChallengeRules.Motivo.META_ATINGIDA:
				achados.append(Achado.BOM_DESEMPENHO)
			ChallengeRules.Motivo.MATOU_ALGUEM:
				achados.append(Achado.DESAFIO_PROIBIA_MATAR)
			ChallengeRules.Motivo.TEMPO_ESGOTADO:
				match regras.desafio:
					ChallengeRules.Desafio.FARMING_PURO:
						achados.append(Achado.COLETE_MAIS_RAPIDO)
					ChallengeRules.Desafio.AGRESSAO_CONTROLADA:
						achados.append(Achado.CACE_PRESAS_CANSADAS)
			ChallengeRules.Motivo.MORREU:
				_analisar_morte(motor, jogador, regras, achados)
	elif not jogador.viva:
		_analisar_morte(motor, jogador, null, achados)
	elif motor.posicao_no_ranking(jogador) <= TOP_ARENA:
		achados.append(Achado.BOM_DESEMPENHO)

	if achados.size() > MAX_ACHADOS:
		achados.resize(MAX_ACHADOS)
	return achados


## Por que a morte aconteceu? Energia congela no tick da morte (cobra morta
## não regenera), então `jogador.energia` é a energia do momento fatal.
static func _analisar_morte(
	motor: GameEngine,
	jogador: SnakeModel,
	regras: ChallengeRules,
	achados: Array[Achado],
) -> void:
	if jogador.energia <= ENERGIA_VAZIA:
		achados.append(Achado.GERENCIE_ENERGIA)
	if jogador.ticks_vividos < MORTE_PRECOCE_SEG * GameEngine.TICKS_POR_SEGUNDO:
		achados.append(Achado.FUJA_DOS_MAIORES)
	if regras != null \
			and regras.desafio == ChallengeRules.Desafio.AGRESSAO_CONTROLADA \
			and jogador.tamanho < TAMANHO_MINIMO_CACA:
		achados.append(Achado.CRESCA_ANTES_DE_CACAR)
