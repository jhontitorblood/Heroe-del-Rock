extends "res://scripts/pantallas/pantalla.gd"
## Campaña: mapa de Santa Cruz con sus 5 territorios iniciales.

const BASE := Vector2(1280, 720)


func _ready() -> void:
	var dep: Dictionary = Datos.territorios["santa_cruz"]
	UI.fondo(self, Datos.textura("mapas", dep["mapa"]), 0.25)
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(capa)
	for z in dep["zonas"]:
		var b := Button.new()
		var activo: bool = z["disponible"]
		b.text = "%s\n%s" % [z["nombre"], z["banda"]]
		b.custom_minimum_size = Vector2(230, 84)
		b.disabled = not activo
		b.anchor_left = float(z["pos"][0]) / BASE.x
		b.anchor_top = float(z["pos"][1]) / BASE.y
		b.anchor_right = b.anchor_left
		b.anchor_bottom = b.anchor_top
		b.offset_left = -115
		b.offset_top = -42
		b.offset_right = 115
		b.offset_bottom = 42
		if activo:
			b.pressed.connect(func(): Estado.ir("mapa", {"zona": z["id"]}))
		else:
			b.text += "\n(bloqueado)"
			b.tooltip_text = z.get("bloqueo", "")
		capa.add_child(b)
	var m := UI.margen(self, 20)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UI.encabezado("Campaña · Acto I: Primer Riff", volver_centro))
	var hist := UI.panel()
	hist.custom_minimum_size = Vector2(520, 0)
	hist.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(hist)
	var hv := VBoxContainer.new()
	hist.add_child(hv)
	hv.add_child(UI.etiqueta("Santa Cruz — las 5 provincias", 24, UI.ORO))
	var texto := "Algo está silenciando a las bandas de las provincias. Silvano Roca te pidió empezar por Cotoca."
	if Estado.nodo_vencido("c8"):
		texto = "Cotoca vuelve a sonar. La Guardia y los Cambas Punk te esperan en la próxima versión."
	hv.add_child(UI.etiqueta(texto, 20, UI.TEXTO, true))
	hv.add_child(UI.boton("Ver la historia otra vez", func():
		var creacion = load("res://scripts/pantallas/creacion.gd")
		UI.dialogo(self, creacion.INTRO, func(): pass), Vector2(0, 52)))
