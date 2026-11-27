extends "res://scripts/pantallas/pantalla.gd"
## Mapa de una zona: combates, sublíderes, líder, jefe y secretos.

const BASE := Vector2(1280, 720)

var zona: Dictionary
var botones := {}
var lienzo: Control  # nodos y caminos sobre el arte del mapa (coordenadas 1280×720)


func _ready() -> void:
	zona = Datos.zona(params.get("zona", "cotoca"))
	lienzo = UI.lienzo(self, Datos.textura("mapas", zona.get("mapa", "")))
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


const TAM_ICONO := 74.0
const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")


## Punto del mapa: ícono (bloqueado, desbloqueado o vencido) sobre el marcador del arte,
## con una etiqueta corta debajo. El desbloqueado late para indicar que se puede jugar.
func _crear_boton(n: Dictionary) -> void:
	var en := Estado.estado_nodo(n["id"])
	var bloqueo := Estado.bloqueo_nodo(n)
	var secreto: bool = n["tipo"] == "secreto"
	var estado := "bloqueado" if bloqueo != "" else ("vencido" if bool(en["vencido"]) else "desbloqueado")
	var espera := Estado.segundos_reaparece(n["id"])
	var centro := Vector2(n["pos"][0], n["pos"][1])
	var raiz := Control.new()
	raiz.position = centro
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(raiz)
	# Ícono
	var ico := TextureRect.new()
	ico.texture = Datos.textura("ui", "icono_" + estado)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.size = Vector2(TAM_ICONO, TAM_ICONO)
	ico.position = -ico.size / 2.0
	ico.pivot_offset = ico.size / 2.0
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if espera > 0:
		ico.modulate = Color(0.5, 0.5, 0.5)
	raiz.add_child(ico)
	if estado == "desbloqueado" and espera == 0:
		var tw := ico.create_tween().set_loops()
		tw.tween_property(ico, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ico, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	# Etiqueta corta
	var tipos := {"sublider": "SUBLÍDER · ", "lider": "LÍDER · ", "jefe": "JEFE · ", "secreto": ""}
	var txt: String = "???" if secreto and bloqueo != "" else tipos.get(n["tipo"], "") + String(n.get("corto", n["nombre"])).to_upper()
	txt += "  NV %d" % int(n["nivel"])
	if espera > 0:
		txt += "\nREAPARECE EN " + Estado.formato_tiempo(espera)
	var et := Label.new()
	et.text = txt
	et.add_theme_font_override("font", FUENTE)
	et.add_theme_font_size_override("font_size", 20)
	et.add_theme_color_override("font_color", {"bloqueado": Color("#b8b0c0"), "desbloqueado": Color("#ece3d0"), "vencido": Color("#ffd23a")}[estado])
	et.add_theme_color_override("font_outline_color", Color.BLACK)
	et.add_theme_constant_override("outline_size", 7)
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	et.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo_et := StyleBoxFlat.new()
	fondo_et.bg_color = Color(0, 0, 0, 0.72)
	fondo_et.set_corner_radius_all(8)
	fondo_et.content_margin_left = 8
	fondo_et.content_margin_right = 8
	fondo_et.content_margin_top = 1
	fondo_et.content_margin_bottom = 1
	et.add_theme_stylebox_override("normal", fondo_et)
	raiz.add_child(et)
	et.reset_size()
	et.position = Vector2(-et.size.x / 2.0, TAM_ICONO / 2.0 - 4)
	# Zona tocable (ícono + etiqueta)
	var b := Button.new()
	for e in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	b.size = Vector2(max(TAM_ICONO, et.size.x), TAM_ICONO + et.size.y)
	b.position = Vector2(-b.size.x / 2.0, -TAM_ICONO / 2.0)
	b.pressed.connect(_abrir.bind(n))
	raiz.add_child(b)
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
