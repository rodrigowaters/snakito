class_name TestFilaSessoes
extends GdUnitTestSuite
## Fila offline de sessões: persistência criptografada, ordem, remoção e teto.


func before_test() -> void:
	DirAccess.remove_absolute(FilaSessoes.CAMINHO)


func after_test() -> void:
	DirAccess.remove_absolute(FilaSessoes.CAMINHO)


func _payload(score: int) -> Dictionary:
	return {"seed": 42, "score": score, "client_version": "teste"}


func test_enfileira_e_le_em_ordem() -> void:
	FilaSessoes.enfileirar(_payload(100))
	FilaSessoes.enfileirar(_payload(200))
	assert_int(FilaSessoes.tamanho()).is_equal(2)
	var pendentes: Array[Dictionary] = FilaSessoes.pendentes()
	assert_int(pendentes[0].payload["score"]).is_equal(100)
	assert_int(pendentes[1].payload["score"]).is_equal(200)


func test_persiste_entre_leituras() -> void:
	# FilaSessoes é estática e reabre o arquivo a cada operação — o teste
	# garante que o payload sobrevive ao "novo boot" (nova leitura do disco).
	FilaSessoes.enfileirar(_payload(777))
	var relido: Array[Dictionary] = FilaSessoes.pendentes()
	assert_int(relido[0].payload["score"]).is_equal(777)
	assert_bool(FileAccess.file_exists(FilaSessoes.CAMINHO)).is_true()


func test_arquivo_e_criptografado() -> void:
	FilaSessoes.enfileirar(_payload(123))
	var bruto: PackedByteArray = FileAccess.get_file_as_bytes(FilaSessoes.CAMINHO)
	# Nada legível no arquivo: nem chave de seção nem valor.
	assert_bool(bruto.get_string_from_utf8().contains("score")).is_false()


func test_remover_tira_da_fila() -> void:
	FilaSessoes.enfileirar(_payload(1))
	FilaSessoes.enfileirar(_payload(2))
	var pendentes: Array[Dictionary] = FilaSessoes.pendentes()
	FilaSessoes.remover(pendentes[0].id)
	assert_int(FilaSessoes.tamanho()).is_equal(1)
	assert_int(FilaSessoes.pendentes()[0].payload["score"]).is_equal(2)


func test_teto_descarta_a_mais_antiga() -> void:
	for i: int in FilaSessoes.MAX_PENDENTES:
		FilaSessoes.enfileirar(_payload(i))
	assert_int(FilaSessoes.tamanho()).is_equal(FilaSessoes.MAX_PENDENTES)
	FilaSessoes.enfileirar(_payload(9999))
	assert_int(FilaSessoes.tamanho()).is_equal(FilaSessoes.MAX_PENDENTES)
	var scores: Array[int] = []
	for pendente: Dictionary in FilaSessoes.pendentes():
		scores.append(pendente.payload["score"])
	assert_array(scores).contains([9999])
	assert_array(scores).not_contains([0])  # a mais antiga caiu
