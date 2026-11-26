extends "res://scripts/pantallas/pantalla.gd"
## Tareas reales: el motor del progreso.

var lista: VBoxContainer
var resumen: Label
var nombre_nueva: LineEdit
var cat_nueva: OptionButton
var cats: Array = []


func es_vertical() -> bool:
	return true


func _ready() -> void:
	Estado.revisar_dia()
	UI.fondo(self, Datos.textura("escenarios", "esc_centro_mando_vertical"), 0.7)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(UI.encabezado("Tareas reales", volver_centro))
	resumen = UI.etiqueta("", 19, UI.TEXTO, true)
	var p := UI.panel()
	p.add_child(resumen)
	v.add_child(p)
	var b_extra := UI.boton("+ Ejercicio extra (−1 min de Desafinados)", _extra, Vector2(0, 56))
	v.add_child(b_extra)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	sc.add_child(lista)
	# Nueva tarea (dos filas para caber en vertical)
	nombre_nueva = LineEdit.new()
	nombre_nueva.placeholder_text = "Nueva tarea (ej.: 30 sentadillas)"
	nombre_nueva.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre_nueva.custom_minimum_size = Vector2(0, 56)
	nombre_nueva.max_length = 50
	v.add_child(nombre_nueva)
	var nueva := HBoxContainer.new()
	nueva.add_theme_constant_override("separation", 10)
	cat_nueva = OptionButton.new()
	cat_nueva.custom_minimum_size = Vector2(260, 56)
	cat_nueva.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in Datos.tareas["categorias"]:
		cats.append(c)
		cat_nueva.add_item(Datos.tareas["categorias"][c]["nombre"])
	nueva.add_child(cat_nueva)
	nueva.add_child(UI.boton("Agregar", _agregar, Vector2(160, 56)))
	v.add_child(nueva)
	_refrescar()


func _refrescar() -> void:
	var d := Estado.d
	var rt: Dictionary = Datos.reglas["tareas"]
	var hechas: int = d["hoy"]["hechas"].size()
	var cats_hoy := Estado.categorias_hechas_hoy().size()
	var tot: Dictionary = d["totales"]
	var txt := "Hoy: %d tareas · Cadena corta%s (%d/%d → +%d energía) · Cadena completa%s (%d/%d categorías → +%d energía y 1 Púa)\n" % [
		hechas, " LISTA" if bool(d["hoy"]["cadena_corta"]) else "", min(hechas, int(rt["cadena_corta"])), int(rt["cadena_corta"]), int(rt["energia_cadena_corta"]),
		" LISTA" if bool(d["hoy"]["cadena_completa"]) else "", cats_hoy, Datos.tareas["categorias"].size(), int(rt["energia_cadena_completa"])]
	txt += "XP por tareas hoy: %d/%d · Energía %d · Púas %d · Racha %d días\n" % [int(d["hoy"]["xp"]), int(rt["xp_tope_diario"]), int(d["energia"]), int(d["pua"]), int(d["racha"])]
	txt += "Acumulados: ejercicio %d · práctica %d · casa %d · trabajo/estudio %d" % [int(tot["ejercicio"]), int(tot["practica"]), int(tot["casa"]), int(tot["trabajo"])]
	if Estado.esta_desafinado():
		txt += "\nDesafinados: %s restantes." % Estado.formato_tiempo(Estado.segundos_desafinado())
	resumen.text = txt
	for c in lista.get_children():
		c.queue_free()
	for cat in Datos.tareas["categorias"]:
		var ci: Dictionary = Datos.tareas["categorias"][cat]
		lista.add_child(UI.etiqueta("%s  —  %s" % [ci["nombre"], ci["efecto"]], 20, UI.ORO, true))
		for t in d["tareas"]:
			if t["categoria"] != cat:
				continue
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			var hecha := Estado.tarea_hecha_hoy(t["id"])
			var l := UI.etiqueta(("[Hecha] " if hecha else "") + t["nombre"], 20, UI.TENUE if hecha else UI.TEXTO, true)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			var b := UI.boton("¡Hecho!", _registrar.bind(t["id"]), Vector2(150, 52))
			b.disabled = hecha
			h.add_child(b)
			h.add_child(UI.boton("Quitar", _borrar.bind(t["id"]), Vector2(110, 52)))
			lista.add_child(h)


func _registrar(id: String) -> void:
	var msgs := Estado.registrar_tarea(id)
	_refrescar()
	if not msgs.is_empty():
		UI.aviso(self, "¡Tarea completada!", "\n".join(msgs))


func _extra() -> void:
	var msg := Estado.registrar_ejercicio_extra()
	_refrescar()
	UI.aviso(self, "Ejercicio extra", msg)


func _borrar(id: String) -> void:
	Estado.borrar_tarea(id)
	_refrescar()


func _agregar() -> void:
	var n := nombre_nueva.text.strip_edges()
	if n == "":
		return
	Estado.agregar_tarea(n, cats[cat_nueva.selected])
	nombre_nueva.text = ""
	_refrescar()
