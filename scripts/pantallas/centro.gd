extends "res://scripts/pantallas/pantalla.gd"
## Menú principal al estilo de un juego de rock clásico: fondo ilustrado con el logo,
## perfil del protagonista sobre la calavera y opciones escalonadas sobre la zona oscura.

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const HUESO := Color("#ece3d0")
const ROJO := Color("#d8232c")
const ROJO_OSCURO := Color("#5c0a10")

# [texto, tamaño, x del centro, y del centro, acción]
var opciones := [
	["CAMPAÑA", 64, 1040, 70, "campana"],
	["MAPA", 50, 1080, 140, "mapa"],
	["ESCUADRÓN", 56, 1025, 206, "escuadron"],
	["EQUIPO", 50, 1070, 272, "equipo"],
	["ARCHIVO", 54, 1040, 336, "archivo"],
	["TAREAS REALES", 48, 1058, 400, "tareas"],
	["SALA DE ENSAYO", 52, 1035, 464, "ensayo"],
	["SALIR", 46, 1020, 560, "titulo"],
]

var lbl_desafinado: Label
var lbl_stats: Label
var foto: TextureRect
var navegando := false
var lienzo: Control  # todo lo que va sobre el arte se agrega aquí (coordenadas 1280×720)


func _ready() -> void:
	Estado.revisar_dia()
	var fondo := Datos.textura("escenarios", "esc_menu_principal")
	lienzo = UI.lienzo(self, fondo if fondo else Datos.textura("escenarios", "esc_centro_mando"))
	_perfil()
	for o in opciones:
		_opcion(o[0], o[1], Vector2(o[2], o[3]), o[4])
	_pista()
	var ver := _texto("VERSIÓN 0.2 · BETA DE COTOCA", 18, ROJO, Color.BLACK, 5)
	ver.position = Vector2(1060, 4)
	lienzo.add_child(ver)
	_actualizar_estado()


## Pista guía al pie, como las de los juegos de consola.
func _pista() -> void:
	var pild := PanelContainer.new()
	var est := StyleBoxFlat.new()
	est.bg_color = Color(0.08, 0.06, 0.06, 0.85)
	est.border_color = Color("#b8b0a0")
	est.set_border_width_all(3)
	est.set_corner_radius_all(22)
	est.content_margin_left = 22
	est.content_margin_right = 22
	est.content_margin_top = 4
	est.content_margin_bottom = 4
	pild.add_theme_stylebox_override("panel", est)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pild.add_child(h)
	var punto := Panel.new()
	var ep := StyleBoxFlat.new()
	ep.bg_color = ROJO
	ep.set_corner_radius_all(9)
	punto.add_theme_stylebox_override("panel", ep)
	punto.custom_minimum_size = Vector2(18, 18)
	punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(punto)
	h.add_child(_texto("TOCA UNA OPCIÓN", 26, HUESO, Color.BLACK, 6))
	lienzo.add_child(pild)
	pild.reset_size()
	pild.position = Vector2(1045 - pild.size.x / 2.0, 640)
	var tw := punto.create_tween().set_loops()
	tw.tween_property(punto, "modulate:a", 0.3, 0.7)
	tw.tween_property(punto, "modulate:a", 1.0, 0.7)


