extends Node
## Música de fondo y volumen del juego.
## - La música de menús suena en las pantallas de MUSICA_EN y se apaga (con desvanecido)
##   en las demás: video de intro, campaña, mapa y combate.
## - Los ajustes (música y efectos: encendido y volumen) se guardan en user://ajustes.json,
##   aparte de la partida, así se conservan aunque empieces una partida nueva.

const RUTA_AJUSTES := "user://ajustes.json"
const MUSICA_MENU := "res://assets/musica/menu"
const MUSICA_EN := ["titulo", "creacion", "centro", "escuadron", "equipo", "archivo", "tareas", "ensayo"]
const BUS_MUSICA := "Musica"
const BUS_EFECTOS := "Efectos"

var ajustes := {"musica_on": true, "musica_vol": 0.7, "efectos_on": true, "efectos_vol": 0.9}
var reproductor: AudioStreamPlayer
var tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_bus(BUS_MUSICA)
	_crear_bus(BUS_EFECTOS)
	_cargar()
	reproductor = AudioStreamPlayer.new()
	reproductor.bus = BUS_MUSICA
	add_child(reproductor)
	var st := _cargar_musica()
	if st:
		reproductor.stream = st
	aplicar()


func _crear_bus(nombre: String) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, nombre)
	AudioServer.set_bus_send(i, "Master")


func _cargar_musica() -> AudioStream:
	for ext: String in [".ogg", ".mp3", ".wav"]:
		var ruta: String = MUSICA_MENU + ext
		if ResourceLoader.exists(ruta):
			var st: AudioStream = load(ruta)
			if "loop" in st:
				st.set("loop", true)
			return st
	return null


## Llamar al cambiar de pantalla: decide si la música de menús suena o no.
func pantalla(nombre: String) -> void:
	if reproductor == null or reproductor.stream == null:
		return
	if nombre in MUSICA_EN:
		if not reproductor.playing:
			reproductor.volume_db = -40.0
			reproductor.play()
		_desvanecer(0.0, 0.8)
	elif reproductor.playing:
		_desvanecer(-40.0, 0.8, true)


func _desvanecer(destino_db: float, dur: float, detener := false) -> void:
	if tw:
		tw.kill()
	tw = create_tween()
	tw.tween_property(reproductor, "volume_db", destino_db, dur)
	if detener:
		tw.tween_callback(reproductor.stop)


## Aplica encendido/volumen a los buses de música y efectos.
func aplicar() -> void:
	for par in [[BUS_MUSICA, "musica"], [BUS_EFECTOS, "efectos"]]:
		var i := AudioServer.get_bus_index(par[0])
		var vol: float = ajustes[par[1] + "_vol"]
		var on: bool = ajustes[par[1] + "_on"]
		AudioServer.set_bus_mute(i, not on or vol <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(max(vol, 0.001)))


func cambiar(clave: String, valor) -> void:
	ajustes[clave] = valor
	aplicar()
	_guardar()


func _cargar() -> void:
	if not FileAccess.file_exists(RUTA_AJUSTES):
		return
	var v = JSON.parse_string(FileAccess.get_file_as_string(RUTA_AJUSTES))
	if typeof(v) == TYPE_DICTIONARY:
		for k in ajustes:
			if v.has(k):
				ajustes[k] = v[k]


func _guardar() -> void:
	var f := FileAccess.open(RUTA_AJUSTES, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(ajustes))
		f.close()
