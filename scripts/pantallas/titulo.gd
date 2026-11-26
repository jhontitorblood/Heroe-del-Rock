extends "res://scripts/pantallas/pantalla.gd"


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_titulo"), 0.35)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(v)
	var t := UI.etiqueta("HÉROE DEL ROCK", 76, UI.ACENTO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 14)
	v.add_child(t)
	var s := UI.etiqueta("RPG táctico de rock boliviano · Beta de Cotoca 0.1", 24, UI.ORO)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	v.add_child(Control.new())
	if Estado.hay_partida():
		v.add_child(UI.boton("Continuar", _continuar, Vector2(420, 72)))
	v.add_child(UI.boton("Nueva partida", _nueva, Vector2(420, 72)))


func _continuar() -> void:
	if Estado.cargar():
		Estado.ir("centro")
	else:
		UI.aviso(self, "Error", "No se pudo leer la partida guardada.")


func _nueva() -> void:
	if not Estado.hay_partida():
		Estado.ir("creacion")
		return
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa)
	v.add_child(UI.etiqueta("¿Empezar de nuevo?", 30, UI.ORO))
	v.add_child(UI.etiqueta("Se borrará tu partida actual, con tus seguidores y tu progreso.", 22, UI.TEXTO, true))
	var h := HBoxContainer.new()
	h.add_child(UI.boton("Cancelar", func(): capa.queue_free(), Vector2(240, 64)))
	h.add_child(UI.boton("Borrar y empezar", func():
		Estado.borrar_partida()
		Estado.ir("creacion"), Vector2(300, 64)))
	v.add_child(h)
