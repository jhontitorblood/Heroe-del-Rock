extends "res://scripts/pantallas/pantalla.gd"
## Selección de protagonista: dos cuadros centrados en penumbra. Al aceptar,
## la imagen elegida cambia a la animación de la señal de rock.

const FPS_ANIMACION := 12.0
const SEG_ANIMACION := 2.6

var genero := ""
var nombre_edit: LineEdit
var tarjetas := {}  # g -> {boton, img}
var btn_aceptar: Button
var animando := false

const INTRO := [
	["Narrador", "Santa Cruz de la Sierra. Dicen que la música de los viejos tiempos se está apagando..."],
	["Silvano Roca", "Te vi tocar en la plaza, {jugador}. Tienes algo que no se aprende: cuando tocas, los espectros escuchan."],
	["Silvano Roca", "Las bandas de las provincias se han vuelto agresivas. Algo las está silenciando por dentro."],
	["Silvano Roca", "Empieza por Cotoca. Los Bravos del Jichi dominan la laguna. Vence a sus músicos y, si puedes, despiértalos."],
	["Silvano Roca", "Y lo más importante: la fuerza de un rockero se gana fuera del escenario. Entrena, ensaya, trabaja... y registra tus tareas."],
]


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_seleccion"), 0.25)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	cc.add_child(v)
	var t := UI.etiqueta("Elige a tu protagonista", 36, UI.ORO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 8)
	v.add_child(t)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 36)
	v.add_child(h)
	for g in ["m", "f"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(340, 400)
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		b.add_child(vb)
		var img := UI.imagen(Datos.textura("personajes", "seleccion_protagonista_" + g), Vector2(320, 320))
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(img)
		var l := UI.etiqueta("Masculino" if g == "m" else "Femenina", 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(l)
		b.pressed.connect(_elegir.bind(g))
		h.add_child(b)
		tarjetas[g] = {"boton": b, "img": img}
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	v.add_child(fila)
	nombre_edit = LineEdit.new()
	nombre_edit.placeholder_text = "Escribe tu nombre"
	nombre_edit.max_length = 16
	nombre_edit.custom_minimum_size = Vector2(380, 62)
	fila.add_child(nombre_edit)
	btn_aceptar = UI.boton("Aceptar", _aceptar, Vector2(200, 64))
	fila.add_child(btn_aceptar)
	_pintar()


func _pintar() -> void:
	for g in tarjetas:
		var b: Button = tarjetas[g]["boton"]
		var elegido: bool = g == genero
		# Leve oscuridad para los no elegidos
		b.modulate = Color(1, 1, 1) if elegido else Color(0.5, 0.5, 0.55)
		var borde := UI.ORO if elegido else Color("#00000000")
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(0, 0, 0, 0.45)
		caja.border_color = borde
		caja.set_border_width_all(4)
		caja.set_corner_radius_all(16)
		for estado in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(estado, caja)


func _elegir(g: String) -> void:
	if animando:
		return
	genero = g
	_pintar()


func _aceptar() -> void:
	if animando:
		return
	if genero == "":
		UI.aviso(self, "Elige un protagonista", "Toca el cuadro masculino o femenino.")
		return
	var n := nombre_edit.text.strip_edges()
	if n == "":
		UI.aviso(self, "Falta tu nombre", "Escribe el nombre de tu personaje.")
		return
	animando = true
	btn_aceptar.disabled = true
	nombre_edit.editable = false
	var otro := "f" if genero == "m" else "m"
	tarjetas[otro]["boton"].create_tween().tween_property(tarjetas[otro]["boton"], "modulate:a", 0.0, 0.5)
	await _animar_rock(tarjetas[genero]["img"], "protagonista_%s_rock" % genero)
	Estado.nueva_partida(genero, n)
	Estado.d["vistos"]["intro"] = true
	Estado.guardar()
	UI.dialogo(self, INTRO, func(): Estado.ir("centro"))


## Reproduce la animación de la señal de rock durante unos segundos.
func _animar_rock(img: TextureRect, nombre: String) -> void:
	var cuadros := Datos.animacion(nombre)
	if cuadros.is_empty():
		await get_tree().create_timer(0.5).timeout
		return
	var total := int(SEG_ANIMACION * FPS_ANIMACION)
	for i in total:
		img.texture = cuadros[i % cuadros.size()]
		await get_tree().create_timer(1.0 / FPS_ANIMACION).timeout
		if not is_inside_tree():
			return
	img.texture = cuadros[cuadros.size() - 1]
