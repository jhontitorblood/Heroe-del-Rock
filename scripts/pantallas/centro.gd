extends "res://scripts/pantallas/pantalla.gd"
## Centro de Mando: estado del jugador y acceso a todas las secciones.

var lbl_desafinado: Label
var lbl_estado: Label


func _ready() -> void:
	Estado.revisar_dia()
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando"), 0.55)
	var m := UI.margen(self, 24)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	# Cabecera con el estado del jugador
	var cab := UI.panel()
	v.add_child(cab)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	cab.add_child(h)
	var base_id: String = Estado.d["protagonista"]["base_id"]
	h.add_child(UI.imagen(Datos.sprite(base_id, false), Vector2(110, 110)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UI.etiqueta("%s · Nivel %d" % [Estado.nombre_jugador(), int(Estado.d["nivel"])], 30, UI.ORO))
	info.add_child(UI.barra(int(Estado.d["xp"]), Estado.xp_necesaria(int(Estado.d["nivel"])), Color("#ffd23a"), 14))
	lbl_estado = UI.etiqueta("", 20, UI.TEXTO)
	info.add_child(lbl_estado)
	lbl_desafinado = UI.etiqueta("", 22, Color("#ff7a7a"))
	info.add_child(lbl_desafinado)
	_actualizar_estado()

	v.add_child(UI.etiqueta("CENTRO DE MANDO", 34, UI.ACENTO))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(g)
	var botones := [
		["Campaña", "Historia y territorios", func(): Estado.ir("campana")],
		["Mapa", "Zona actual y enemigos", func(): Estado.ir("mapa", {"zona": "cotoca"})],
		["Escuadrón", "Elige quién combate", func(): Estado.ir("escuadron")],
		["Equipo", "Estadísticas y habilidades", func(): Estado.ir("equipo")],
		["Archivo", "Tu legión espectral", func(): Estado.ir("archivo")],
		["Tareas reales", "Gana experiencia y energía", func(): Estado.ir("tareas")],
		["Sala de Ensayo", "Recupera a tu equipo", func(): Estado.ir("ensayo")],
		["Menú principal", "Salir al título", func(): Estado.ir("titulo")],
	]
	for b in botones:
		var bt := Button.new()
		bt.text = "%s\n%s" % [b[0], b[1]]
		bt.custom_minimum_size = Vector2(290, 120)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bt.pressed.connect(b[2])
		g.add_child(bt)


func _actualizar_estado() -> void:
	var d := Estado.d
	lbl_estado.text = "Energía %d/%d   ·   Púas Espectrales %d   ·   Racha %d días   ·   Fama %d   ·   Seguidores %d" % [
		int(d["energia"]), int(Datos.reglas["energia"]["maxima"]), int(d["pua"]), int(d["racha"]), int(d["fama"]), d["seguidores"].size()]
	if Estado.esta_desafinado():
		lbl_desafinado.text = "¡DESAFINADOS! Tu equipo no puede combatir por %s. Cada ejercicio extra resta 1 minuto (en Tareas reales)." % Estado.formato_tiempo(Estado.segundos_desafinado())
	elif bool(d.get("en_sintonia", false)):
		lbl_desafinado.text = "En sintonía: +5% de daño en el próximo combate."
		lbl_desafinado.add_theme_color_override("font_color", UI.ESPECTRAL)
	else:
		lbl_desafinado.text = ""


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 30 == 0:
		_actualizar_estado()
