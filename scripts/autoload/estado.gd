extends Node
## Estado de la partida + reglas de progreso (tareas, energía, despertar, ensayo, derrota).
## Se guarda en user://partida.json.

signal cambiar_pantalla(nombre: String, params: Dictionary)
signal cambio  # se emite cuando cambia algo visible (energía, nivel, etc.)

const RUTA := "user://partida.json"
const VERSION := 1

var d: Dictionary = {}  # datos de la partida


func ir(nombre: String, params: Dictionary = {}) -> void:
	cambiar_pantalla.emit(nombre, params)


# =====================================================================
# Tiempo
# =====================================================================

func ahora() -> int:
	return int(Time.get_unix_time_from_system())


## Día local (cuenta días desde 1970 en la zona horaria del teléfono).
func dia_local() -> int:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return int(floor((ahora() + bias * 60) / 86400.0))


func semana_local() -> int:
	return int(floor(dia_local() / 7.0))


static func formato_tiempo(seg: int) -> String:
	seg = max(seg, 0)
	var h := seg / 3600
	var m := (seg % 3600) / 60
	var s := seg % 60
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%d:%02d" % [m, s]


# =====================================================================
# Partida
# =====================================================================

func hay_partida() -> bool:
	return FileAccess.file_exists(RUTA)


func nueva_partida(genero: String, nombre: String) -> void:
	var r: Dictionary = Datos.reglas
	d = {
		"version": VERSION,
		"protagonista": {"genero": genero, "nombre": nombre, "base_id": "protagonista_" + genero},
		"nivel": 1, "xp": 0, "hp_frac": 1.0,
		"bonus": {"hp": 0.0, "atk": 0.0, "def": 0.0, "maestria": 0},
		"fama": 0,
		"energia": r["energia"]["inicial"],
		"pua": 0,
		"seguidores": [],
		"siguiente_uid": 1,
		"equipo": [],
		"tam_equipo": r["equipo"]["tam_inicial"],
		"nodos": {},
		"encontrados": {},
		"tareas": Datos.tareas["tareas"].duplicate(true),
		"siguiente_tarea": 1,
		"dia": dia_local(),
		"hoy": {"hechas": {}, "xp": 0, "cadena_corta": false, "cadena_completa": false, "practicas": 0},
		"totales": {"ejercicio": 0, "practica": 0, "casa": 0, "trabajo": 0},
		"racha": 0, "ultimo_activo": -10, "gracia_semana": -1,
		"desafinado_hasta": 0,
		"ensayo_rapido_listo": 0,
		"en_sintonia": false,
		"quimica": {},
		"vistos": {},
	}
	guardar()


func cargar() -> bool:
	if not hay_partida():
		return false
	var txt := FileAccess.get_file_as_string(RUTA)
	var v = JSON.parse_string(txt)
	if typeof(v) != TYPE_DICTIONARY:
		return false
	d = v
	revisar_dia()
	return true


func guardar() -> void:
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()
	cambio.emit()


func borrar_partida() -> void:
	if hay_partida():
		DirAccess.remove_absolute(RUTA)
	d = {}


func nombre_jugador() -> String:
	return d["protagonista"]["nombre"]


# =====================================================================
# Día nuevo
# =====================================================================

func revisar_dia() -> void:
	if d.is_empty():
		return
	var hoy := dia_local()
	if int(d["dia"]) == hoy:
		return
	var e: Dictionary = Datos.reglas["energia"]
	d["energia"] = min(int(e["maxima"]), int(d["energia"]) + int(e["diaria"]))
	d["dia"] = hoy
	d["hoy"] = {"hechas": {}, "xp": 0, "cadena_corta": false, "cadena_completa": false, "practicas": 0}
	guardar()


# =====================================================================
# Experiencia y niveles
# =====================================================================

func xp_necesaria(nivel: int) -> int:
	return int(Datos.reglas["xp"]["necesaria_por_nivel"]) * nivel


## Suma XP al protagonista. Devuelve los niveles ganados.
func ganar_xp_prota(xp: int) -> int:
	d["xp"] = int(d["xp"]) + xp
	var subidos := 0
	while int(d["xp"]) >= xp_necesaria(int(d["nivel"])):
		d["xp"] = int(d["xp"]) - xp_necesaria(int(d["nivel"]))
		d["nivel"] = int(d["nivel"]) + 1
		subidos += 1
	return subidos


