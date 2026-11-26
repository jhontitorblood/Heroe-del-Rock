extends "res://scripts/pantallas/pantalla.gd"
## Centro de Mando: logo arriba, protagonista con su estado y menú en botones de a 2.

var lbl_desafinado: Label
var lbl_stats: Label
var foto: TextureRect


func _ready() -> void:
	Estado.revisar_dia()
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando"), 0.55)
	var m := UI.margen(self, 16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	# 1) Logo arriba
	var logo := UI.imagen(Datos.textura("ui", "logo"), Vector2(0, 130))
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(logo)

	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 16)
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cuerpo)

	# 2) Protagonista y su estado (izquierda)
	var cab := UI.panel()
	cab.custom_minimum_size = Vector2(430, 0)
	cuerpo.add_child(cab)
	var izq := VBoxContainer.new()
	izq.add_theme_constant_override("separation", 8)
	cab.add_child(izq)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	izq.add_child(h)
	var col_foto := VBoxContainer.new()
	h.add_child(col_foto)
	foto = UI.imagen(Estado.textura_protagonista(), Vector2(190, 190))
	col_foto.add_child(foto)
	col_foto.add_child(UI.boton("Cambiar foto", _menu_foto, Vector2(190, 50)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	h.add_child(info)
	var nom := UI.etiqueta(Estado.nombre_jugador(), 28, UI.ORO)
	nom.clip_text = true
	info.add_child(nom)
	info.add_child(UI.etiqueta("Nivel %d" % int(Estado.d["nivel"]), 22, UI.TEXTO))
	info.add_child(UI.barra(int(Estado.d["xp"]), Estado.xp_necesaria(int(Estado.d["nivel"])), Color("#ffd23a"), 12))
	lbl_stats = UI.etiqueta("", 19, UI.TEXTO)
	info.add_child(lbl_stats)
	lbl_desafinado = UI.etiqueta("", 18, Color("#ff7a7a"), true)
	izq.add_child(lbl_desafinado)
	_actualizar_estado()

	# 3) Menú en botones de a 2, mismo orden (derecha)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(g)
	var botones := [
		["Campaña", "Historia y territorios", func(): Estado.ir("campana")],
		["Mapa", "Zona actual y enemigos", func(): Estado.ir("mapa", {"zona": "cotoca"})],
		["Escuadrón", "Elige quién combate", func(): Estado.ir("escuadron")],
		["Equipo", "Estadísticas y habilidades", func(): Estado.ir("equipo")],
		["Archivo", "Tu legión espectral", func(): Estado.ir("archivo")],
		["Tareas reales", "Gana experiencia y energía", func(): Estado.ir("tareas")],
		["Sala de Ensayo", "Recupera a tu equipo", func(): Estado.ir("ensayo")],
		["Menú principal", "Salir al inicio", func(): Estado.ir("titulo")],
	]
	for b in botones:
		var bt := Button.new()
		bt.text = "%s\n%s" % [b[0], b[1]]
		bt.add_theme_font_size_override("font_size", 21)
		bt.custom_minimum_size = Vector2(0, 100)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bt.pressed.connect(b[2])
		g.add_child(bt)


func _actualizar_estado() -> void:
	var d := Estado.d
	lbl_stats.text = "Energía: %d / %d\nPúas Espectrales: %d\nRacha: %d días\nFama: %d\nSeguidores: %d" % [
		int(d["energia"]), int(Datos.reglas["energia"]["maxima"]), int(d["pua"]), int(d["racha"]), int(d["fama"]), d["seguidores"].size()]
	if Estado.esta_desafinado():
		lbl_desafinado.text = "¡DESAFINADOS! Tu equipo no puede combatir por %s. Cada ejercicio extra resta 1 minuto (en Tareas reales)." % Estado.formato_tiempo(Estado.segundos_desafinado())
		lbl_desafinado.add_theme_color_override("font_color", Color("#ff7a7a"))
	elif bool(d.get("en_sintonia", false)):
		lbl_desafinado.text = "En sintonía: +5% de daño en el próximo combate."
		lbl_desafinado.add_theme_color_override("font_color", UI.ESPECTRAL)
	else:
		lbl_desafinado.text = ""


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 30 == 0:
		_actualizar_estado()


# ---------------------------------------------------------------------
# Foto del protagonista
# ---------------------------------------------------------------------

func _menu_foto() -> void:
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 600)
	v.add_child(UI.etiqueta("Foto del protagonista", 30, UI.ORO))
	v.add_child(UI.etiqueta("Elige una foto de tu teléfono. Se guarda una copia dentro del juego.", 20, UI.TEXTO, true))
	v.add_child(UI.boton("Elegir foto de la galería", func():
		capa.queue_free()
		_elegir_foto(), Vector2(0, 68)))
	v.add_child(UI.boton("Usar la imagen original", func():
		capa.queue_free()
		Estado.quitar_foto()
		foto.texture = Estado.textura_protagonista(), Vector2(0, 68)))
	v.add_child(UI.boton("Cancelar", func(): capa.queue_free(), Vector2(0, 60)))


func _elegir_foto() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var filtros := PackedStringArray(["image/*"]) if OS.has_feature("android") else PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes"])
		DisplayServer.file_dialog_show("Elige una foto", OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filtros, _foto_elegida)
	else:
		var fd := FileDialog.new()
		fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		fd.access = FileDialog.ACCESS_FILESYSTEM
		fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes"])
		fd.file_selected.connect(func(ruta: String): _foto_elegida(true, PackedStringArray([ruta]), 0))
		add_child(fd)
		fd.popup_centered_ratio(0.9)


func _foto_elegida(ok: bool, rutas: PackedStringArray, _filtro: int) -> void:
	if not ok or rutas.is_empty():
		return
	_aplicar_foto.call_deferred(rutas[0])


func _aplicar_foto(ruta: String) -> void:
	var err := Estado.guardar_foto(ruta)
	if err != "":
		UI.aviso(self, "Foto", err)
		return
	foto.texture = Estado.textura_protagonista()
