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
var familias: Dictionary = {}


func _ready() -> void:
	clases = _cargar("res://data/clases.json")
	habilidades = _cargar("res://data/habilidades.json")
	personajes = _cargar("res://data/personajes.json")
	territorios = _cargar("res://data/territorios.json")
	reglas = _cargar("res://data/reglas.json")
	generos = _cargar("res://data/generos.json")
	tareas = _cargar("res://data/tareas.json")
	familias = _cargar("res://data/familias.json")


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


## Instrumento del personaje (propio o el de su clase).
func instrumento_de(base_id: String) -> String:
	return personaje(base_id).get("instrumento", clase_de(base_id).get("instrumento", "—"))


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


# ---------- Familias de instrumentos (deciden las ventajas en combate) ----------

## Familia del personaje: la propia (por su instrumento) o la de su clase.
func familia_de(base_id: String) -> String:
	return personaje(base_id).get("familia", clase_de(base_id).get("familia", "cordofono"))


func icono_tipo(f: String) -> Texture2D:
	return textura("ui", "tipo_" + f)


func nombre_familia(f: String) -> String:
	return familias["nombres"].get(f, f)


func color_familia(f: String) -> Color:
	return Color(familias["colores"].get(f, "#ffffff"))


## true si la familia a vence a la familia b en el ciclo.
func vence(a: String, b: String) -> bool:
	var orden: Array = familias["orden"]
	var ia := orden.find(a)
	var ib := orden.find(b)
	if ia < 0 or ib < 0:
		return false
	return (ia + 1) % orden.size() == ib


func multiplicador_afinidad(atacante: String, defensor: String) -> float:
	var v: float = familias["ventaja"]
	if vence(atacante, defensor):
		return 1.0 + v
	if vence(defensor, atacante):
		return 1.0 - v
	return 1.0


## Ajuste de sinergia entre dos familias que atacan al mismo objetivo en la misma ronda.
func sinergia_familias(a: String, b: String) -> float:
	var s: Dictionary = familias["sinergia"]
	if a == b:
		return s["mismo"]
	if vence(a, b) or vence(b, a):
		return s["enfrentado"]
	return s["complementario"]


## Bonus de equipo según cuántas familias distintas lo forman: {nombre, dano, banda_extra}.
func bonus_banda(familias_equipo: Array) -> Dictionary:
	var distintas := []
	for f in familias_equipo:
		if not f in distintas:
			distintas.append(f)
	var o: Dictionary = familias["orquesta_total"]
	var bc: Dictionary = familias["banda_completa"]
	if distintas.size() >= int(o["familias"]):
		return {"nombre": "¡Orquesta total!", "dano": float(o["bonus_dano"]), "banda_extra": float(bc["medidor_banda_extra"])}
	if distintas.size() >= int(bc["familias"]):
		return {"nombre": "¡Banda completa!", "dano": float(bc["bonus_dano"]), "banda_extra": float(bc["medidor_banda_extra"])}
	return {}


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


## Imagen en pose de ataque (pj_<id>_normal_ataque / pj_<id>_espectral_ataque), o null si no hay.
func sprite_ataque(imagen: String, espectral: bool) -> Texture2D:
	return textura("personajes", "pj_%s_%s_ataque" % [imagen, "espectral" if espectral else "normal"])


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
