extends Node
## Saca capturas de las pantallas principales en /tmp/capturas (requiere pantalla o xvfb).

var main: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/capturas")
	DirAccess.remove_absolute("user://partida.json")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _foto("01_titulo")
	Estado.ir("creacion")
	await _foto("02_creacion")
	Estado.nueva_partida("m", "Joser")
	for t in ["t_flexiones", "t_instrumento", "t_ordenar"]:
		Estado.registrar_tarea(t)
	Estado.agregar_seguidor("s_brisa", 4)
	Estado.agregar_seguidor("e_bajista", 3)
	Estado.d["tam_equipo"] = 3
	Estado.d["equipo"] = ["s1", "s2"]
	Estado.d["nodos"]["c1"] = {"vencido": true, "veces": 1, "unico_despertado": false, "reaparece": 0, "fallos": 0}
	Estado.d["nodos"]["c2"] = {"vencido": true, "veces": 1, "unico_despertado": false, "reaparece": 0, "fallos": 0}
	Estado.d["nivel"] = 4
	Estado.guardar()
	Estado.ir("centro")
	await _foto("03_centro")
	Estado.ir("campana")
	await _foto("04_campana")
	Estado.ir("mapa", {"zona": "cotoca"})
	await _foto("05_mapa")
	Estado.ir("tareas")
	await _foto("06_tareas")
	Estado.ir("ensayo")
	await _foto("07_ensayo")
	Estado.ir("escuadron")
	await _foto("08_escuadron")
	Estado.ir("equipo")
	await _foto("09_equipo")
	Estado.ir("archivo")
	await _foto("10_archivo")
	Estado.ir("combate", {"zona": "cotoca", "nodo": "c4"})
	await _foto("11_combate")
	var c = main.actual
	# Elegir una habilidad del jugador para ver la selección
	for i in 60:
		if c.esperando_jugador:
			break
		await get_tree().process_frame
	if c.esperando_jugador:
		c._elegir_habilidad(c.b.actual.habilidades[1])
	await _foto("12_combate_objetivo")
	c._despertar("s_lazaro", 6)
	await _foto("13_despertar")
	get_tree().quit()


func _foto(nombre: String) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/capturas/%s.png" % nombre)
