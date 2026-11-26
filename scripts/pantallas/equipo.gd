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
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(360, 0)
	h.add_child(sc)
	var lista := VBoxContainer.new()
	sc.add_child(lista)
	var pid: String = Estado.d["protagonista"]["base_id"]
	lista.add_child(UI.boton(Estado.nombre_jugador() + " (protagonista)", _mostrar.bind("prota"), Vector2(340, 56)))
	for s in Estado.d["seguidores"]:
		lista.add_child(UI.boton(Datos.personaje(s["base_id"])["nombre"], _mostrar.bind(s["uid"]), Vector2(340, 56)))
	var sc2 := ScrollContainer.new()
	sc2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h.add_child(sc2)
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
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	detalle.add_child(h)
	h.add_child(UI.imagen(Datos.sprite(p.get("imagen", base_id), espectral), Vector2(200, 200)))
	var col := VBoxContainer.new()
	h.add_child(col)
	col.add_child(UI.etiqueta(nombre, 30, UI.ESPECTRAL if espectral else UI.ORO))
	var cl: Dictionary = Datos.clases[p["clase"]]
	col.add_child(UI.etiqueta("%s (%s) · %s · Nivel %d" % [cl["nombre"], cl["funcion"], Datos.nombre_genero(p["genero"]), nivel], 20, Datos.color_genero(p["genero"])))
	var txt := "Vida %d   Ataque %.0f   Defensa %.0f   Velocidad %.0f" % [st["hp"] + float(bonus.get("hp", 0)), st["atk"] + float(bonus.get("atk", 0)), st["def"] + float(bonus.get("def", 0)), st["spd"]]
	col.add_child(UI.etiqueta(txt, 20))
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
