extends "res://scripts/pantallas/pantalla.gd"
## Pantalla de combate por turnos + Despertar espectral al ganar.

const Batalla = preload("res://scripts/core/batalla.gd")

var b: Batalla
var zona: Dictionary
var nodo: Dictionary
var info_enemigos: Dictionary
var tarjetas := {}  # uid -> {boton, hp, hp_txt, est, med, img}
var lbl_turno: Label
var lbl_info: Label
var caja_habs: HBoxContainer
var barra_banda: ProgressBar
var btn_usar: Button
var btn_auto: Button
var seleccion := ""
var orden_box: HBoxContainer
var ultimo_actor = null

# Formaciones (x, y de los pies) según cantidad de combatientes por lado; los enemigos se reflejan
const FORMACIONES := {
	1: [[0.24, 0.62]],
	2: [[0.17, 0.42], [0.31, 0.86]],
	3: [[0.12, 0.36], [0.30, 0.62], [0.12, 0.90]],
	4: [[0.08, 0.32], [0.24, 0.50], [0.08, 0.72], [0.24, 0.90]],
	5: [[0.07, 0.28], [0.21, 0.44], [0.35, 0.60], [0.07, 0.74], [0.21, 0.90]],
}
const TAM_SPRITE := {1: 210, 2: 185, 3: 155, 4: 135, 5: 125}


## Efecto de impacto dibujado a mano, distinto para cada clase musical.
class EfectoGolpe extends Control:
	const DURACION := 0.55
	var tipo := "guitarrista"
	var t := 0.0
	var semilla := randi()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 5

	func _process(delta: float) -> void:
		t += delta
		if t >= DURACION:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var p := t / DURACION
		var a := 1.0 - p
		var c := size * Vector2(0.5, 0.45)
		var r := size.x * 0.5
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		match tipo:
			"guitarrista", "charanguista":
				# Chispas que saltan hacia afuera
				for i in 12:
					var ang := rng.randf() * TAU
					var largo := r * (0.15 + 0.15 * rng.randf())
					var d0 := r * (0.1 + 0.7 * p)
					var dir := Vector2(cos(ang), sin(ang))
					var col := Color("#ffd23a") if i % 2 == 0 else Color("#ff6a2a")
					draw_line(c + dir * d0, c + dir * (d0 + largo), Color(col, a), 4.0, true)
			"bajista":
				# Ondas graves que se expanden
				for i in 3:
					var pr := clampf(p * 1.4 - i * 0.2, 0.0, 1.0)
					if pr > 0:
						draw_arc(c, r * 0.15 + r * 0.6 * pr, 0, TAU, 40, Color(Color("#4a8bff"), (1.0 - pr) * a), 6.0, true)
			"baterista":
				# Golpe seco: estrella de impacto y aro
				var pts := PackedVector2Array()
				for i in 16:
					var ang2 := TAU * i / 16.0
					var rr := (r * 0.45 if i % 2 == 0 else r * 0.2) * (0.6 + 0.6 * p)
					pts.append(c + Vector2(cos(ang2), sin(ang2)) * rr)
				draw_colored_polygon(pts, Color(Color("#ffe07a"), a * 0.85))
				draw_arc(c, r * (0.3 + 0.5 * p), 0, TAU, 40, Color(Color("#ffb02e"), a), 5.0, true)
			"vocalista", "corista":
				# Notas musicales que suben
				for i in 5:
					var x := c.x + (rng.randf() - 0.5) * r * 1.2
					var y := c.y + r * 0.3 - p * r * (0.6 + 0.5 * rng.randf())
					var col2 := Color(Color("#ff7ad9") if i % 2 == 0 else Color("#ffffff"), a)
					draw_circle(Vector2(x, y), 7.0, col2)
					draw_line(Vector2(x + 6, y), Vector2(x + 6, y - 24), col2, 3.0)
					draw_line(Vector2(x + 6, y - 24), Vector2(x + 16, y - 18), col2, 3.0)
			"tecladista":
				# Fallas digitales: cuadros que parpadean
				for i in 14:
					var q := Vector2((rng.randf() - 0.5) * r * 1.3, (rng.randf() - 0.5) * r * 1.3) * (0.5 + p)
					var lado := 6.0 + rng.randf() * 12.0
					if rng.randf() < 0.75:
						draw_rect(Rect2(c + q, Vector2(lado, lado)), Color(Color("#c05cff") if i % 3 else Color("#5ef2ff"), a))
			"ingeniero":
				# Ondas de feedback en zigzag
				for k in 3:
					var y0 := c.y - r * 0.3 + k * r * 0.3
					var pts2 := PackedVector2Array()
					for i in 13:
						var x2 := c.x - r * 0.6 + i * r * 0.1
						pts2.append(Vector2(x2, y0 + (12.0 if (i + k) % 2 == 0 else -12.0) * (1.0 - p * 0.5)))
					draw_polyline(pts2, Color(Color("#3ae8e0"), a), 3.0, true)
			"vientista":
				# Ráfagas de viento en espiral
				for k in 3:
					var base := TAU * k / 3.0 + p * 4.0
					var pts3 := PackedVector2Array()
					for i in 16:
						var ang3 := base + i * 0.25
						pts3.append(c + Vector2(cos(ang3), sin(ang3)) * (r * 0.1 + i * r * 0.03 * (0.6 + p)))
					draw_polyline(pts3, Color(Color("#8be83a"), a), 4.0, true)
			_:
				draw_arc(c, r * (0.2 + 0.5 * p), 0, TAU, 32, Color(1, 1, 1, a), 5.0, true)


