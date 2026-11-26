extends Node
## Carga todos los datos del juego desde /data (JSON).
## Agregar contenido (zonas, personajes, habilidades) = editar los JSON, sin tocar código.

var clases: Dictionary = {}
var habilidades: Dictionary = {}
var personajes: Dictionary = {}
var territorios: Dictionary = {}
var reglas: Dictionary = {}
var generos: Dictionary = {}
var tareas: Dictionary = {}


func _ready() -> void:
	clases = _cargar("res://data/clases.json")
	habilidades = _cargar("res://data/habilidades.json")
	personajes = _cargar("res://data/personajes.json")
	territorios = _cargar("res://data/territorios.json")
	reglas = _cargar("res://data/reglas.json")
	generos = _cargar("res://data/generos.json")
	tareas = _cargar("res://data/tareas.json")


func _cargar(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		push_error("Falta el archivo de datos: " + ruta)
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if typeof(d) != TYPE_DICTIONARY:
		push_error("JSON inválido: " + ruta)
		return {}
	return d


# ---------- Personajes ----------

func personaje(base_id: String) -> Dictionary:
	return personajes.get(base_id, {})


func clase_de(base_id: String) -> Dictionary:
	return clases.get(personaje(base_id).get("clase", ""), {})


func rareza(id: String) -> Dictionary:
	return reglas["rarezas"].get(id, reglas["rarezas"]["comun"])


func habilidades_de(base_id: String) -> Array:
	var p := personaje(base_id)
	return p.get("habilidades", clase_de(base_id).get("habilidades", []))


func definitiva_de(base_id: String) -> String:
	var p := personaje(base_id)
	return p.get("definitiva", clase_de(base_id).get("definitiva", ""))


## Estadísticas de un personaje a cierto nivel (sin bonus de tareas).
func stats(base_id: String, nivel: int) -> Dictionary:
	var p := personaje(base_id)
	var b: Dictionary = clase_de(base_id).get("base", {"hp": 100, "atk": 10, "def": 8, "spd": 10})
	var m: Dictionary = p.get("mult", {})
	var r: float = rareza(p.get("rareza", "comun")).get("mult", 1.0)
	var f := 1.0 + 0.12 * (nivel - 1)
	return {
		"hp": int(b["hp"] * m.get("hp", 1.0) * r * f),
		"atk": b["atk"] * m.get("atk", 1.0) * r * f,
		"def": b["def"] * m.get("def", 1.0) * r * f,
		"spd": b["spd"] * m.get("spd", 1.0) + nivel * 0.2,
	}


# ---------- Géneros y afinidades ----------

func nombre_genero(g: String) -> String:
	return generos["nombres"].get(g, g)


func color_genero(g: String) -> Color:
	return Color(generos["colores"].get(g, "#ffffff"))


## true si el género a vence al género b en el ciclo.
func vence(a: String, b: String) -> bool:
	var orden: Array = generos["orden"]
	var ia := orden.find(a)
	var ib := orden.find(b)
	if ia < 0 or ib < 0:
		return false
	return (ia + 1) % orden.size() == ib


func multiplicador_afinidad(atacante: String, defensor: String) -> float:
	var v: float = generos["ventaja"]
	if vence(atacante, defensor):
		return 1.0 + v
	if vence(defensor, atacante):
		return 1.0 - v
	return 1.0


## Ajuste de sinergia entre dos géneros que atacan al mismo objetivo en la misma ronda.
func sinergia_generos(a: String, b: String) -> float:
	var s: Dictionary = generos["sinergia"]
	if a == b:
		return s["mismo"]
	if vence(a, b) or vence(b, a):
		return s["enfrentado"]
	return s["complementario"]


# ---------- Territorios ----------

func zona(zona_id: String) -> Dictionary:
	for dep in territorios.values():
		for z in dep["zonas"]:
			if z["id"] == zona_id:
				return z
	return {}


func nodo(zona_id: String, nodo_id: String) -> Dictionary:
	for n in zona(zona_id).get("nodos", []):
		if n["id"] == nodo_id:
			return n
	return {}


# ---------- Recursos gráficos ----------

## Carga una imagen provisional/definitiva por nombre. Devuelve null si no existe.
func textura(carpeta: String, nombre: String) -> Texture2D:
	var ruta := "res://assets/%s/%s.png" % [carpeta, nombre]
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return null


func sprite(imagen: String, espectral: bool) -> Texture2D:
	return textura("personajes", "pj_%s_%s" % [imagen, "espectral" if espectral else "normal"])


## Cuadros de una animación: assets/animaciones/<nombre>/0001.png, 0002.png, ...
func animacion(nombre: String) -> Array:
	var cuadros := []
	var i := 1
	while i < 1000:
		var ruta := "res://assets/animaciones/%s/%04d.png" % [nombre, i]
		if not ResourceLoader.exists(ruta):
			break
		cuadros.append(load(ruta))
		i += 1
	return cuadros
