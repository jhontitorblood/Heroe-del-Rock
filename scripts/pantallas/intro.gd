extends "res://scripts/pantallas/pantalla.gd"
## Video de entrada (assets/video/intro.ogv). Se salta tocando 2 veces.

const RUTA_VIDEO := "res://assets/video/intro.ogv"
const DOBLE_TOQUE_SEG := 0.45

var video: VideoStreamPlayer
var ultimo_toque := -10.0
var saliendo := false


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	if not ResourceLoader.exists(RUTA_VIDEO):
		_salir.call_deferred()
		return
	video = VideoStreamPlayer.new()
	video.stream = load(RUTA_VIDEO)
	video.set_anchors_preset(Control.PRESET_FULL_RECT)
	video.expand = true
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(video)
	video.finished.connect(_salir)
	video.play()
	var aviso := UI.etiqueta("Toca 2 veces para saltar", 20, Color(1, 1, 1, 0.55))
	aviso.anchor_left = 1.0
	aviso.anchor_top = 1.0
	aviso.anchor_right = 1.0
	aviso.anchor_bottom = 1.0
	aviso.offset_left = -300
	aviso.offset_top = -50
	aviso.offset_right = -24
	aviso.offset_bottom = -16
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(aviso)


func _gui_input(event: InputEvent) -> void:
	# Solo toques de pantalla: en Android cada toque genera además un clic de ratón
	# simulado, que antes se contaba como segundo toque y saltaba el video con uno solo.
	# En computadora el clic se convierte en toque (emulate_touch_from_mouse).
	if not (event is InputEventScreenTouch) or not event.pressed or event.index != 0:
		return
	accept_event()
	var t := Time.get_ticks_msec() / 1000.0
	if t - ultimo_toque <= DOBLE_TOQUE_SEG:
		_salir()
		return
	ultimo_toque = t


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	if video:
		video.stop()
	Estado.ir("titulo")