## Sombra elíptica bajo los pies: normal, turno (anillo dorado) u objetivo (anillo que late).
class Sombra extends Control:
	var modo := 0
	var color_objetivo := Color.RED
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if modo == 2:
			t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			pts.append(c + Vector2(cos(a) * c.x, sin(a) * c.y))
		draw_colored_polygon(pts.slice(0, 32), Color(0, 0, 0, 0.5))
		if modo == 1:
			draw_polyline(pts, Color("#ffd23a"), 4.0, true)
		elif modo == 2:
			draw_polyline(pts, Color(color_objetivo, 0.5 + 0.5 * sin(t * 7.0)), 4.0, true)
var esperando_jugador := false
var auto := false
var terminado := false


func _ready() -> void:
	zona = Datos.zona(params["zona"])
	nodo = Datos.nodo(params["zona"], params["nodo"])
	info_enemigos = Estado.enemigos_de_nodo(zona, nodo)
	b = Batalla.new()
	b.quimica = Estado.d["quimica"]
	if bool(Estado.d.get("en_sintonia", false)):
		b.bonus_dano_aliados = float(Datos.reglas["ensayo"]["real"]["bonus_dano"])
	for m in Estado.equipo_combate():
		b.agregar(m, Batalla.ALIADO)
	var i := 0
	for id in info_enemigos["ids"]:
		b.agregar({"uid": "e%d" % i, "base_id": id, "nivel": int(info_enemigos["nivel"]),
			"fuerza": info_enemigos["fuerza"], "fuerza_hp": info_enemigos["fuerza_hp"]}, Batalla.ENEMIGO)
		Estado.d["encontrados"][id] = true
		i += 1
	var bonus := b.preparar_bonus_banda()
	_construir()
	if not bonus.is_empty():
		lbl_info.text = "%s Tu equipo junta %s tipos de instrumento distintos: +%d%% de daño y la Definitiva de banda se carga más rápido." % [
			bonus["nombre"], "las 5" if bonus["nombre"].contains("Orquesta") else "3 o más", int(float(bonus["dano"]) * 100)]
		await get_tree().create_timer(1.6).timeout
	_siguiente()


# ---------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------