func _texto(t: String, tam: int, color: Color, borde: Color, grosor: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", borde)
	l.add_theme_constant_override("outline_size", grosor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Perfil del protagonista, justo debajo del logo y sobre la calavera del fondo.
func _perfil() -> void:
	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.05, 0.01, 0.02, 0.72)
	estilo.border_color = ROJO
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	caja.add_theme_stylebox_override("panel", estilo)
	caja.position = Vector2(120, 380)
	caja.custom_minimum_size = Vector2(520, 0)
	lienzo.add_child(caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	caja.add_child(h)
	var col_foto := VBoxContainer.new()
	col_foto.add_theme_constant_override("separation", 6)
	h.add_child(col_foto)
	var marco := PanelContainer.new()
	var em := StyleBoxFlat.new()
	em.bg_color = Color.BLACK
	em.border_color = HUESO
	em.set_border_width_all(3)
	marco.add_theme_stylebox_override("panel", em)
	col_foto.add_child(marco)
	foto = UI.imagen(Estado.textura_protagonista(), Vector2(170, 170))
	marco.add_child(foto)
	var bf := Button.new()
	bf.text = "CAMBIAR FOTO"
	_estilo_boton(bf, 24)
	bf.pressed.connect(_menu_foto)
	col_foto.add_child(bf)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var nom := _texto(Estado.nombre_jugador().to_upper(), 42, HUESO, ROJO_OSCURO, 10)
	nom.clip_text = true
	info.add_child(nom)
	info.add_child(_texto("NIVEL %d" % int(Estado.d["nivel"]), 32, ROJO, Color.BLACK, 8))
	var xp := UI.barra(int(Estado.d["xp"]), Estado.xp_necesaria(int(Estado.d["nivel"])), ROJO, 10)
	info.add_child(xp)
	lbl_stats = _texto("", 23, HUESO, Color.BLACK, 6)
	info.add_child(lbl_stats)
	lbl_desafinado = _texto("", 20, Color("#ff6a6a"), Color.BLACK, 6)
	lbl_desafinado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desafinado.custom_minimum_size = Vector2(300, 0)
	info.add_child(lbl_desafinado)


func _estilo_boton(b: Button, tam: int) -> void:
	b.add_theme_font_override("font", FUENTE)
	b.add_theme_font_size_override("font_size", tam)
	b.add_theme_color_override("font_color", HUESO)
	b.add_theme_color_override("font_hover_color", HUESO)
	b.add_theme_color_override("font_pressed_color", ROJO_OSCURO)
	b.add_theme_color_override("font_focus_color", HUESO)
	b.add_theme_color_override("font_outline_color", ROJO_OSCURO)
	b.add_theme_constant_override("outline_size", 10)
	var vacio := StyleBoxEmpty.new()
	var marcado := StyleBoxFlat.new()
	marcado.bg_color = HUESO
	marcado.set_corner_radius_all(4)
	marcado.content_margin_left = 14
	marcado.content_margin_right = 14
	for estado in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(estado, vacio)
	b.add_theme_stylebox_override("pressed", marcado)


## Opción del menú: texto grande escalonado sobre la zona oscura del fondo.
func _opcion(texto: String, tam: int, centro: Vector2, destino: String) -> void:
	var b := Button.new()
	b.text = texto
	_estilo_boton(b, tam)
	lienzo.add_child(b)
	b.reset_size()
	b.position = centro - b.size / 2.0
	b.pivot_offset = b.size / 2.0
	b.pressed.connect(func():
		if navegando:
			return
		navegando = true
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.08)
		tw.tween_property(b, "scale", Vector2.ONE, 0.08)
		tw.tween_callback(func():
			if destino == "mapa":
				Estado.ir("mapa", {"zona": "cotoca"})
			else:
				Estado.ir(destino)))


func _actualizar_estado() -> void:
	var d := Estado.d
	lbl_stats.text = "ENERGÍA %d/%d\nPÚAS ESPECTRALES %d\nRACHA %d DÍAS\nFAMA %d  ·  SEGUIDORES %d" % [
		int(d["energia"]), int(Datos.reglas["energia"]["maxima"]), int(d["pua"]), int(d["racha"]), int(d["fama"]), d["seguidores"].size()]
	if Estado.esta_desafinado():
		lbl_desafinado.text = "¡DESAFINADOS! %s" % Estado.formato_tiempo(Estado.segundos_desafinado())
		lbl_desafinado.add_theme_color_override("font_color", Color("#ff6a6a"))
	elif bool(d.get("en_sintonia", false)):
		lbl_desafinado.text = "EN SINTONÍA: +5% DE DAÑO"
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
