class_name TestRngService
extends GdUnitTestSuite
## Determinismo do RNG central — a base de "mesma seed = mesma partida".


func test_mesma_seed_produz_a_mesma_sequencia() -> void:
	var a: RngService = RngService.new(42)
	var b: RngService = RngService.new(42)
	for i: int in 50:
		assert_float(a.float_unitario()).is_equal(b.float_unitario())


func test_seeds_diferentes_divergem() -> void:
	var a: RngService = RngService.new(1)
	var b: RngService = RngService.new(2)
	var iguais: int = 0
	for i: int in 10:
		if a.float_unitario() == b.float_unitario():
			iguais += 1
	assert_int(iguais).is_less(10)


func test_int_entre_respeita_os_limites() -> void:
	var rng: RngService = RngService.new(7)
	for i: int in 200:
		var valor: int = rng.int_entre(3, 7)
		assert_int(valor).is_between(3, 7)


func test_float_entre_respeita_os_limites() -> void:
	var rng: RngService = RngService.new(7)
	for i: int in 200:
		var valor: float = rng.float_entre(-2.5, 2.5)
		assert_float(valor).is_between(-2.5, 2.5)


func test_direcao_unitaria_tem_comprimento_1() -> void:
	var rng: RngService = RngService.new(11)
	for i: int in 20:
		assert_float(rng.direcao_unitaria().length()).is_equal_approx(1.0, 0.0001)


func test_ponto_no_retangulo_fica_dentro() -> void:
	var rng: RngService = RngService.new(13)
	var retangulo: Rect2 = Rect2(100.0, 200.0, 50.0, 30.0)
	for i: int in 100:
		assert_bool(retangulo.has_point(rng.ponto_no_retangulo(retangulo))).is_true()


func test_semente_fica_exposta_para_a_tela_de_resultado() -> void:
	assert_int(RngService.new(987654).semente).is_equal(987654)