func _construir() -> void:
	UI.fondo(self, Datos.textura("escenarios", nodo.get("fondo", "")), 0.3)
	var m := UI.margen(self, 16)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	lbl_turno = UI.etiqueta("", 20, UI.ORO)
	lbl_turno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_turno.clip_text = true
	top.add_child(lbl_turno)
	# Orden de turnos: quién actúa ahora y después
	orden_box = HBoxContainer.new()
	orden_box.add_theme_constant_override("separation", 4)
	orden_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(orden_box)
	btn_auto = UI.boton("Auto: NO", _alternar_auto, Vector2(150, 50))
	top.add_child(btn_auto)
	top.add_child(UI.boton("Retirarse", _retirarse, Vector2(150, 50)))

	# Campo de batalla: sprites libres en formación (aliados a la izquierda, enemigos a la derecha)
	var campo := Control.new()
	campo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	campo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(campo)
	var colocados := []
	for lado in [Batalla.ALIADO, Batalla.ENEMIGO]:
		var lista := b.lado(lado, false)
		var n: int = clamp(lista.size(), 1, 5)
		var form: Array = FORMACIONES[n]
		var tam: int = TAM_SPRITE[n]
		for i in lista.size():
			var p: Array = form[min(i, form.size() - 1)]
			var fx: float = p[0] if lado == Batalla.ALIADO else 1.0 - p[0]
			colocados.append([float(p[1]), _unidad(lista[i], fx, float(p[1]), tam)])
	# Los de más abajo se dibujan delante
	colocados.sort_custom(func(x, y): return x[0] < y[0])
	for c in colocados:
		campo.add_child(c[1])

	var abajo := UI.panel()
	v.add_child(abajo)
	var av := VBoxContainer.new()
	abajo.add_child(av)
	var fila_info := HBoxContainer.new()
	av.add_child(fila_info)
	lbl_info = UI.etiqueta("", 20, UI.TEXTO, true)
	lbl_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_info.custom_minimum_size = Vector2(0, 40)
	fila_info.add_child(lbl_info)
	btn_usar = UI.boton("Usar", _usar_sin_objetivo, Vector2(140, 52))
	btn_usar.visible = false
	fila_info.add_child(btn_usar)
	var fila_banda := HBoxContainer.new()
	av.add_child(fila_banda)
	fila_banda.add_child(UI.etiqueta("Banda ", 16, UI.TENUE))
	barra_banda = UI.barra(0, 100, Color("#ff3a5e"), 10)
	barra_banda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra_banda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_banda.add_child(barra_banda)
	caja_habs = HBoxContainer.new()
	caja_habs.add_theme_constant_override("separation", 8)
	av.add_child(caja_habs)
	_refrescar()


