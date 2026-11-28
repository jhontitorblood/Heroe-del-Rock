extends Node
## Saca capturas de las pantallas principales en /tmp/capturas (requiere pantalla o xvfb).

var main: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/capturas")
	DirAccess.remove_absolute("user://partida.json")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _foto("00_intro")
	main.actual._salir()
	await _foto("01_inicio")
	Estado.ir("creacion")
	await _foto("02_creacion")
	var cr = main.actual
	cr._elegir("f")
	cr.nombre_edit.text = "Joser"
	await _foto("02b_creacion_elegida")
	cr._aceptar()
	for i in 25:
		await get_tree().process_frame
	await _foto("02c_creacion_rock")
	Estado.nueva_partida("m", "Joser")
	for t in ["t_flexiones", "t_instrumento", "t_ordenar"]:
		Estado.registrar_tarea(t)
	Estado.agregar_seguidor("s_ivy", 4)
	Estado.agregar_seguidor("e_sam", 3)
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
	main.actual._ver_ciclo()
	await _foto("09b_ciclo_tipos")
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
	# Efectos de golpe por clase (se capturan a mitad de la animación)
	var clases := ["guitarrista", "bajista", "baterista", "vocalista", "tecladista", "vientista"]
	var uids: Array = c.tarjetas.keys()
	for i in uids.size():
		c._efecto_golpe(uids[i], clases[i % clases.size()])
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not ("vertical" in OS.get_cmdline_user_args()):
		get_viewport().get_texture().get_image().save_png("/tmp/capturas/12b_efectos.png")
	# Imagen de ataque: se fuerza una acción y se captura a mitad de la embestida
	var atacante = c.b.lado(0)[0]
	c._anim_accion(atacante.uid, atacante.habilidades[0])
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not ("vertical" in OS.get_cmdline_user_args()):
		get_viewport().get_texture().get_image().save_png("/tmp/capturas/12c_ataque.png")
	await get_tree().create_timer(0.6).timeout
	c._despertar("s_jiujiu", 6)
	await _foto("13_despertar")
	get_tree().quit()


func _foto(nombre: String) -> void:
	# Cada ejecución captura solo una orientación (la ventana de prueba no gira sola):
	#   -- vertical   → solo pantallas verticales;  sin argumento → solo horizontales
	var quiero_vertical := "vertical" in OS.get_cmdline_user_args()
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if main.vertical_actual != quiero_vertical:
		return
	get_viewport().get_texture().get_image().save_png("/tmp/capturas/%s.png" % nombre)
