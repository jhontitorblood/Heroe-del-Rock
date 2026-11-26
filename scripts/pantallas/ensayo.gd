extends "res://scripts/pantallas/pantalla.gd"
## Sala de Ensayo: recuperación fuera de combate y química del equipo.

var cuerpo: VBoxContainer


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_sala_ensayo"), 0.55)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	v.add_child(UI.encabezado("Sala de Ensayo", volver_centro))
	cuerpo = VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 12)
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cuerpo)
	_refrescar()


func _refrescar() -> void:
	for c in cuerpo.get_children():
		c.queue_free()
	var r: Dictionary = Datos.reglas["ensayo"]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	cuerpo.add_child(h)
	var rapido_espera := Estado.segundos_ensayo_rapido()
	_tarjeta(h, "Ensayo rápido", "Gratis, uno cada 30 minutos.\nRecupera %d%% de vida · +%d química." % [int(r["rapido"]["cura"] * 100), int(r["rapido"]["quimica"])],
		"Listo en " + Estado.formato_tiempo(rapido_espera) if rapido_espera > 0 else "Ensayar", rapido_espera > 0, "rapido")
	_tarjeta(h, "Ensayo completo", "Cuesta %d de energía.\nRecupera %d%% de vida · +%d química." % [int(r["completo"]["costo_energia"]), int(r["completo"]["cura"] * 100), int(r["completo"]["quimica"])],
		"Ensayar", int(Estado.d["energia"]) < int(r["completo"]["costo_energia"]), "completo")
	var practicas := int(Estado.d["hoy"]["practicas"])
	_tarjeta(h, "Ensayo real", "Usa una práctica real de instrumento registrada hoy (%d disponibles).\nRecupera toda la vida · +%d química · En sintonía (+5%% daño)." % [practicas, int(r["real"]["quimica"])],
		"Ensayar", practicas <= 0, "real")
	# Estado del equipo
	var p := UI.panel()
	cuerpo.add_child(p)
	var pv := VBoxContainer.new()
	p.add_child(pv)
	pv.add_child(UI.etiqueta("Tu equipo", 24, UI.ORO))
	var miembros := Estado.miembros_equipo()
	for mi in miembros:
		var fila := HBoxContainer.new()
		var l := UI.etiqueta(mi["nombre"], 20)
		l.custom_minimum_size = Vector2(320, 0)
		fila.add_child(l)
		var bar := UI.barra(float(mi["hp_frac"]) * 100, 100, Color("#3ae889"), 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(bar)
		fila.add_child(UI.etiqueta("  %d%%" % int(float(mi["hp_frac"]) * 100), 20))
		pv.add_child(fila)
	if miembros.size() > 1:
		var q := []
		for i in miembros.size():
			for j in range(i + 1, miembros.size()):
				q.append("%s + %s: %d" % [miembros[i]["nombre"], miembros[j]["nombre"], Estado.quimica(miembros[i]["uid"], miembros[j]["uid"])])
		pv.add_child(UI.etiqueta("Química (hasta +15% de sinergia): " + " · ".join(q), 18, UI.ESPECTRAL, true))
	else:
		pv.add_child(UI.etiqueta("La química aparece cuando tienes compañeros en el equipo.", 18, UI.TENUE, true))


func _tarjeta(padre: Control, titulo: String, desc: String, texto_boton: String, deshabilitado: bool, tipo: String) -> void:
	var p := UI.panel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UI.etiqueta(titulo, 24, UI.ORO))
	var l := UI.etiqueta(desc, 18, UI.TEXTO, true)
	l.custom_minimum_size = Vector2(0, 110)
	v.add_child(l)
	var b := UI.boton(texto_boton, func():
		var msg := Estado.ensayo(tipo)
		_refrescar()
		UI.aviso(self, titulo, msg), Vector2(0, 60))
	b.disabled = deshabilitado
	v.add_child(b)
