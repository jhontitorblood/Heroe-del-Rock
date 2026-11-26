extends Control
## Raíz del juego: cambia entre pantallas, ajusta la orientación (vertical u horizontal)
## y maneja el botón "atrás" de Android.

const UI = preload("res://scripts/ui/ui.gd")
const TAM_HORIZONTAL := Vector2i(1280, 720)
const TAM_VERTICAL := Vector2i(720, 1280)

var actual: Control = null
var nombre_actual := ""
var vertical_actual := false


func _ready() -> void:
	theme = UI.crear_tema()
	Estado.cambiar_pantalla.connect(_ir)
	_ir("intro", {})


func _ir(nombre: String, params: Dictionary) -> void:
	if actual:
		actual.queue_free()
	var s: Control = load("res://scripts/pantallas/%s.gd" % nombre).new()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.params = params
	_orientar(s.es_vertical())
	actual = s
	nombre_actual = nombre
	add_child(s)


func _orientar(vertical: bool) -> void:
	vertical_actual = vertical
	var raiz := get_tree().root
	raiz.content_scale_size = TAM_VERTICAL if vertical else TAM_HORIZONTAL
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT if vertical else DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	elif DisplayServer.get_name() != "headless" and not OS.has_feature("editor_hint"):
		# En computadora se simula el giro cambiando el tamaño de la ventana
		var alto := DisplayServer.window_get_size().y
		var ancho := int(alto * (9.0 / 16.0)) if vertical else int(alto * (16.0 / 9.0))
		DisplayServer.window_set_size(Vector2i(ancho, alto))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if nombre_actual in ["intro", "titulo", "centro"]:
			get_tree().quit()
		elif nombre_actual != "combate":
			_ir("centro", {})
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not Estado.d.is_empty():
			Estado.guardar()
