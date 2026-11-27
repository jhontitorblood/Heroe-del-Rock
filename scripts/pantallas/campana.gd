extends "res://scripts/pantallas/pantalla.gd"
## Campaña: mapa de Santa Cruz con sus territorios. A la izquierda, en la zona vacía del
## mapa, un panel con el acto actual, el progreso, el objetivo y la leyenda de íconos.

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const HUESO := Color("#ece3d0")

var dep: Dictionary
var lienzo: Control


func _ready() -> void:
	dep = Datos.territorios["santa_cruz"]
	lienzo = UI.lienzo(self, Datos.textura("mapas", dep["mapa"]))
	for lugar in dep.get("lugares", []):
		_lugar(lugar)
	for z in dep["zonas"]:
		if z.has("pos"):
			_zona(z)
	_panel_info()


func _estado_zona(z: Dictionary) -> String:
	if not bool(z.get("disponible", false)):
		return "bloqueado"
	if z.has("jefe_nodo") and Estado.nodo_vencido(z["jefe_nodo"]):
		return "vencido"
	return "desbloqueado"


func _zona(z: Dictionary) -> void:
	var estado := _estado_zona(z)
	var linea2: String = z["banda"] if estado != "bloqueado" else "PRÓXIMAMENTE"
	var txt := "%s\n%s" % [String(z["nombre"]).to_upper(), linea2.to_upper()]
	UI.marcador(lienzo, Vector2(z["pos"][0], z["pos"][1]), estado, txt, _tocar_zona.bind(z))


func _tocar_zona(z: Dictionary) -> void:
	if bool(z.get("disponible", false)):
		Estado.ir("mapa", {"zona": z["id"]})
	else:
		var txt := "Banda: %s\nEstilo: %s" % [z["banda"], z["estilo"]]
		if z.has("lider"):
			txt += "\nLíder: %s" % z["lider"]
		if z.has("jefe"):
			txt += "\nJefe territorial: %s" % z["jefe"]
		UI.aviso(self, z["nombre"], txt + "\n\n" + String(z.get("bloqueo", "Bloqueado")))


## Lugar sin combate (texto sobre el mapa).
func _lugar(l: Dictionary) -> void:
	var et := _texto("%s\n%s" % [String(l["nombre"]).to_upper(), String(l.get("detalle", "")).to_upper()], 22, HUESO)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.7)
	fondo.set_corner_radius_all(8)
	fondo.content_margin_left = 10
	fondo.content_margin_right = 10
	et.add_theme_stylebox_override("normal", fondo)
	lienzo.add_child(et)
	et.reset_size()
	et.position = Vector2(l["pos"][0], l["pos"][1]) - et.size / 2.0


func _texto(t: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 7)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Panel en la zona vacía de la izquierda.
func _panel_info() -> void:
	var p := PanelContainer.new()
	var est := StyleBoxFlat.new()
	est.bg_color = Color(0.04, 0.02, 0.05, 0.82)
	est.border_color = Color("#d8232c")
	est.set_border_width_all(2)
	est.set_corner_radius_all(12)
	est.content_margin_left = 16
	est.content_margin_right = 16
	est.content_margin_top = 12
	est.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", est)
	p.position = Vector2(14, 236)
	p.custom_minimum_size = Vector2(500, 0)
	lienzo.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	fila.add_child(UI.boton("< Volver", volver_centro, Vector2(130, 50)))
	var t := _texto("CAMPAÑA · SANTA CRUZ", 32, UI.ORO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fila.add_child(t)
	v.add_child(_izq(_texto(String(dep.get("acto", "")).to_upper(), 24, Color("#d8232c"))))
	# Progreso
	var con_mapa: Array = dep["zonas"].filter(func(z): return z.has("pos"))
	var liberados: int = con_mapa.filter(func(z): return _estado_zona(z) == "vencido").size()
	v.add_child(UI.etiqueta("Territorios liberados: %d de %d" % [liberados, con_mapa.size()], 20, UI.TEXTO))
	v.add_child(UI.barra(liberados, con_mapa.size(), Color("#ffd23a"), 10))
	v.add_child(UI.etiqueta("Objetivo: " + _objetivo(), 20, UI.ESPECTRAL, true))
	var historia := "Algo está silenciando a las bandas de las provincias. Silvano Roca te pidió empezar por Cotoca."
	if Estado.nodo_vencido("c8"):
		historia = "Cotoca vuelve a sonar. Los demás territorios se abrirán en las próximas versiones."
	v.add_child(UI.etiqueta(historia, 18, UI.TENUE, true))
	# Leyenda de íconos
	var ley := HBoxContainer.new()
	ley.add_theme_constant_override("separation", 6)
	v.add_child(ley)
	for par in [["bloqueado", "Bloqueado"], ["desbloqueado", "Disponible"], ["vencido", "Liberado"]]:
		ley.add_child(UI.imagen(Datos.textura("ui", "icono_" + par[0]), Vector2(34, 34)))
		var l := UI.etiqueta(par[1] + "   ", 17, UI.TEXTO)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ley.add_child(l)
	v.add_child(UI.boton("Ver la historia otra vez", func():
		var creacion = load("res://scripts/pantallas/creacion.gd")
		UI.dialogo(self, creacion.INTRO, func(): pass), Vector2(0, 50)))


func _izq(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


## Siguiente combate disponible en Cotoca, o el estado general.
func _objetivo() -> String:
	var z := Datos.zona("cotoca")
	if Estado.nodo_vencido(z["jefe_nodo"]):
		return "Cotoca liberada. Espera el próximo territorio."
	for n in z["nodos"]:
		if n["tipo"] == "secreto" or Estado.nodo_vencido(n["id"]):
			continue
		var b := Estado.bloqueo_nodo(n)
		if b == "":
			return "Cotoca · %s (nivel %d)." % [n["nombre"], int(n["nivel"])]
		return "Cotoca · %s. %s." % [n["nombre"], b]
	return "Explora Cotoca."
