extends Control
## Base de todas las pantallas.

const UI = preload("res://scripts/ui/ui.gd")

var params: Dictionary = {}


## Las pantallas en vertical sobrescriben esto y devuelven true.
func es_vertical() -> bool:
	return false


func volver_centro() -> void:
	Estado.ir("centro")
