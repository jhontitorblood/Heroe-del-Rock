extends "res://scripts/pantallas/pantalla.gd"
## Equipo: estadísticas y las 4 habilidades equipadas de cada combatiente.

var detalle: VBoxContainer


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando"), 0.7)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(UI.encabezado("Equipo", volver_centro))
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
	fila.add_child(UI.imagen(tex, Vector2(220, 220)))
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
