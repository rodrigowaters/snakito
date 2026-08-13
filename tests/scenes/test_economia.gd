class_name TestEconomia
extends GdUnitTestSuite
## Economia local (docs §5 + tokens do design): fração da partida,
## prêmio de desafio e a máquina de estados da recompensa diária.


func before_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func after_test() -> void:
	DirAccess.remove_absolute(ProgressoLocal.CAMINHO)
	ProgressoLocal._resetar_cache_para_testes()


func test_moedas_da_partida_e_o_exemplo_do_design() -> void:
	# Tokens do design: "2480 pts -> 124 moedas" (~5%).
	assert_int(Economia.moedas_da_partida(2480)).is_equal(124)
	assert_int(Economia.moedas_da_partida(0)).is_equal(0)


func test_diaria_primeira_coleta() -> void:
	assert_int(Economia.dia_para_coletar("2026-08-13")).is_equal(1)
	assert_int(Economia.coletar_diaria("2026-08-13")).is_equal(50)
	assert_int(ProgressoLocal.moedas()).is_equal(50)
	# Mesmo dia: já coletada — nada a coletar, nada creditado.
	assert_int(Economia.dia_para_coletar("2026-08-13")).is_equal(0)
	assert_int(Economia.coletar_diaria("2026-08-13")).is_equal(0)
	assert_int(ProgressoLocal.moedas()).is_equal(50)


func test_diaria_sequencia_avanca_no_dia_seguinte() -> void:
	Economia.coletar_diaria("2026-08-13")
	assert_int(Economia.dia_para_coletar("2026-08-14")).is_equal(2)
	assert_int(Economia.coletar_diaria("2026-08-14")).is_equal(75)


func test_diaria_perder_um_dia_reinicia() -> void:
	Economia.coletar_diaria("2026-08-13")
	Economia.coletar_diaria("2026-08-14")
	# Pulou o dia 15: a sequência quebra e volta ao dia 1.
	assert_int(Economia.dia_para_coletar("2026-08-16")).is_equal(1)
	assert_int(Economia.coletar_diaria("2026-08-16")).is_equal(50)


func test_diaria_dia_7_em_dobro_e_recomeco() -> void:
	var datas: Array[String] = ["2026-08-01", "2026-08-02", "2026-08-03",
		"2026-08-04", "2026-08-05", "2026-08-06", "2026-08-07"]
	var total: int = 0
	for data: String in datas:
		total += Economia.coletar_diaria(data)
	assert_int(total).is_equal(50 + 75 + 100 + 150 + 200 + 300 + 600)
	# Dia seguinte ao 7: a sequência recomeça no dia 1.
	assert_int(Economia.dia_para_coletar("2026-08-08")).is_equal(1)


func test_diaria_atravessa_virada_de_mes() -> void:
	Economia.coletar_diaria("2026-08-31")
	assert_int(Economia.dia_para_coletar("2026-09-01")).is_equal(2)
