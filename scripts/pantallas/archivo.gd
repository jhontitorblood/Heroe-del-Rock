extends "res://scripts/pantallas/pantalla.gd"
## Archivo: colección de la legión espectral y bestiario de enemigos encontrados.


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando"), 0.7)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(UI.encabezado("Archivo · Legión espectral (%d)" % Estado.d["seguidores"].size(), volver_centro))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var cuerpo := VBoxContainer.new()
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(cuerpo)
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	cuerpo.add_child(g)
	if Estado.d["seguidores"].is_empty():
		cuerpo.add_child(UI.etiqueta("Tu legión está vacía. Vence enemigos y despiértalos.", 20, UI.TENUE))
	for s in Estado.d["seguidores"]:
		g.add_child(_ficha(s["base_id"], true, int(s["nivel"])))
	cuerpo.add_child(UI.etiqueta("Bestiario · enemigos encontrados", 26, UI.ORO))
	var g2 := GridContainer.new()
	g2.columns = 6
	g2.add_theme_constant_override("h_separation", 10)
	g2.add_theme_constant_override("v_separation", 10)
	cuerpo.add_child(g2)
	for id in Estado.d["encontrados"]:
		g2.add_child(_ficha(id, false, 0))


func _ficha(base_id: String, espectral: bool, nivel: int) -> Button:
	var p := Datos.personaje(base_id)
	var rz := Datos.rareza(p.get("rareza", "comun"))
	var b := Button.new()
	b.custom_minimum_size = Vector2(196, 230)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var img := UI.imagen(Datos.sprite(p.get("imagen", base_id), espectral), Vector2(150, 150))
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.marcar_tipo(img, Datos.familia_de(base_id), 34)
	v.add_child(img)
	var l := UI.etiqueta(p.get("nombre", base_id), 15, Color(rz["color"]), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.pressed.connect(func():
		var cl: Dictionary = Datos.clases[p["clase"]]
		var txt := "%s · %s\nInstrumento: %s (%s)\nBanda: %s · Estilo: %s" % [rz["nombre"], cl["nombre"], Datos.instrumento_de(base_id), Datos.nombre_familia(Datos.familia_de(base_id)), p.get("banda", "—"), Datos.nombre_genero(p["genero"])]
		if nivel > 0:
			txt += "\nNivel %d" % nivel
		txt += "\n\n" + p.get("bio", "Seguidor sin historia propia (rareza %s)." % rz["nombre"].to_lower())
		UI.aviso(self, p["nombre"], txt))
	return b
