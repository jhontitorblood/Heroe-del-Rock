extends Node
## Prueba de humo: recorre todas las pantallas y juega combates en automático.
## Uso: godot --headless --path . res://tests/prueba_pantallas.tscn

var main: Control


func _ready() -> void:
	DirAccess.remove_absolute("user://partida.json")
	Engine.time_scale = 20.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _esperar(5)
	_ok("titulo", main.nombre_actual == "titulo")
	Estado.ir("creacion")
	await _esperar(5)
	Estado.nueva_partida("f", "Prueba")
	for p in ["centro", "campana", "escuadron", "equipo", "archivo", "tareas", "ensayo"]:
		Estado.ir(p)
		await _esperar(4)
		_ok(p, main.nombre_actual == p)
	Estado.ir("mapa", {"zona": "cotoca"})
	await _esperar(4)
	# Tareas reales: cadena completa
	for t in ["t_flexiones", "t_caminar", "t_instrumento", "t_ordenar", "t_trabajo"]:
		print("  tarea: ", Estado.registrar_tarea(t))
	_ok("pua por cadena completa", int(Estado.d["pua"]) == 1)
	print("  ensayo real: ", Estado.ensayo("real"))
	_ok("en sintonía", bool(Estado.d["en_sintonia"]))
	# Combates en automático por toda Cotoca
	Estado.d["energia"] = 200
	Estado.d["nivel"] = 1
	for nodo in ["c1", "c2", "c3", "c4", "c5", "c6", "c7"]:
		await _combate_auto(nodo)
		print("  ", nodo, " vencido=", Estado.nodo_vencido(nodo), " nivel=", Estado.d["nivel"], " seguidores=", Estado.d["seguidores"].size(), " equipo=", Estado.d["equipo"], " tam=", Estado.d["tam_equipo"])
		Estado.d["desafinado_hasta"] = 0
		Estado.curar_equipo(1.0)
		Estado.d["nodos"][nodo]["reaparece"] = 0
	# Requisito del jefe: 5 ejercicios acumulados
	var n8 := Datos.nodo("cotoca", "c8")
	print("  bloqueo jefe: ", Estado.bloqueo_nodo(n8))
	for i in 5:
		Estado.registrar_ejercicio_extra()
	Estado.d["nivel"] = max(6, int(Estado.d["nivel"]))
	_ok("jefe desbloqueado", Estado.bloqueo_nodo(n8) == "")
	await _combate_auto("c8")
	print("  jefe vencido=", Estado.nodo_vencido("c8"))
	# Derrota y desafinados
	Estado.aplicar_derrota()
	_ok("desafinado", Estado.esta_desafinado())
	var antes := Estado.segundos_desafinado()
	Estado.registrar_ejercicio_extra()
	_ok("ejercicio resta 1 min", antes - Estado.segundos_desafinado() >= 59)
	Estado.ir("centro")
	await _esperar(4)
	Estado.ir("archivo")
	await _esperar(4)
	print("FIN DE LA PRUEBA")
	get_tree().quit()


func _combate_auto(nodo: String) -> void:
	Estado.ir("combate", {"zona": "cotoca", "nodo": nodo})
	await _esperar(3)
	var c = main.actual
	c._alternar_auto()
	var t := 0
	while not c.terminado and t < 60000:
		await _esperar(1)
		t += 1
	var res: String = c.b.resultado()
	var ronda: int = c.b.ronda
	await _esperar(3)
	# Cerrar avisos/diálogos y despertar
	for i in 12:
		if main.nombre_actual != "combate":
			break
		_pulsar_todo(main.actual)
		await _esperar(3)
	print("  resultado ", nodo, ": ", res, " en ronda ", ronda)


func _pulsar_todo(n: Node) -> void:
	# Pulsa "Aceptar", "Continuar >", "¡DESPERTAR!" y luego "Continuar"
	var botones := n.find_children("*", "Button", true, false)
	for b in botones:
		if b.is_visible_in_tree() and not b.disabled and b.text in ["Aceptar", "Continuar >", "¡DESPERTAR!", "Continuar"]:
			b.pressed.emit()
			return


func _esperar(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _ok(nombre: String, cond: bool) -> void:
	print(("OK    " if cond else "FALLO ") + nombre)
