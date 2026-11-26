extends "res://scripts/pantallas/pantalla.gd"
## Mapa de una zona: combates, sublíderes, líder, jefe y secretos.

const BASE := Vector2(1280, 720)

var zona: Dictionary
var botones := {}


class Lineas extends Control:
	var segmentos: Array = []  # [[Vector2 a, Vector2 b, Color]]

	func _draw() -> void:
		for s in segmentos:
			draw_line(s[0] * size / Vector2(1280, 720), s[1] * size / Vector2(1280, 720), s[2], 5.0, true)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()


func _ready() -> void:
	zona = Datos.zona(params.get("zona", "cotoca"))
	UI.fondo(self, Datos.textura("mapas", zona.get("mapa", "")), 0.2)
	var lineas := Lineas.new()
	lineas.set_anchors_preset(Control.PRESET_FULL_RECT)
	lineas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lineas)
	var pos := {}
	for n in zona["nodos"]:
		pos[n["id"]] = Vector2(n["pos"][0], n["pos"][1])
	for n in zona["nodos"]:
		var req: Dictionary = n.get("requiere", {})
		if req.has("nodo") and pos.has(req["nodo"]):
			var col := Color("#ffd23a") if Estado.nodo_vencido(req["nodo"]) else Color("#ffffff40")
			lineas.segmentos.append([pos[req["nodo"]], pos[n["id"]], col])
	for n in zona["nodos"]:
		_crear_boton(n)

	var m := UI.margen(self, 20)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	v.add_child(UI.encabezado("Mapa · %s (%s)" % [zona["nombre"], zona["banda"]], volver_centro))
	var info := UI.panel()
	info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(info)
	var restantes := Estado.enemigos_restantes_antes_del_jefe(zona)
	var txt := "Enemigos por vencer antes del jefe: %d" % restantes
	if Estado.nodo_vencido(zona["jefe_nodo"]):
		txt = "¡Zona liberada! Puedes volver a combatir para entrenar y despertar seguidores."
	info.add_child(UI.etiqueta("%s\nEnergía: %d   ·   Púas: %d" % [txt, int(Estado.d["energia"]), int(Estado.d["pua"])], 20))


func _crear_boton(n: Dictionary) -> void:
	var b := Button.new()
	var en := Estado.estado_nodo(n["id"])
	var bloqueo := Estado.bloqueo_nodo(n)
	var secreto: bool = n["tipo"] == "secreto"
	if secreto and bloqueo != "":
		b.text = "???\nZona secreta"
	else:
		var marca := "[Vencido] " if bool(en["vencido"]) else ""
		b.text = "%s%s\nNv %d" % [marca, n["nombre"], int(n["nivel"])]
	var colores := {"normal": Color("#2a1838"), "sublider": Color("#3b1f5c"), "lider": Color("#5c1f3b"), "jefe": Color("#7a1020"), "secreto": Color("#0f3b40")}
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = colores.get(n["tipo"], Color("#2a1838"))
	estilo.border_color = Color("#ffd23a") if bool(en["vencido"]) else (Color("#555") if bloqueo != "" else Color("#ff3a5e"))
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	b.add_theme_stylebox_override("normal", estilo)
	b.add_theme_font_size_override("font_size", 18)
	if bloqueo != "":
		b.modulate = Color(0.75, 0.75, 0.75)
	if Estado.segundos_reaparece(n["id"]) > 0:
		b.text += "\nReaparece en " + Estado.formato_tiempo(Estado.segundos_reaparece(n["id"]))
	var ancho := 210.0
	var alto := 86.0
	b.anchor_left = float(n["pos"][0]) / BASE.x
	b.anchor_top = float(n["pos"][1]) / BASE.y
	b.anchor_right = b.anchor_left
	b.anchor_bottom = b.anchor_top
	b.offset_left = -ancho / 2
	b.offset_right = ancho / 2
	b.offset_top = -alto / 2
	b.offset_bottom = alto / 2
	b.pressed.connect(_abrir.bind(n))
	add_child(b)
	botones[n["id"]] = b


func _abrir(n: Dictionary) -> void:
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 860)
	var bloqueo := Estado.bloqueo_nodo(n)
	var tipos := {"normal": "Combate", "sublider": "Sublíder", "lider": "Líder de banda", "jefe": "Jefe territorial", "secreto": "Zona secreta"}
	v.add_child(UI.etiqueta("%s · %s · Nivel %d" % [n["nombre"] if (n["tipo"] != "secreto" or bloqueo == "") else "???", tipos[n["tipo"]], int(n["nivel"])], 28, UI.ORO))
	if bloqueo != "":
		v.add_child(UI.etiqueta(bloqueo, 22, Color("#ff9a9a"), true))
	else:
		var info := Estado.enemigos_de_nodo(zona, n)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		for id in info["ids"]:
			var p := Datos.personaje(id)
			var c := VBoxContainer.new()
			c.add_child(UI.imagen(Datos.sprite(p.get("imagen", id), false), Vector2(120, 120)))
			var rz := Datos.rareza(p.get("rareza", "comun"))
			c.add_child(UI.etiqueta(p.get("nombre", id), 16, Color(rz["color"])))
			c.add_child(UI.etiqueta("%s · %s" % [Datos.clases[p["clase"]]["nombre"], Datos.nombre_genero(p["genero"])], 14, UI.TENUE))
			h.add_child(c)
		v.add_child(h)
		if bool(info["aleatorio"]):
			v.add_child(UI.etiqueta("Su enemigo principal ya está en tu legión: ahora aparecen músicos aleatorios de la zona.", 18, UI.TENUE, true))
		elif info["despertable"] != "":
			var pd := Datos.personaje(info["despertable"])
			v.add_child(UI.etiqueta("Despertable: %s (%s)" % [pd["nombre"], Datos.rareza(pd["rareza"])["nombre"]], 20, UI.ESPECTRAL))
		v.add_child(UI.etiqueta("Costo: %d de energía (tienes %d)" % [Estado.costo_nodo(n), int(Estado.d["energia"])], 20))
	var h2 := HBoxContainer.new()
	h2.add_theme_constant_override("separation", 14)
	h2.add_child(UI.boton("Cerrar", func(): capa.queue_free(), Vector2(200, 64)))
	var motivo := _motivo_no_combatir(n, bloqueo)
	var bc := UI.boton("¡Combatir!", func():
		capa.queue_free()
		_combatir(n), Vector2(260, 64))
	bc.disabled = motivo != ""
	h2.add_child(bc)
	v.add_child(h2)
	if motivo != "" and bloqueo == "":
		v.add_child(UI.etiqueta(motivo, 20, Color("#ff9a9a"), true))


func _motivo_no_combatir(n: Dictionary, bloqueo: String) -> String:
	if bloqueo != "":
		return bloqueo
	if Estado.esta_desafinado():
		return "Tu equipo está Desafinado: espera %s o registra ejercicios extra." % Estado.formato_tiempo(Estado.segundos_desafinado())
	var r := Estado.segundos_reaparece(n["id"])
	if r > 0:
		return "El enemigo se desvaneció. Reaparece en %s." % Estado.formato_tiempo(r)
	if int(Estado.d["energia"]) < Estado.costo_nodo(n):
		return "No tienes energía suficiente. Completa tareas reales para recargarla."
	return ""


func _combatir(n: Dictionary) -> void:
	UI.dialogo(self, n.get("dialogo_antes", []), func():
		Estado.d["energia"] = int(Estado.d["energia"]) - Estado.costo_nodo(n)
		Estado.guardar()
		Estado.ir("combate", {"zona": zona["id"], "nodo": n["id"]}))
