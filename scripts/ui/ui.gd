extends RefCounted
## Utilidades de interfaz: tema, botones, paneles, diálogos y avisos.

const FONDO := Color("#120d1a")
const PANEL := Color(0.08, 0.05, 0.12, 0.88)
const ACENTO := Color("#ff3a5e")
const ORO := Color("#ffd23a")
const TEXTO := Color("#f4eefc")
const TENUE := Color("#b9aecb")
const ESPECTRAL := Color("#5ef2ff")
const FUENTE_ROCK := preload("res://assets/fuentes/Bangers-Regular.ttf")
const TAM_ICONO := 74.0


static func crear_tema() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	var normal := _caja(Color("#2a1838"), Color("#ff3a5e"), 2)
	var hover := _caja(Color("#3b2150"), Color("#ffd23a"), 2)
	var pressed := _caja(Color("#ff3a5e"), Color("#ffd23a"), 2)
	var disabled := _caja(Color("#1c1424"), Color("#4a3d58"), 1)
	for estilo in [["normal", normal], ["hover", hover], ["pressed", pressed], ["disabled", disabled], ["focus", hover]]:
		t.set_stylebox(estilo[0], "Button", estilo[1])
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_disabled_color", "Button", Color("#6d6078"))
	t.set_color("font_color", "Label", TEXTO)
	t.set_stylebox("panel", "PanelContainer", _caja(PANEL, Color("#ff3a5e55"), 1))
	var barra_fondo := _caja(Color("#1a1022"), Color("#00000000"), 0)
	var barra := _caja(Color("#3ae889"), Color("#00000000"), 0)
	t.set_stylebox("background", "ProgressBar", barra_fondo)
	t.set_stylebox("fill", "ProgressBar", barra)
	t.set_stylebox("normal", "LineEdit", _caja(Color("#1a1022"), Color("#ffd23a"), 2))
	return t


