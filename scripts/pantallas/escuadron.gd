extends "res://scripts/pantallas/pantalla.gd"
## Escuadrón: elige qué seguidores combaten junto al protagonista.

var cuerpo: VBoxContainer


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando"), 0.7)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(UI.encabezado("Escuadrón", volver_centro))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	cuerpo = VBoxContainer.new()
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 8)
	sc.add_child(cuerpo)
	_refrescar()


func _refrescar() -> void:
	for c in cuerpo.get_children():
		c.queue_free()
	var tam := int(Estado.d["tam_equipo"])
	var txt := "Integrantes: %d de %d (el protagonista siempre combate)." % [1 + Estado.d["equipo"].size(), tam]
	if tam == 1:
		txt += "\nDespierta a tu primer seguidor para tener un compañero."
	elif tam == 2:
		txt += "\nVence a la líder Aruma para ampliar el equipo a 3."
	cuerpo.add_child(UI.etiqueta(txt, 20, UI.ORO, true))
	if Estado.d["seguidores"].is_empty():
		cuerpo.add_child(UI.etiqueta("Aún no tienes seguidores espectrales. Vence enemigos y despiértalos.", 20, UI.TENUE, true))
		return
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	cuerpo.add_child(g)
	for s in Estado.d["seguidores"]:
		var p := Datos.personaje(s["base_id"])
		var en_equipo: bool = s["uid"] in Estado.d["equipo"]
		var b := Button.new()
		b.custom_minimum_size = Vector2(600, 110)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_pressed = en_equipo
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 8
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var img := UI.imagen(Datos.sprite(p.get("imagen", s["base_id"]), true), Vector2(96, 96))
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(img)
		var rz := Datos.rareza(p["rareza"])
		var l := UI.etiqueta("%s%s\n%s · %s · %s · Nv %d · Vida %d%%" % ["[EN EQUIPO] " if en_equipo else "", p["nombre"], rz["nombre"],
			Datos.clases[p["clase"]]["nombre"], Datos.nombre_familia(Datos.familia_de(s["base_id"])), int(s["nivel"]), int(float(s.get("hp_frac", 1.0)) * 100)], 18, Color(rz["color"]))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(l)
		b.pressed.connect(func():
			var err := Estado.alternar_en_equipo(s["uid"])
			if err != "":
				UI.aviso(self, "Equipo completo", err)
			_refrescar())
		g.add_child(b)
