class_name Economia
extends RefCounted
## Regras da economia local (docs §5 + bloco `economy` dos tokens do
## design). Moedas vivem 100% no aparelho — o servidor não participa
## (offline-first; ranking nunca considera economia).
##
## Fontes: ~5% dos pontos viram moedas (exemplo do design: 2.480 pts →
## 124), prêmio fixo na PRIMEIRA conclusão de cada desafio (análogo do
## `phaseWin` — Snakito não tem fases) e recompensa diária em sequência
## de 7 dias (perder um dia reinicia; dia 7 vale em dobro).

## Fração dos pontos da partida que vira moedas (toda partida, Arcade e
## desafio — a comparabilidade educacional é do RANKING, não da economia).
const FRACAO_PONTOS: float = 0.05
## Prêmio da primeira conclusão de um desafio (pill "+350" da tela 07/12c).
const PREMIO_DESAFIO: int = 350
## Recompensa diária por dia da sequência (dia 7 = em dobro do dia 6).
const RECOMPENSAS_DIARIAS: Array[int] = [50, 75, 100, 150, 200, 300, 600]


static func moedas_da_partida(pontos: int) -> int:
	return roundi(pontos * FRACAO_PONTOS)


## Dia da sequência a coletar HOJE (1..7); 0 = hoje já foi coletado.
## `hoje` injetável para testes (padrão: data local do aparelho, spec 01b).
static func dia_para_coletar(hoje: String = "") -> int:
	var data: String = hoje if hoje != "" else Time.get_date_string_from_system()
	var ultima: String = ProgressoLocal.diaria_ultima_coleta()
	if ultima == data:
		return 0
	if ultima != "" and _dias_entre(ultima, data) == 1:
		# Sequência viva: avança (depois do dia 7 recomeça no 1).
		return ProgressoLocal.diaria_sequencia() % RECOMPENSAS_DIARIAS.size() + 1
	return 1  # primeira vez ou sequência quebrada


## Credita a recompensa do dia e avança a sequência. Devolve o valor
## coletado (0 = hoje já tinha sido coletado).
static func coletar_diaria(hoje: String = "") -> int:
	var data: String = hoje if hoje != "" else Time.get_date_string_from_system()
	var dia: int = dia_para_coletar(data)
	if dia == 0:
		return 0
	var valor: int = RECOMPENSAS_DIARIAS[dia - 1]
	ProgressoLocal.adicionar_moedas(valor)
	ProgressoLocal.definir_diaria(data, dia)
	return valor


## Dias corridos entre duas datas "YYYY-MM-DD" (ambas lidas no mesmo
## referencial — a diferença é o que importa).
static func _dias_entre(de: String, ate: String) -> int:
	var t0: int = Time.get_unix_time_from_datetime_string(de + "T00:00:00")
	var t1: int = Time.get_unix_time_from_datetime_string(ate + "T00:00:00")
	return int((t1 - t0) / 86400.0)