## Un combatiente en el campo: sombra bajo los pies, sprite sin recuadro y barras debajo.
func _unidad(u, fx: float, fy: float, s: int) -> Control:
	var n := Control.new()
	n.anchor_left = fx
	n.anchor_right = fx
	n.anchor_top = fy
	n.anchor_bottom = fy
	n.offset_left = -s / 2.0
	n.offset_right = s / 2.0
	n.offset_top = -s
	n.offset_bottom = 50
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombra := Sombra.new()
	sombra.position = Vector2(s * 0.14, s * 0.88)
	sombra.size = Vector2(s * 0.72, s * 0.2)
	sombra.color_objetivo = Color("#ff4a4a") if u.lado == Batalla.ENEMIGO else UI.ESPECTRAL
	n.add_child(sombra)
	var spr := TextureRect.new()
	spr.texture = Datos.sprite(u.imagen, u.espectral)
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.size = Vector2(s, s)
	spr.pivot_offset = Vector2(s / 2.0, s * 0.95)
	spr.flip_h = u.voltear()
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(spr)
	# Zona tocable para elegir objetivo
	var bt := Button.new()
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		bt.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	bt.position = Vector2(s * 0.12, s * 0.05)
	bt.size = Vector2(s * 0.76, s * 0.95)
	bt.pressed.connect(_tocar_tarjeta.bind(u.uid))
	n.add_child(bt)
	# Barras bajo los pies
	var barras := VBoxContainer.new()
	barras.position = Vector2(-s * 0.1, s + 2)
	barras.size = Vector2(s * 1.2, 48)
	barras.add_theme_constant_override("separation", 2)
	barras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(barras)
	var rz := Datos.rareza(u.rareza)
	var color_nombre: Color = Color(rz["color"]) if u.lado == Batalla.ENEMIGO else (UI.ESPECTRAL if u.espectral else UI.ORO)
	var fila_nom := HBoxContainer.new()
	fila_nom.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_nom.add_theme_constant_override("separation", 4)
	fila_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_nom.add_child(UI.icono_tipo(u.familia, 20))
	var nom := _texto(u.nombre, 14, color_nombre)
	nom.clip_text = false
	fila_nom.add_child(nom)
	barras.add_child(fila_nom)
	var hp := UI.barra(u.hp, u.hp_max, Color("#3ae889") if u.lado == Batalla.ALIADO else Color("#ff4a4a"), 9)
	hp.custom_minimum_size.x = s * 0.8
	hp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	barras.add_child(hp)
	var med := UI.barra(u.medidor, 100, Color("#ffd23a"), 5)
	med.custom_minimum_size.x = s * 0.8
	med.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	barras.add_child(med)
	var hp_txt := _texto("", 12, UI.TEXTO)
	barras.add_child(hp_txt)
	for c in barras.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Respiración: leve balanceo continuo
	var bob := spr.create_tween().set_loops()
	bob.tween_interval(randf() * 0.8)
	bob.tween_property(spr, "position:y", -4.0, 0.9).set_trans(Tween.TRANS_SINE)
	bob.tween_property(spr, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	tarjetas[u.uid] = {"nodo": n, "spr": spr, "sombra": sombra, "hp": hp, "hp_txt": hp_txt, "med": med, "lado": u.lado,
		"tex_normal": spr.texture, "tex_ataque": Datos.sprite_ataque(u.imagen, u.espectral)}
	return n


func _texto(t: String, tam: int, color: Color) -> Label:
	var l := UI.etiqueta(t, tam, color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.clip_text = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _refrescar() -> void:
	for u in b.unidades:
		var t: Dictionary = tarjetas[u.uid]
		t["hp"].max_value = u.hp_max
		t["hp"].value = u.hp
		var txt: String = "Nv %d · %d / %d" % [u.nivel, u.hp, u.hp_max] if u.vivo() else "Fuera de combate"
		var est: String = u.texto_estados()
		if est != "" and u.vivo():
			txt += " · " + est
		t["hp_txt"].text = txt
		t["med"].value = u.medidor
		t["nodo"].modulate = Color(1, 1, 1) if u.vivo() else Color(1, 1, 1, 0.35)
	barra_banda.value = b.medidor_banda
	_dibujar_orden()
	if b.actual:
		lbl_turno.text = "Ronda %d · Turno de %s" % [b.ronda, b.actual.nombre]


func _dibujar_orden() -> void:
	if orden_box == null:
		return
	for c in orden_box.get_children():
		c.queue_free()
	var primero := true
	var separado := false
	for par in b.orden_proximo(8):
		var u = par[0]
		if par[1] and not separado:
			separado = true
			var sep := UI.etiqueta("|", 26, UI.TENUE)
			orden_box.add_child(sep)
		var marco := PanelContainer.new()
		var est := StyleBoxFlat.new()
		est.bg_color = Color(0, 0, 0, 0.6)
		est.border_color = UI.ORO if primero else (UI.ESPECTRAL if u.lado == Batalla.ALIADO else Color("#ff4a4a"))
		est.set_border_width_all(3 if primero else 2)
		est.set_corner_radius_all(8)
		marco.add_theme_stylebox_override("panel", est)
		var tam := 54 if primero else 42
		var img := UI.imagen(Datos.sprite(u.imagen, u.espectral), Vector2(tam, tam))
		img.flip_h = u.voltear()
		marco.add_child(img)
		UI.marcar_tipo(img, u.familia, 18 if primero else 15)
		marco.tooltip_text = u.nombre
		if par[1]:
			marco.modulate = Color(1, 1, 1, 0.6)
		orden_box.add_child(marco)
		primero = false


func _resaltar(validos: Array) -> void:
	var ids := validos.map(func(x): return x.uid)
	for u in b.unidades:
		var so: Sombra = tarjetas[u.uid]["sombra"]
		if u == b.actual:
			so.modo = 1
		elif u.uid in ids:
			so.modo = 2
		else:
			so.modo = 0
		so.queue_redraw()


# ---------------------------------------------------------------------
# Animaciones de los combatientes
# ---------------------------------------------------------------------

func _anim_accion(uid: String, id: String) -> void:
	var t: Dictionary = tarjetas.get(uid, {})
	if t.is_empty():
		return
	var spr: TextureRect = t["spr"]
	var tw := spr.create_tween()
	if float(b.hab(id).get("poder", 0)) > 0:
		# Embestida hacia el rival, con la imagen de ataque solo durante el golpe
		var dir := 1.0 if t["lado"] == Batalla.ALIADO else -1.0
		if t["tex_ataque"] != null:
			spr.texture = t["tex_ataque"]
		tw.tween_property(spr, "position:x", dir * 55.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.12)
		tw.tween_property(spr, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func(): spr.texture = t["tex_normal"])
	else:
		# Apoyo: pequeño salto con brillo
		tw.set_parallel(true)
		tw.tween_property(spr, "scale", Vector2(1.08, 1.08), 0.14)
		tw.tween_property(spr, "modulate", Color(1.4, 1.4, 1.7), 0.14)
		tw.chain().tween_property(spr, "scale", Vector2.ONE, 0.18)
		tw.parallel().tween_property(spr, "modulate", Color.WHITE, 0.18)


## Efecto visual de impacto según la clase de quien ataca.
func _efecto_golpe(uid: String, clase: String) -> void:
	var t: Dictionary = tarjetas.get(uid, {})
	if t.is_empty():
		return
	var nd: Control = t["nodo"]
	var fx := EfectoGolpe.new()
	fx.tipo = clase
	var s: float = nd.size.x
	fx.size = Vector2(s, s)
	fx.position = nd.global_position - global_position + Vector2(0, s * 0.05)
	add_child(fx)


func _anim_golpe(uid: String) -> void:
	var t: Dictionary = tarjetas.get(uid, {})
	if t.is_empty():
		return
	var spr: TextureRect = t["spr"]
	spr.modulate = Color(1.8, 0.45, 0.45)
	var tw := spr.create_tween()
	tw.tween_property(spr, "position:x", 9.0, 0.04)
	tw.tween_property(spr, "position:x", -9.0, 0.06)
	tw.tween_property(spr, "position:x", 0.0, 0.05)
	tw.parallel().tween_property(spr, "modulate", Color.WHITE, 0.25)


func _anim_brillo(uid: String, color: Color) -> void:
	var t: Dictionary = tarjetas.get(uid, {})
	if t.is_empty():
		return
	var spr: TextureRect = t["spr"]
	spr.modulate = color
	spr.create_tween().tween_property(spr, "modulate", Color.WHITE, 0.4)


func _anim_cae(uid: String, cae: bool) -> void:
	var t: Dictionary = tarjetas.get(uid, {})
	if t.is_empty():
		return
	var spr: TextureRect = t["spr"]
	var dir := -1.0 if t["lado"] == Batalla.ALIADO else 1.0
	spr.create_tween().tween_property(spr, "rotation_degrees", dir * 14.0 if cae else 0.0, 0.3)


func _mostrar_habilidades(u) -> void:
	for c in caja_habs.get_children():
		c.queue_free()
	if u == null or u.lado != Batalla.ALIADO:
		return
	for o in b.opciones(u):
		var h: Dictionary = o["h"]
		var txt: String = h.get("nombre", o["id"])
		if int(o["cd"]) > 0:
			txt += " (%d)" % int(o["cd"])
		if o.get("definitiva", false):
			txt = "DEF: " + txt
		if o.get("banda", false):
			txt = "BANDA"
		var bt := UI.boton(txt, _elegir_habilidad.bind(o["id"]), Vector2(0, 56))
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.add_theme_font_size_override("font_size", 17)
		bt.disabled = not bool(o["ok"])
		bt.clip_text = true
		caja_habs.add_child(bt)


# ---------------------------------------------------------------------
# Flujo de turnos
# ---------------------------------------------------------------------

func _siguiente() -> void:
	while true:
		if b.resultado() != "":
			_fin()
			return
		var ev := b.siguiente_turno()
		var saltar := false
		for e in ev:
			if e["t"] in ["aturdido", "salta"]:
				saltar = true
		await _mostrar(ev)
		if not is_inside_tree():
			return
		if b.resultado() != "":
			_fin()
			return
		if not saltar:
			break
	var u = b.actual
	seleccion = ""
	btn_usar.visible = false
	_refrescar()
	_resaltar([])
	if u.lado == Batalla.ALIADO and not auto:
		esperando_jugador = true
		lbl_info.text = "Turno de %s: elige una habilidad." % u.nombre
		_mostrar_habilidades(u)
	else:
		esperando_jugador = false
		_mostrar_habilidades(null)
		await get_tree().create_timer(0.45).timeout
		if not is_inside_tree():
			return
		var el := b.ia_elegir(u)
		await _accion(u, el["id"], el["obj"])


func _elegir_habilidad(id: String) -> void:
	if not esperando_jugador:
		return
	seleccion = id
	var h := b.hab(id)
	lbl_info.text = "%s: %s" % [h.get("nombre", id), h.get("desc", "")]
	if b.necesita_objetivo(id):
		btn_usar.visible = false
		lbl_info.text += "   → Toca el objetivo."
		_resaltar(b.objetivos_validos(b.actual, id))
	else:
		btn_usar.visible = true
		_resaltar(b.objetivos_validos(b.actual, id))


func _tocar_tarjeta(uid: String) -> void:
	if not esperando_jugador or seleccion == "" or not b.necesita_objetivo(seleccion):
		return
	var t = b.por_uid(uid)
	if not t in b.objetivos_validos(b.actual, seleccion):
		return
	_accion(b.actual, seleccion, t)


func _usar_sin_objetivo() -> void:
	if esperando_jugador and seleccion != "":
		_accion(b.actual, seleccion, null)


func _accion(u, id: String, obj) -> void:
	esperando_jugador = false
	btn_usar.visible = false
	_mostrar_habilidades(null)
	var ev := b.ejecutar(u, id, obj)
	await _mostrar(ev)
	if not is_inside_tree():
		return
	_siguiente()


func _mostrar(eventos: Array) -> void:
	for e in eventos:
		var uid: String = e.get("obj", "")
		var t: Dictionary = tarjetas.get(uid, {})
		var pos := Vector2.ZERO
		if not t.is_empty():
			var nd: Control = t["nodo"]
			pos = nd.global_position - global_position + Vector2(nd.size.x * 0.3, nd.size.y * 0.12)
		match e["t"]:
			"ronda":
				lbl_turno.text = "Ronda %d" % int(e["valor"])
			"accion":
				var u = b.por_uid(e["obj"])
				lbl_info.text = "%s usa %s" % [u.nombre, e["nombre"]]
				_anim_accion(uid, e.get("id", ""))
				ultimo_actor = u
				await get_tree().create_timer(0.3).timeout
			"dano":
				var txt := "-%d" % int(e["valor"])
				if String(e.get("nota", "")) != "":
					txt += "  " + String(e["nota"])
				UI.flotante(self, txt, Color("#ff5a5a"), pos)
				_anim_golpe(uid)
				if ultimo_actor != null and String(e.get("nota", "")) != "Quemadura":
					_efecto_golpe(uid, ultimo_actor.clase)
			"cura":
				UI.flotante(self, "+%d" % int(e["valor"]), Color("#5aff8a"), pos)
				_anim_brillo(uid, Color(0.6, 1.6, 0.7))
			"estado":
				UI.flotante(self, e["texto"], UI.ESPECTRAL, pos + Vector2(0, 30))
			"cae":
				UI.flotante(self, "¡Cae!", Color("#aaaaaa"), pos + Vector2(0, 30))
				_anim_cae(uid, true)
			"revive":
				UI.flotante(self, "¡Revive!", UI.ORO, pos)
				_anim_cae(uid, false)
				_anim_brillo(uid, Color(1.8, 1.6, 0.8))
			"aturdido":
				var u2 = b.por_uid(e["obj"])
				lbl_info.text = "%s está aturdido y pierde su turno." % u2.nombre
				UI.flotante(self, "Aturdido", UI.ESPECTRAL, pos)
				await get_tree().create_timer(0.5).timeout
		_refrescar()
		if e["t"] in ["dano", "cura", "estado", "revive"]:
			await get_tree().create_timer(0.18).timeout
		if not is_inside_tree():
			return


func _sacudir(c: Control) -> void:
	var tw := c.create_tween()
	var x := c.position.x
	tw.tween_property(c, "position:x", x + 8, 0.05)
	tw.tween_property(c, "position:x", x - 8, 0.05)
	tw.tween_property(c, "position:x", x, 0.05)


func _alternar_auto() -> void:
	auto = not auto
	btn_auto.text = "Auto: SÍ" if auto else "Auto: NO"
	if auto and esperando_jugador:
		esperando_jugador = false
		var el := b.ia_elegir(b.actual)
		_accion(b.actual, el["id"], el["obj"])


func _retirarse() -> void:
	if terminado:
		return
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa)
	v.add_child(UI.etiqueta("¿Retirarte del combate?", 28, UI.ORO))
	v.add_child(UI.etiqueta("Retirarse cuenta como derrota: tu equipo quedará Desafinado.", 22, UI.TEXTO, true))
	var h := HBoxContainer.new()
	h.add_child(UI.boton("Seguir peleando", func(): capa.queue_free(), Vector2(260, 64)))
	h.add_child(UI.boton("Retirarse", func():
		terminado = true
		Estado.aplicar_derrota()
		Estado.ir("mapa", {"zona": zona["id"]}), Vector2(220, 64)))
	v.add_child(h)


# ---------------------------------------------------------------------
# Fin del combate
# ---------------------------------------------------------------------

func _fin() -> void:
	if terminado:
		return
	terminado = true
	_mostrar_habilidades(null)
	if b.resultado() == "victoria":
		var primera_vez := not Estado.nodo_vencido(nodo["id"])
		var hp := {}
		for u in b.lado(Batalla.ALIADO, false):
			hp[u.uid] = float(u.hp) / u.hp_max
		var res := Estado.aplicar_victoria(nodo, int(info_enemigos["nivel"]), info_enemigos["ids"].size(), hp)
		var txt := "+%d XP para todo el equipo." % int(res["xp"])
		for s in res["subidas"]:
			txt += "\n" + s
		UI.aviso(self, "¡VICTORIA!", txt, func():
			var dlg: Array = nodo.get("dialogo_despues", []) if primera_vez else []
			UI.dialogo(self, dlg, _ofrecer_despertar))
	else:
		Estado.aplicar_derrota()
		UI.aviso(self, "Derrota", "Tu equipo quedó DESAFINADO por 5 minutos. Cada ejercicio extra registrado en Tareas reales resta 1 minuto.", func():
			Estado.ir("mapa", {"zona": zona["id"]}))


func _ofrecer_despertar() -> void:
	var id: String = info_enemigos.get("despertable", "")
	var p := Datos.personaje(id)
	if id == "" or p.is_empty():
		Estado.ir("mapa", {"zona": zona["id"]})
		return
	var rz := Datos.rareza(p["rareza"])
	if bool(rz["unico"]) and Estado.tiene_unico(id):
		Estado.ir("mapa", {"zona": zona["id"]})
		return
	_despertar(id, int(info_enemigos["nivel"]))


func _despertar(id: String, nivel: int) -> void:
	var p := Datos.personaje(id)
	var rz := Datos.rareza(p["rareza"])
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 820)
	v.add_child(UI.etiqueta("DESPERTAR ESPECTRAL", 34, UI.ESPECTRAL))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	var img := UI.imagen(Datos.sprite(p.get("imagen", id), false), Vector2(200, 200))
	h.add_child(img)
	UI.marcar_tipo(img, Datos.familia_de(id), 44)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	col.add_child(UI.etiqueta(p["nombre"], 26, Color(rz["color"])))
	col.add_child(UI.etiqueta("%s · %s · %s · Nv %d" % [rz["nombre"], Datos.clases[p["clase"]]["nombre"], Datos.nombre_familia(Datos.familia_de(id)), nivel], 18, UI.TENUE))
	var lbl_prob := UI.etiqueta("", 24, UI.ORO)
	col.add_child(lbl_prob)
	var lbl_res := UI.etiqueta("Tienes 3 intentos. Si fallas los 3, se desvanece y reaparece en %d horas reales." % int(rz["espera_h"]), 19, UI.TEXTO, true)
	col.add_child(lbl_res)
	var chk := CheckBox.new()
	chk.text = "Usar Púa Espectral (+15%%) — tienes %d" % int(Estado.d["pua"])
	chk.disabled = int(Estado.d["pua"]) <= 0
	col.add_child(chk)
	var estado := {"fallos": 0, "intentos": 3, "pua": false, "fin": false}
	var actualizar := func():
		var con_pua: bool = estado["pua"] or chk.button_pressed
		lbl_prob.text = "Probabilidad: %d%%   ·   Intentos: %d" % [Estado.prob_despertar(nivel, estado["fallos"], con_pua), estado["intentos"]]
	actualizar.call()
	chk.toggled.connect(func(_x): actualizar.call())
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 14)
	v.add_child(botones)
	var b_soltar := UI.boton("Dejarlo ir", func(): Estado.ir("mapa", {"zona": zona["id"]}), Vector2(220, 64))
	var b_desp := UI.boton("¡DESPERTAR!", func(): pass, Vector2(300, 64))
	botones.add_child(b_soltar)
	botones.add_child(b_desp)
	b_desp.pressed.connect(func():
		if estado["fin"]:
			Estado.ir("mapa", {"zona": zona["id"]})
			return
		if chk.button_pressed and not estado["pua"]:
			if Estado.usar_pua():
				estado["pua"] = true
			chk.disabled = true
		var prob := Estado.prob_despertar(nivel, estado["fallos"], estado["pua"])
		if randi() % 100 < prob:
			Estado.despertar_exito(nodo["id"], id, nivel)
			img.texture = Datos.sprite(p.get("imagen", id), true)
			var tw := img.create_tween()
			img.modulate = Color(2, 2, 2)
			tw.tween_property(img, "modulate", Color(1, 1, 1), 0.8)
			lbl_res.text = "¡%s despertó y se une a tu legión espectral!" % p["nombre"]
			lbl_res.add_theme_color_override("font_color", UI.ESPECTRAL)
			lbl_prob.text = ""
			estado["fin"] = true
			b_desp.text = "Continuar"
			b_soltar.visible = false
			chk.visible = false
		else:
			estado["fallos"] += 1
			estado["intentos"] -= 1
			_sacudir(img)
			if estado["intentos"] <= 0:
				var horas := Estado.despertar_fallido(nodo["id"], id)
				lbl_res.text = "%s se desvaneció... Reaparecerá en esta zona en %d horas reales." % [p["nombre"], horas]
				lbl_res.add_theme_color_override("font_color", Color("#ff9a9a"))
				lbl_prob.text = ""
				estado["fin"] = true
				b_desp.text = "Continuar"
				b_soltar.visible = false
				chk.visible = false
			else:
				lbl_res.text = "Falló... pero el eco se fortalece (+10% al siguiente intento)."
				actualizar.call())
