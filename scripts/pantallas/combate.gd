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
	_construir()
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
	lbl_turno = UI.etiqueta("", 24, UI.ORO)
	lbl_turno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl_turno)
	btn_auto = UI.boton("Auto: NO", _alternar_auto, Vector2(150, 50))
	top.add_child(btn_auto)
	top.add_child(UI.boton("Retirarse", _retirarse, Vector2(150, 50)))

	var campo := HBoxContainer.new()
	campo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(campo)
	var izq := VBoxContainer.new()
	izq.alignment = BoxContainer.ALIGNMENT_CENTER
	izq.add_theme_constant_override("separation", 8)
	campo.add_child(izq)
	var medio := Control.new()
	medio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo.add_child(medio)
	var der := VBoxContainer.new()
	der.alignment = BoxContainer.ALIGNMENT_CENTER
	der.add_theme_constant_override("separation", 8)
	campo.add_child(der)
	var n_unidades: int = max(b.lado(Batalla.ALIADO, false).size(), b.lado(Batalla.ENEMIGO, false).size())
	var alto := 112 if n_unidades <= 3 else 92
	for u in b.unidades:
		var t := _tarjeta(u, alto)
		(izq if u.lado == Batalla.ALIADO else der).add_child(t)

	var abajo := UI.panel()
	v.add_child(abajo)
	var av := VBoxContainer.new()
	abajo.add_child(av)
	var fila_info := HBoxContainer.new()
	av.add_child(fila_info)
	lbl_info = UI.etiqueta("", 20, UI.TEXTO, true)
	lbl_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_info.custom_minimum_size = Vector2(0, 52)
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


func _tarjeta(u, alto: int) -> Button:
	var bt := Button.new()
	bt.custom_minimum_size = Vector2(430, alto)
	bt.pressed.connect(_tocar_tarjeta.bind(u.uid))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	bt.add_child(h)
	var img := UI.imagen(Datos.sprite(u.imagen, u.espectral), Vector2(alto - 12, alto - 12))
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if u.lado == Batalla.ENEMIGO:
		img.flip_h = true
	h.add_child(img)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	var rz := Datos.rareza(u.rareza)
	var nom := UI.etiqueta(u.nombre, 18, Color(rz["color"]) if u.lado == Batalla.ENEMIGO else (UI.ESPECTRAL if u.espectral else UI.ORO))
	nom.clip_text = true
	col.add_child(nom)
	col.add_child(UI.etiqueta("Nv %d · %s · %s" % [u.nivel, Datos.clases[u.clase]["nombre"], Datos.nombre_genero(u.genero)], 14, Datos.color_genero(u.genero)))
	var hp := UI.barra(u.hp, u.hp_max, Color("#3ae889") if u.lado == Batalla.ALIADO else Color("#ff4a4a"), 14)
	col.add_child(hp)
	var hp_txt := UI.etiqueta("", 14, UI.TEXTO)
	hp_txt.clip_text = true
	col.add_child(hp_txt)
	var med := UI.barra(u.medidor, 100, Color("#ffd23a"), 6)
	col.add_child(med)
	for c in col.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjetas[u.uid] = {"boton": bt, "hp": hp, "hp_txt": hp_txt, "med": med}
	return bt


func _refrescar() -> void:
	for u in b.unidades:
		var t: Dictionary = tarjetas[u.uid]
		t["hp"].max_value = u.hp_max
		t["hp"].value = u.hp
		var txt: String = "%d / %d" % [u.hp, u.hp_max] if u.vivo() else "Fuera de combate"
		var est: String = u.texto_estados()
		if est != "" and u.vivo():
			txt += "   " + est
		t["hp_txt"].text = txt
		t["med"].value = u.medidor
		t["boton"].modulate = Color(1, 1, 1) if u.vivo() else Color(0.4, 0.4, 0.4)
	barra_banda.value = b.medidor_banda
	if b.actual:
		lbl_turno.text = "Ronda %d · Turno de %s" % [b.ronda, b.actual.nombre]


func _resaltar(validos: Array) -> void:
	var ids := validos.map(func(x): return x.uid)
	for u in b.unidades:
		var bt: Button = tarjetas[u.uid]["boton"]
		if u == b.actual:
			bt.modulate = Color(1.25, 1.2, 0.8)
		elif u.uid in ids:
			bt.modulate = Color(1.3, 1.3, 1.3)
		elif u.vivo():
			bt.modulate = Color(0.8, 0.8, 0.8) if not ids.is_empty() else Color(1, 1, 1)


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
		var bt := UI.boton(txt, _elegir_habilidad.bind(o["id"]), Vector2(0, 64))
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
		var t: Dictionary = tarjetas.get(e.get("obj", ""), {})
		var pos := Vector2.ZERO
		if not t.is_empty():
			var bt: Button = t["boton"]
			pos = bt.global_position - global_position + Vector2(bt.size.x * 0.45, 4)
		match e["t"]:
			"ronda":
				lbl_turno.text = "Ronda %d" % int(e["valor"])
			"accion":
				var u = b.por_uid(e["obj"])
				lbl_info.text = "%s usa %s" % [u.nombre, e["nombre"]]
				await get_tree().create_timer(0.25).timeout
			"dano":
				var txt := "-%d" % int(e["valor"])
				if String(e.get("nota", "")) != "":
					txt += "  " + String(e["nota"])
				UI.flotante(self, txt, Color("#ff5a5a"), pos)
				_sacudir(t["boton"])
			"cura":
				UI.flotante(self, "+%d" % int(e["valor"]), Color("#5aff8a"), pos)
			"estado":
				UI.flotante(self, e["texto"], UI.ESPECTRAL, pos + Vector2(0, 30))
			"cae":
				UI.flotante(self, "¡Cae!", Color("#aaaaaa"), pos + Vector2(0, 30))
			"revive":
				UI.flotante(self, "¡Revive!", UI.ORO, pos)
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
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	col.add_child(UI.etiqueta(p["nombre"], 26, Color(rz["color"])))
	col.add_child(UI.etiqueta("%s · %s · %s · Nv %d" % [rz["nombre"], Datos.clases[p["clase"]]["nombre"], Datos.nombre_genero(p["genero"]), nivel], 18, UI.TENUE))
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