func ganar_xp_seguidor(s: Dictionary, xp: int) -> int:
	s["xp"] = int(s.get("xp", 0)) + xp
	var subidos := 0
	while int(s["xp"]) >= xp_necesaria(int(s["nivel"])):
		s["xp"] = int(s["xp"]) - xp_necesaria(int(s["nivel"]))
		s["nivel"] = int(s["nivel"]) + 1
		subidos += 1
	return subidos


# =====================================================================
# Seguidores y equipo
# =====================================================================

func seguidor(uid: String) -> Dictionary:
	for s in d["seguidores"]:
		if s["uid"] == uid:
			return s
	return {}


func agregar_seguidor(base_id: String, nivel: int) -> Dictionary:
	var uid := "s%d" % int(d["siguiente_uid"])
	d["siguiente_uid"] = int(d["siguiente_uid"]) + 1
	var s := {"uid": uid, "base_id": base_id, "nivel": nivel, "xp": 0, "hp_frac": 1.0}
	d["seguidores"].append(s)
	# Ampliar equipo tras el primer Despertar
	var tam: int = Datos.reglas["equipo"]["tam_tras_primer_despertar"]
	if int(d["tam_equipo"]) < tam:
		d["tam_equipo"] = tam
	# Si hay espacio, entra directo al equipo
	if d["equipo"].size() < int(d["tam_equipo"]) - 1:
		d["equipo"].append(uid)
	guardar()
	return s


func tiene_unico(base_id: String) -> bool:
	for s in d["seguidores"]:
		if s["base_id"] == base_id:
			return true
	return false


func alternar_en_equipo(uid: String) -> String:
	if uid in d["equipo"]:
		d["equipo"].erase(uid)
		guardar()
		return ""
	if d["equipo"].size() >= int(d["tam_equipo"]) - 1:
		return "El equipo está completo (%d de %d)." % [int(d["tam_equipo"]), int(d["tam_equipo"])]
	d["equipo"].append(uid)
	guardar()
	return ""


## Datos de cada miembro del equipo para iniciar un combate.
func equipo_combate() -> Array:
	var lista := []
	lista.append({
		"uid": "prota", "base_id": d["protagonista"]["base_id"], "nivel": int(d["nivel"]),
		"hp_frac": float(d["hp_frac"]), "nombre": nombre_jugador(), "bonus": d["bonus"], "espectral": false,
	})
	for uid in d["equipo"]:
		var s := seguidor(uid)
		if s.is_empty():
			continue
		lista.append({
			"uid": uid, "base_id": s["base_id"], "nivel": int(s["nivel"]),
			"hp_frac": float(s.get("hp_frac", 1.0)), "espectral": true,
		})
	return lista


func miembros_equipo() -> Array:
	## [{uid, nombre, hp_frac}] protagonista + seguidores del equipo
	var lista := [{"uid": "prota", "nombre": nombre_jugador(), "hp_frac": float(d["hp_frac"])}]
	for uid in d["equipo"]:
		var s := seguidor(uid)
		if not s.is_empty():
			lista.append({"uid": uid, "nombre": Datos.personaje(s["base_id"])["nombre"], "hp_frac": float(s.get("hp_frac", 1.0))})
	return lista


func set_hp_frac(uid: String, frac: float) -> void:
	frac = clamp(frac, 0.0, 1.0)
	if uid == "prota":
		d["hp_frac"] = frac
	else:
		var s := seguidor(uid)
		if not s.is_empty():
			s["hp_frac"] = frac


func curar_equipo(frac: float) -> void:
	for m in miembros_equipo():
		set_hp_frac(m["uid"], float(m["hp_frac"]) + frac)


# =====================================================================
# Química (sinergias entre pares que ensayan juntos)
# =====================================================================

