extends Control
## Base de todas las pantallas.

const UI = preload("res://scripts/ui/ui.gd")

var params: Dictionary = {}


func volver_centro() -> void:
	Estado.ir("centro")
