class_name Sessao
extends RefCounted
## Estado de navegação entre cenas (Home → Jogo → Resultado), em vars
## estáticas — sem autoload, sem Node. NÃO é domínio: só transporta a config
## da próxima partida e o motor da última para a tela de resultado.

## Seed pedida para a próxima partida; -1 = sortear (modo Arcade).
static var proxima_semente: int = -1
## Motor da última partida encerrada — lido pela tela de resultado.
static var ultimo_motor: GameEngine = null


## Config da próxima partida. Consome `proxima_semente` (volta a -1).
static func config_para_jogar() -> GameEngine.ConfigPartida:
	var semente: int = proxima_semente if proxima_semente >= 0 else RngService.semente_aleatoria()
	proxima_semente = -1
	return GameEngine.ConfigPartida.padrao(semente)
