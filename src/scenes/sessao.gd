class_name Sessao
extends RefCounted
## Estado de navegação entre cenas (Home → Jogo → Resultado), em vars
## estáticas — sem autoload, sem Node. NÃO é domínio: só transporta a config
## da próxima partida e o motor da última para a tela de resultado.

## Seed pedida para a próxima partida; -1 = sortear (modo Arcade).
static var proxima_semente: int = -1
## Desafio pedido para a próxima partida (valor de `ChallengeRules.Desafio`);
## -1 = Arcade.
static var desafio_pendente: int = -1
## Regras do desafio da partida corrente (null = Arcade). Preenchido ao criar
## a config; lido pelo jogo (avaliação por tick), HUD (progresso) e resultado.
static var regras_desafio: ChallengeRules = null
## Motor da última partida encerrada — lido pela tela de resultado.
static var ultimo_motor: GameEngine = null


## Config da próxima partida. Consome `desafio_pendente`/`proxima_semente`.
static func config_para_jogar() -> GameEngine.ConfigPartida:
	if desafio_pendente >= 0:
		var desafio: ChallengeRules.Desafio = desafio_pendente as ChallengeRules.Desafio
		desafio_pendente = -1
		proxima_semente = -1  # desafio tem seed própria e fixa
		regras_desafio = ChallengeRules.new(desafio)
		return ChallengeRules.config_do_desafio(desafio)
	regras_desafio = null
	var semente: int = proxima_semente if proxima_semente >= 0 else RngService.semente_aleatoria()
	proxima_semente = -1
	var config: GameEngine.ConfigPartida = GameEngine.ConfigPartida.padrao(semente)
	# Dificuldade persistida (Configurações no M3): "tranquila"
	# alivia a pressão predatória sem mexer no ritmo de alimentação.
	if regras_desafio == null and ProgressoLocal.dificuldade() == ProgressoLocal.Dificuldade.TRANQUILA:
		config.cacadores = 3
		config.oportunistas = 8
		config.agressividade = 0.35
		config.turbo_bots = 1.3
	# Buffs permanentes comprados na Loja (docs §2.6.2) — SÓ no Arcade:
	# desafio já sai de config_do_desafio com aplicar_buffs = false.
	config.nivel_velocidade = ProgressoLocal.nivel_buff("velocidade")
	config.nivel_ima = ProgressoLocal.nivel_buff("ima")
	config.nivel_pontos_iniciais = ProgressoLocal.nivel_buff("pontos")
	return config