static func clave_par(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func quimica(a: String, b: String) -> int:
	return int(d["quimica"].get(clave_par(a, b), 0))


func sumar_quimica_equipo(puntos: int) -> void:
	var ids := ["prota"] + Array(d["equipo"])
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var k := clave_par(ids[i], ids[j])
			d["quimica"][k] = int(d["quimica"].get(k, 0)) + puntos


# =====================================================================
# Energía y estado Desafinados
# =====================================================================

func esta_desafinado() -> bool:
	return int(d.get("desafinado_hasta", 0)) > ahora()


func segundos_desafinado() -> int:
	return max(0, int(d.get("desafinado_hasta", 0)) - ahora())


func costo_nodo(n: Dictionary) -> int:
	var e: Dictionary = Datos.reglas["energia"]
	return int(e["costo_jefe"]) if n.get("tipo", "") in ["lider", "jefe"] else int(e["costo_combate"])


func sumar_energia(x: int) -> void:
	d["energia"] = min(int(Datos.reglas["energia"]["maxima"]), int(d["energia"]) + x)


# =====================================================================
# Nodos del mapa
# =====================================================================

func estado_nodo(nodo_id: String) -> Dictionary:
	if not d["nodos"].has(nodo_id):
		d["nodos"][nodo_id] = {"vencido": false, "veces": 0, "unico_despertado": false, "reaparece": 0, "fallos": 0}
	return d["nodos"][nodo_id]


func nodo_vencido(nodo_id: String) -> bool:
	return d["nodos"].has(nodo_id) and bool(d["nodos"][nodo_id]["vencido"])


## Devuelve "" si se puede entrar, o el motivo del bloqueo.
func bloqueo_nodo(n: Dictionary) -> String:
	var req: Dictionary = n.get("requiere", {})
	var faltan := []
	if req.has("nodo") and not nodo_vencido(req["nodo"]):
		faltan.append("vencer el combate anterior")
	if req.has("nivel") and int(d["nivel"]) < int(req["nivel"]):
		faltan.append("nivel %d (tienes %d)" % [int(req["nivel"]), int(d["nivel"])])
	if req.has("racha") and int(d["racha"]) < int(req["racha"]):
		faltan.append("racha de %d días (tienes %d)" % [int(req["racha"]), int(d["racha"])])
	for cat in req.get("totales", {}):
		var necesita := int(req["totales"][cat])
		var tiene := int(d["totales"].get(cat, 0))
		if tiene < necesita:
			faltan.append("%d tareas reales de %s (llevas %d)" % [necesita, Datos.tareas["categorias"][cat]["nombre"].to_lower(), tiene])
	if faltan.is_empty():
		return ""
	return "Requiere: " + ", ".join(faltan)


func segundos_reaparece(nodo_id: String) -> int:
	return max(0, int(estado_nodo(nodo_id)["reaparece"]) - ahora())


## Enemigos del combate de un nodo. Si su enemigo único ya fue despertado,
## aparecen enemigos aleatorios de bajo nivel de la zona.
func enemigos_de_nodo(zona: Dictionary, n: Dictionary) -> Dictionary:
	var en := estado_nodo(n["id"])
	if bool(en["unico_despertado"]):
		var comunes: Array = zona.get("comunes", [])
		var lista := []
		for i in 2:
			lista.append(comunes[randi() % comunes.size()])
		return {"ids": lista, "nivel": max(1, int(n["nivel"]) - 1), "despertable": lista[0], "aleatorio": true, "fuerza": 0.85, "fuerza_hp": 1.0}
	return {"ids": n["enemigos"], "nivel": int(n["nivel"]), "despertable": n.get("despertable", ""), "aleatorio": false,
		"fuerza": float(n.get("fuerza", 1.0)), "fuerza_hp": float(n.get("fuerza_hp", 1.0))}


func enemigos_restantes_antes_del_jefe(zona: Dictionary) -> int:
	var c := 0
	for n in zona.get("nodos", []):
		if n["tipo"] in ["jefe", "secreto"]:
			continue
		if not nodo_vencido(n["id"]):
			c += 1
	return c


# =====================================================================
# Resultado de combate
# =====================================================================

## Aplica victoria: XP, vida restante, nodo vencido. Devuelve resumen.
func aplicar_victoria(n: Dictionary, nivel_enemigos: int, cantidad: int, hp_finales: Dictionary) -> Dictionary:
	var rx: Dictionary = Datos.reglas["xp"]
	var xp := int(rx["por_nivel_enemigo"]) * nivel_enemigos * cantidad
	if n.get("tipo", "") in ["lider", "jefe"]:
		xp = int(xp * float(rx["multiplicador_jefe"]))
	var resumen := {"xp": xp, "subidas": []}
	var sub := ganar_xp_prota(xp)
	if sub > 0:
		resumen["subidas"].append("%s sube a nivel %d" % [nombre_jugador(), int(d["nivel"])])
	for uid in d["equipo"]:
		var s := seguidor(uid)
		if s.is_empty():
			continue
		if ganar_xp_seguidor(s, xp) > 0:
			resumen["subidas"].append("%s sube a nivel %d" % [Datos.personaje(s["base_id"])["nombre"], int(s["nivel"])])
	for uid in hp_finales:
		set_hp_frac(uid, max(0.1, float(hp_finales[uid])))
	var en := estado_nodo(n["id"])
	en["vencido"] = true
	en["veces"] = int(en["veces"]) + 1
	# Tras vencer al líder se amplía el equipo a 3
	var re: Dictionary = Datos.reglas["equipo"]
	if n["id"] == re["nodo_lider"] and int(d["tam_equipo"]) < int(re["tam_tras_lider"]):
		d["tam_equipo"] = int(re["tam_tras_lider"])
		resumen["subidas"].append("¡Tu equipo ahora puede tener %d integrantes!" % int(d["tam_equipo"]))
	d["en_sintonia"] = false
	guardar()
	return resumen


func aplicar_derrota() -> void:
	d["desafinado_hasta"] = ahora() + int(Datos.reglas["desafinado_segundos"])
	for m in miembros_equipo():
		set_hp_frac(m["uid"], 0.3)
	d["en_sintonia"] = false
	guardar()


# =====================================================================
# Despertar espectral
# =====================================================================

func prob_despertar(nivel_enemigo: int, fallos: int, con_pua: bool) -> int:
	var r: Dictionary = Datos.reglas["despertar"]
	var dif := int(d["nivel"]) - nivel_enemigo
	var p := int(r["base"])
	if dif >= 0:
		p += dif * int(r["por_nivel_arriba"])
	else:
		p += dif * int(r["por_nivel_abajo"])
	p += fallos * int(r["por_fallo"])
	if con_pua:
		p += int(r["pua"])
	return clamp(p, int(r["minimo"]), int(r["maximo"]))


func usar_pua() -> bool:
	if int(d["pua"]) <= 0:
		return false
	d["pua"] = int(d["pua"]) - 1
	guardar()
	return true


func despertar_exito(nodo_id: String, base_id: String, nivel: int) -> Dictionary:
	var s := agregar_seguidor(base_id, nivel)
	var rz := Datos.rareza(Datos.personaje(base_id).get("rareza", "comun"))
	if bool(rz["unico"]):
		estado_nodo(nodo_id)["unico_despertado"] = true
	guardar()
	return s


func despertar_fallido(nodo_id: String, base_id: String) -> int:
	var rz := Datos.rareza(Datos.personaje(base_id).get("rareza", "comun"))
	var horas := int(rz["espera_h"])
	estado_nodo(nodo_id)["reaparece"] = ahora() + horas * 3600
	guardar()
	return horas


# =====================================================================
# Tareas reales
# =====================================================================

func tarea(id: String) -> Dictionary:
	for t in d["tareas"]:
		if t["id"] == id:
			return t
	return {}


func tarea_hecha_hoy(id: String) -> bool:
	return d["hoy"]["hechas"].has(id)


func agregar_tarea(nombre: String, categoria: String) -> void:
	var id := "u%d" % int(d["siguiente_tarea"])
	d["siguiente_tarea"] = int(d["siguiente_tarea"]) + 1
	d["tareas"].append({"id": id, "nombre": nombre, "categoria": categoria, "propia": true})
	guardar()


func borrar_tarea(id: String) -> void:
	for t in d["tareas"]:
		if t["id"] == id:
			d["tareas"].erase(t)
			break
	guardar()


func categorias_hechas_hoy() -> Array:
	var cats := []
	for id in d["hoy"]["hechas"]:
		var c: String = d["hoy"]["hechas"][id]
		if not c in cats:
			cats.append(c)
	return cats


func _actualizar_racha() -> void:
	var hoy := dia_local()
	var ultimo := int(d["ultimo_activo"])
	if ultimo == hoy:
		return
	if ultimo == hoy - 1:
		d["racha"] = int(d["racha"]) + 1
	elif ultimo == hoy - 2 and int(d["gracia_semana"]) != semana_local():
		d["racha"] = int(d["racha"]) + 1
		d["gracia_semana"] = semana_local()
	else:
		d["racha"] = 1
	d["ultimo_activo"] = hoy


func _ganar_xp_tarea(xp: int) -> Dictionary:
	var tope := int(Datos.reglas["tareas"]["xp_tope_diario"])
	var real: int = clamp(tope - int(d["hoy"]["xp"]), 0, xp)
	d["hoy"]["xp"] = int(d["hoy"]["xp"]) + real
	var sub := ganar_xp_prota(real)
	return {"xp": real, "subidas": sub}


## Registra una tarea real completada. Devuelve una lista de mensajes.
func registrar_tarea(id: String) -> Array:
	revisar_dia()
	var msgs := []
	var t := tarea(id)
	if t.is_empty() or tarea_hecha_hoy(id):
		return msgs
	var cat: String = t["categoria"]
	d["hoy"]["hechas"][id] = cat
	d["totales"][cat] = int(d["totales"].get(cat, 0)) + 1
	_actualizar_racha()
	# Bonus según categoría
	var b: Dictionary = Datos.reglas["bonus_tarea"][cat]
	for k in b:
		match k:
			"hp", "atk", "def":
				d["bonus"][k] = float(d["bonus"][k]) + float(b[k])
			"maestria":
				d["bonus"]["maestria"] = int(d["bonus"]["maestria"]) + int(b[k])
			"fama":
				d["fama"] = int(d["fama"]) + int(b[k])
			"energia":
				sumar_energia(int(b[k]))
	if cat == "practica":
		d["hoy"]["practicas"] = int(d["hoy"]["practicas"]) + 1
	msgs.append("%s: %s" % [t["nombre"], Datos.tareas["categorias"][cat]["efecto"]])
	var gx := _ganar_xp_tarea(int(Datos.reglas["tareas"]["xp_por_tarea"]))
	if int(gx["xp"]) > 0:
		msgs.append("+%d XP" % int(gx["xp"]))
	else:
		msgs.append("Tope diario de XP por tareas alcanzado (las demás recompensas sí cuentan).")
	if int(gx["subidas"]) > 0:
		msgs.append("¡Subes a nivel %d!" % int(d["nivel"]))
	# Cadenas
	var rt: Dictionary = Datos.reglas["tareas"]
	if not bool(d["hoy"]["cadena_corta"]) and d["hoy"]["hechas"].size() >= int(rt["cadena_corta"]):
		d["hoy"]["cadena_corta"] = true
		sumar_energia(int(rt["energia_cadena_corta"]))
		msgs.append("¡Cadena de %d tareas! +%d energía" % [int(rt["cadena_corta"]), int(rt["energia_cadena_corta"])])
	if not bool(d["hoy"]["cadena_completa"]) and categorias_hechas_hoy().size() >= Datos.tareas["categorias"].size():
		d["hoy"]["cadena_completa"] = true
		sumar_energia(int(rt["energia_cadena_completa"]))
		d["pua"] = int(d["pua"]) + int(rt["pua_cadena_completa"])
		msgs.append("¡Cadena completa! +%d energía y +1 Púa Espectral" % int(rt["energia_cadena_completa"]))
	guardar()
	return msgs


## Ejercicio extra: suma al acumulado y reduce 1 minuto el estado Desafinados.
func registrar_ejercicio_extra() -> String:
	revisar_dia()
	d["totales"]["ejercicio"] = int(d["totales"]["ejercicio"]) + 1
	_actualizar_racha()
	var msg := "Ejercicio extra registrado (+1 al acumulado de ejercicio)."
	if esta_desafinado():
		d["desafinado_hasta"] = int(d["desafinado_hasta"]) - int(Datos.reglas["desafinado_resta_ejercicio"])
		msg += " Desafinados: −1 minuto."
	guardar()
	return msg


# =====================================================================
# Sala de Ensayo
# =====================================================================

func segundos_ensayo_rapido() -> int:
	return max(0, int(d["ensayo_rapido_listo"]) - ahora())


func ensayo(tipo: String) -> String:
	var r: Dictionary = Datos.reglas["ensayo"][tipo]
	match tipo:
		"rapido":
			if segundos_ensayo_rapido() > 0:
				return "El ensayo rápido estará listo en " + formato_tiempo(segundos_ensayo_rapido())
			d["ensayo_rapido_listo"] = ahora() + int(r["espera_seg"])
		"completo":
			if int(d["energia"]) < int(r["costo_energia"]):
				return "No tienes energía suficiente."
			d["energia"] = int(d["energia"]) - int(r["costo_energia"])
		"real":
			if int(d["hoy"]["practicas"]) <= 0:
				return "Registra hoy una práctica real de instrumento para hacer un Ensayo real."
			d["hoy"]["practicas"] = int(d["hoy"]["practicas"]) - 1
			d["en_sintonia"] = true
	curar_equipo(float(r["cura"]))
	sumar_quimica_equipo(int(r["quimica"]))
	# Los seguidores en reserva también aprenden un poco
	for s in d["seguidores"]:
		if not s["uid"] in d["equipo"]:
			ganar_xp_seguidor(s, 5)
	guardar()
	var txt := "El equipo recupera %d%% de vida y gana +%d de química." % [int(float(r["cura"]) * 100), int(r["quimica"])]
	if tipo == "real":
		txt += " ¡En sintonía! +5% de daño en el próximo combate."
	return txt