static func _caja(fondo: Color, borde: Color, ancho: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(ancho)
	s.set_corner_radius_all(10)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func boton(texto: String, cb: Callable, tam := Vector2(0, 64)) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = tam
	b.pressed.connect(cb)
	return b


static func etiqueta(texto: String, tam := 22, color := TEXTO, envolver := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if envolver:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func panel() -> PanelContainer:
	return PanelContainer.new()


static func panel_color(fondo: Color, borde: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _caja(fondo, borde, 2))
	return p


static func barra(valor: float, maximo: float, color: Color, alto := 14) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maximo
	b.value = valor
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, alto)
	# Sin esto la barra toma la altura de la letra y queda más gruesa de lo pedido
	b.add_theme_font_size_override("font_size", 1)
	var fondo_b := _caja(Color("#1a1022"), Color("#00000000"), 0)
	var relleno := _caja(color, Color("#00000000"), 0)
	for c in [fondo_b, relleno]:
		c.set_content_margin_all(0)
		c.set_corner_radius_all(int(min(alto / 2.0, 10)))
	b.add_theme_stylebox_override("background", fondo_b)
	b.add_theme_stylebox_override("fill", relleno)
	return b


static func imagen(tex: Texture2D, tam: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = tam
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r


## Fondo a pantalla completa con imagen (o color si falta) y una capa oscura.
static func fondo(padre: Control, tex: Texture2D, oscuro := 0.45) -> void:
	var c := ColorRect.new()
	c.color = FONDO
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(c)
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padre.add_child(r)
	var o := ColorRect.new()
	o.color = Color(0, 0, 0, oscuro)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(o)


## Lienzo de 1280×720 que se mueve y escala junto con la imagen de fondo, para que lo que
## se pone encima (menús, nodos de mapa) quede siempre sobre la misma parte del arte.
## Agrega encima con posiciones de 1280×720.
##
## Dos modos, según la medida de la imagen:
## - Con margen extra (2520×1440, proporción 7:4): la imagen llena toda la pantalla de
##   cualquier aparato sin deformarse ni dejar bordes; solo se recorta parte del margen.
##   El lienzo corresponde a la ZONA SEGURA central de 1920×1080.
## - Imagen 16:9 normal: se ve completa y los costados sobrantes se rellenan oscurecidos.
static func lienzo(padre: Control, tex: Texture2D) -> Control:
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(negro)
	var con_margen := tex != null and absf(float(tex.get_width()) / tex.get_height() - Lienzo.PROPORCION_MARGEN) < 0.02
	if tex and not con_margen:
		var relleno := TextureRect.new()
		relleno.texture = tex
		relleno.set_anchors_preset(Control.PRESET_FULL_RECT)
		relleno.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		relleno.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		relleno.modulate = Color(0.14, 0.12, 0.12)
		relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padre.add_child(relleno)
	var l := Lienzo.new()
	l.con_margen = con_margen
	padre.add_child(l)
	if tex:
		var arte := TextureRect.new()
		arte.texture = tex
		arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arte.stretch_mode = TextureRect.STRETCH_SCALE
		arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if con_margen:
			# La imagen completa sobresale de la zona segura por todos lados
			arte.size = Lienzo.ARTE_MARGEN
			arte.position = -(Lienzo.ARTE_MARGEN - Lienzo.BASE) / 2.0
		else:
			arte.size = Lienzo.BASE
		l.add_child(arte)
	return l


class Lienzo extends Control:
	const BASE := Vector2(1280, 720)
	# 2520×1440 con zona segura de 1920×1080 → en unidades del lienzo: 1680×960
	const ARTE_MARGEN := Vector2(1680, 960)
	const PROPORCION_MARGEN := 2520.0 / 1440.0
	var con_margen := false

	func _ready() -> void:
		size = BASE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_parent().resized.connect(_ajustar)
		_ajustar.call_deferred()

	func _ajustar() -> void:
		var p: Vector2 = get_parent().size
		if p.x <= 0 or p.y <= 0:
			return
		var k: float
		if con_margen:
			# La imagen completa cubre la pantalla (se recorta solo el margen)
			k = maxf(p.x / ARTE_MARGEN.x, p.y / ARTE_MARGEN.y)
		else:
			# La imagen 16:9 entra completa
			k = minf(p.x / BASE.x, p.y / BASE.y)
		scale = Vector2(k, k)
		position = (p - BASE * k) / 2.0


## Marcador de mapa: ícono de estado ("bloqueado", "desbloqueado", "vencido") centrado en
## `centro`, con etiqueta corta debajo. El desbloqueado late. Devuelve el botón tocable.
static func marcador(padre: Control, centro: Vector2, estado: String, texto: String, al_tocar: Callable, apagado := false) -> Button:
	var raiz := Control.new()
	raiz.position = centro
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(raiz)
	var ico := TextureRect.new()
	ico.texture = Datos.textura("ui", "icono_" + estado)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.size = Vector2(TAM_ICONO, TAM_ICONO)
	ico.position = -ico.size / 2.0
	ico.pivot_offset = ico.size / 2.0
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if apagado:
		ico.modulate = Color(0.5, 0.5, 0.5)
	raiz.add_child(ico)
	if estado == "desbloqueado" and not apagado:
		var tw := ico.create_tween().set_loops()
		tw.tween_property(ico, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ico, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	var et := Label.new()
	et.text = texto
	et.add_theme_font_override("font", FUENTE_ROCK)
	et.add_theme_font_size_override("font_size", 20)
	et.add_theme_color_override("font_color", {"bloqueado": Color("#b8b0c0"), "desbloqueado": Color("#ece3d0"), "vencido": Color("#ffd23a")}.get(estado, TEXTO))
	et.add_theme_color_override("font_outline_color", Color.BLACK)
	et.add_theme_constant_override("outline_size", 7)
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	et.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo_et := StyleBoxFlat.new()
	fondo_et.bg_color = Color(0, 0, 0, 0.72)
	fondo_et.set_corner_radius_all(8)
	fondo_et.content_margin_left = 8
	fondo_et.content_margin_right = 8
	fondo_et.content_margin_top = 1
	fondo_et.content_margin_bottom = 1
	et.add_theme_stylebox_override("normal", fondo_et)
	raiz.add_child(et)
	et.reset_size()
	et.position = Vector2(-et.size.x / 2.0, TAM_ICONO / 2.0 - 4)
	var b := Button.new()
	for e in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	b.size = Vector2(max(TAM_ICONO, et.size.x), TAM_ICONO + et.size.y)
	b.position = Vector2(-b.size.x / 2.0, -TAM_ICONO / 2.0)
	b.pressed.connect(al_tocar)
	raiz.add_child(b)
	return b


## Contenedor con márgenes a pantalla completa.
static func margen(padre: Control, m := 24) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + lado, m)
	padre.add_child(mc)
	return mc


static func encabezado(titulo: String, volver: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.add_child(boton("< Volver", volver, Vector2(150, 56)))
	var l := etiqueta(titulo, 34, ORO)
	var fondo_t := StyleBoxFlat.new()
	fondo_t.bg_color = Color(0.05, 0.02, 0.08, 0.72)
	fondo_t.set_corner_radius_all(10)
	fondo_t.content_margin_left = 16
	fondo_t.content_margin_right = 16
	fondo_t.content_margin_top = 2
	fondo_t.content_margin_bottom = 4
	l.add_theme_stylebox_override("normal", fondo_t)
	h.add_child(l)
	return h


## Capa modal que bloquea lo de abajo.
static func capa_modal(padre: Control) -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	var o := ColorRect.new()
	o.color = Color(0, 0, 0, 0.7)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(o)
	padre.add_child(capa)
	return capa


static func centrado(capa: Control, ancho := 760) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(cc)
	var p := panel()
	p.custom_minimum_size = Vector2(ancho, 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	return v


## Aviso simple con botón Aceptar.
static func aviso(padre: Control, titulo: String, texto: String, al_cerrar := Callable()) -> void:
	var capa := capa_modal(padre)
	var v := centrado(capa)
	v.add_child(etiqueta(titulo, 30, ORO))
	v.add_child(etiqueta(texto, 22, TEXTO, true))
	var b := boton("Aceptar", func():
		capa.queue_free()
		if al_cerrar.is_valid():
			al_cerrar.call())
	v.add_child(b)


## Diálogo por líneas [[quién, texto], ...]. El nombre {jugador} se reemplaza.
static func dialogo(padre: Control, lineas: Array, al_terminar: Callable) -> void:
	if lineas.is_empty():
		al_terminar.call()
		return
	var capa := capa_modal(padre)
	var caja := panel()
	caja.anchor_left = 0.05
	caja.anchor_right = 0.95
	caja.anchor_top = 0.62
	caja.anchor_bottom = 0.95
	capa.add_child(caja)
	var v := VBoxContainer.new()
	caja.add_child(v)
	var quien := etiqueta("", 26, ORO)
	var texto := etiqueta("", 24, TEXTO, true)
	texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(quien)
	v.add_child(texto)
	var sig := boton("Continuar >", func(): pass, Vector2(220, 56))
	sig.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(sig)
	var i := [0]
	var mostrar := func():
		var l: Array = lineas[i[0]]
		quien.text = l[0]
		texto.text = String(l[1]).replace("{jugador}", Estado.nombre_jugador() if not Estado.d.is_empty() else "")
	mostrar.call()
	sig.pressed.connect(func():
		i[0] += 1
		if i[0] >= lineas.size():
			capa.queue_free()
			al_terminar.call()
		else:
			mostrar.call())


## Texto flotante que sube y se desvanece (daño, curación).
static func flotante(padre: Control, texto: String, color: Color, pos: Vector2) -> void:
	var l := etiqueta(texto, 30, color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = pos
	l.z_index = 10
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position", pos + Vector2(0, -60), 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)
