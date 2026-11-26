extends "res://scripts/pantallas/pantalla.gd"

var genero := "m"
var nombre_edit: LineEdit
var tarjetas := {}

const INTRO := [
	["Narrador", "Santa Cruz de la Sierra. Dicen que la música de los viejos tiempos se está apagando..."],
	["Silvano Roca", "Te vi tocar en la plaza, {jugador}. Tienes algo que no se aprende: cuando tocas, los espectros escuchan."],
	["Silvano Roca", "Las bandas de las provincias se han vuelto agresivas. Algo las está silenciando por dentro."],
	["Silvano Roca", "Empieza por Cotoca. Los Bravos del Jichi dominan la laguna. Vence a sus músicos y, si puedes, despiértalos."],
	["Silvano Roca", "Y lo más importante: la fuerza de un rockero se gana fuera del escenario. Entrena, ensaya, trabaja... y registra tus tareas."],
]


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_titulo"), 0.6)
	var m := UI.margen(self, 32)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	v.add_child(UI.etiqueta("Elige a tu protagonista", 38, UI.ORO))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 40)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	for g in ["m", "f"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(300, 360)
		b.toggle_mode = true
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		var img := UI.imagen(Datos.sprite("protagonista_" + g, false), Vector2(256, 256))
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(img)
		var l := UI.etiqueta("Protagonista masculino" if g == "m" else "Protagonista femenina", 22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(l)
		b.add_child(vb)
		b.pressed.connect(_elegir.bind(g))
		h.add_child(b)
		tarjetas[g] = b
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 16)
	fila.add_child(UI.etiqueta("Nombre:", 26))
	nombre_edit = LineEdit.new()
	nombre_edit.placeholder_text = "Escribe tu nombre"
	nombre_edit.max_length = 16
	nombre_edit.custom_minimum_size = Vector2(380, 60)
	fila.add_child(nombre_edit)
	fila.add_child(UI.boton("Comenzar >", _comenzar, Vector2(240, 64)))
	v.add_child(fila)
	_elegir("m")


func _elegir(g: String) -> void:
	genero = g
	for k in tarjetas:
		tarjetas[k].button_pressed = (k == g)


func _comenzar() -> void:
	var n := nombre_edit.text.strip_edges()
	if n == "":
		UI.aviso(self, "Falta tu nombre", "Escribe el nombre de tu personaje.")
		return
	Estado.nueva_partida(genero, n)
	Estado.d["vistos"]["intro"] = true
	Estado.guardar()
	UI.dialogo(self, INTRO, func(): Estado.ir("centro"))
