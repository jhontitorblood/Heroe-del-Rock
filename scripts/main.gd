extends Control
## Raíz del juego: cambia entre pantallas y maneja el botón "atrás" de Android.

const UI = preload("res://scripts/ui/ui.gd")

var actual: Control = null
var nombre_actual := ""


func _ready() -> void:
	theme = UI.crear_tema()
	Estado.cambiar_pantalla.connect(_ir)
	_ir("titulo", {})


func _ir(nombre: String, params: Dictionary) -> void:
	if actual:
		actual.queue_free()
	var s: Control = load("res://scripts/pantallas/%s.gd" % nombre).new()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.params = params
	actual = s
	nombre_actual = nombre
	add_child(s)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if nombre_actual in ["titulo", "centro"]:
			get_tree().quit()
		elif nombre_actual != "combate":
			_ir("centro", {})
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not Estado.d.is_empty():
			Estado.guardar()
