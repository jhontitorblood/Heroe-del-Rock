extends "res://scripts/pantallas/pantalla.gd"
## Equipo: estadísticas y las 4 habilidades equipadas de cada combatiente.

var detalle: VBoxContainer


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando"), 0.7)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	var cab := UI.encabezado("Equipo", volver_centro)
	cab.add_child(UI.boton("Ventajas por tipo", _ver_ciclo, Vector2(260, 56)))
	v.add_child(cab)
	# Lista de personajes (desliza a los lados)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 76)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var lista := HBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	sc.add_child(lista)
	lista.add_child(UI.boton(Estado.nombre_jugador(), _mostrar.bind("prota"), Vector2(0, 64)))
	for s in Estado.d["seguidores"]:
		lista.add_child(UI.boton(Datos.personaje(s["base_id"])["nombre"], _mostrar.bind(s["uid"]), Vector2(0, 64)))
	var sc2 := ScrollContainer.new()
	sc2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc2)
	detalle = VBoxContainer.new()
	detalle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(detalle)
	_mostrar("prota")


func _mostrar(uid: String) -> void:
	for c in detalle.get_children():
		c.queue_free()
	var base_id: String
	var nivel: int
	var nombre: String
	var espectral := false
	var bonus := {}
	if uid == "prota":
		base_id = Estado.d["protagonista"]["base_id"]
		nivel = int(Estado.d["nivel"])
		nombre = Estado.nombre_jugador()
		bonus = Estado.d["bonus"]
	else:
		var s := Estado.seguidor(uid)
		base_id = s["base_id"]
		nivel = int(s["nivel"])
		nombre = Datos.personaje(base_id)["nombre"]
		espectral = true
	var p := Datos.personaje(base_id)
	var st := Datos.stats(base_id, nivel)
	var tex := Estado.textura_protagonista() if uid == "prota" else Datos.sprite(p.get("imagen", base_id), espectral)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	detalle.add_child(fila)
	var img_det := UI.imagen(tex, Vector2(220, 220))
	UI.marcar_tipo(img_det, Datos.familia_de(base_id), 48)
	fila.add_child(img_det)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(col)
	col.add_child(UI.etiqueta(nombre, 30, UI.ESPECTRAL if espectral else UI.ORO))
	var cl: Dictionary = Datos.clases[p["clase"]]
	var fam := Datos.familia_de(base_id)
	col.add_child(UI.etiqueta("%s (%s) · Nivel %d" % [cl["nombre"], cl["funcion"], nivel], 20, UI.ORO, true))
	col.add_child(UI.etiqueta("Instrumento: %s · Tipo: %s" % [Datos.instrumento_de(base_id), Datos.nombre_familia(fam)], 19, Datos.color_familia(fam), true))
	col.add_child(UI.etiqueta("Rareza: %s · Estilo de su banda: %s" % [Datos.rareza(p.get("rareza", "comun"))["nombre"], Datos.nombre_genero(p["genero"])], 18, UI.TENUE, true))
	var txt := "Vida %d · Ataque %.0f · Defensa %.0f · Velocidad %.0f" % [st["hp"] + float(bonus.get("hp", 0)), st["atk"] + float(bonus.get("atk", 0)), st["def"] + float(bonus.get("def", 0)), st["spd"]]
	col.add_child(UI.etiqueta(txt, 20, UI.TEXTO, true))
	if uid == "prota":
		col.add_child(UI.etiqueta("Bonus de tareas reales: +%.0f vida · +%.1f ataque · +%.1f defensa · Maestría %d (+%.1f%% poder)" % [
			float(bonus["hp"]), float(bonus["atk"]), float(bonus["def"]), int(bonus["maestria"]), int(bonus["maestria"]) * 0.5], 18, UI.ESPECTRAL, true))
	if p.has("bio"):
		col.add_child(UI.etiqueta(p["bio"], 18, UI.TENUE, true))
	detalle.add_child(UI.etiqueta("Habilidades equipadas", 24, UI.ORO))
	var habs: Array = Datos.habilidades_de(base_id).duplicate()
	habs.append(Datos.definitiva_de(base_id))
	for id in habs:
		var hb: Dictionary = Datos.habilidades.get(id, {})
		var cd := int(hb.get("enfriamiento", 0))
		var extra := "  (espera %d turnos)" % cd if cd > 0 else ""
		detalle.add_child(UI.etiqueta("• %s%s — %s" % [hb.get("nombre", id), extra, hb.get("desc", "")], 19, UI.TEXTO, true))


## Muestra el ciclo de ventajas con los íconos de tipo de instrumento.
func _ver_ciclo() -> void:
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 1100)
	v.add_child(UI.etiqueta("Ventajas por tipo de instrumento", 30, UI.ORO))
	v.add_child(UI.etiqueta("Cada tipo hace +25% de daño al siguiente y recibe +25% del anterior.", 19, UI.TEXTO, true))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 6)
	v.add_child(fila)
	var orden: Array = Datos.familias["orden"]
	for i in orden.size() + 1:
		var f: String = orden[i % orden.size()]
		var col := VBoxContainer.new()
		col.add_child(UI.icono_tipo(f, 84))
		var l := UI.etiqueta(Datos.nombre_familia(f), 15, Datos.color_familia(f))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(110, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
		fila.add_child(col)
		if i < orden.size():
			var flecha := UI.etiqueta(">", 40, UI.ORO)
			flecha.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			flecha.custom_minimum_size = Vector2(0, 84)
			flecha.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fila.add_child(flecha)
	for f in orden:
		var r: String = Datos.familias["razones"].get(f, "")
		v.add_child(UI.etiqueta("%s le gana a %s: %s." % [Datos.nombre_familia(f), Datos.nombre_familia(orden[(orden.find(f) + 1) % orden.size()]), r.to_lower()], 17, UI.TENUE, true))
	v.add_child(UI.boton("Cerrar", func(): capa.queue_free(), Vector2(0, 56)))
