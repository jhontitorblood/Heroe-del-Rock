extends "res://scripts/pantallas/pantalla.gd"
## Pantalla de inicio: imagen con el nombre del juego (el mensaje para tocar viene en la imagen).
## Tocar en cualquier parte continúa.

var listo := false


func _ready() -> void:
	UI.fondo(self, Datos.textura("escenarios", "esc_inicio"), 0.0)
	var ver := UI.etiqueta("v0.2 · Beta de Cotoca", 16, Color(1, 1, 1, 0.5))
	ver.position = Vector2(16, 12)
	add_child(ver)
	# Evita que el doble toque que saltó el video cuente aquí
	get_tree().create_timer(0.4).timeout.connect(func(): listo = true)


func _gui_input(event: InputEvent) -> void:
	if not listo:
		return
	if event is InputEventScreenTouch and event.pressed:
		listo = false
		_comenzar()


func _comenzar() -> void:
	if not Estado.hay_partida():
		Estado.ir("creacion")
		return
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 560)
	v.add_child(UI.etiqueta("Héroe del Rock", 32, UI.ORO))
	v.add_child(UI.boton("Continuar partida", func():
		if Estado.cargar():
			Estado.ir("centro")
		else:
			UI.aviso(self, "Error", "No se pudo leer la partida guardada."), Vector2(0, 72)))
	v.add_child(UI.boton("Nueva partida", func(): _confirmar_nueva(capa), Vector2(0, 72)))


func _confirmar_nueva(capa_anterior: Control) -> void:
	capa_anterior.queue_free()
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 640)
	v.add_child(UI.etiqueta("¿Empezar de nuevo?", 30, UI.ORO))
	v.add_child(UI.etiqueta("Se borrará tu partida actual, con tus seguidores y tu progreso.", 22, UI.TEXTO, true))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(UI.boton("Cancelar", func():
		capa.queue_free()
		listo = true, Vector2(220, 64)))
	h.add_child(UI.boton("Borrar y empezar", func():
		Estado.borrar_partida()
		Estado.ir("creacion"), Vector2(300, 64)))
	v.add_child(h)
