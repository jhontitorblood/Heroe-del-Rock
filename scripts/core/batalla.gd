extends RefCounted
## Motor de combate por turnos (sin interfaz). Una acción por combatiente en cada ronda,
## orden por velocidad, afinidades de género, sinergias en ataques conjuntos,
## definitivas individuales y de banda, estados y resurrección.

const ALIADO := 0
const ENEMIGO := 1


class Unidad:
	var uid: String
	var base_id: String
	var nombre: String
	var clase: String
	var genero: String
	var rareza: String
	var imagen: String
	var espectral: bool = false
	var mira_izquierda: bool = false  # el dibujo original mira a la izquierda
	var lado: int
	var nivel: int
	var hp_max: int
	var hp: int
	var atk: float
	var def: float
	var spd: float
	var poder_extra: float = 0.0
	var habilidades: Array = []
	var definitiva: String = ""
	var enfriamientos: Dictionary = {}
	var estados: Array = []  # [{tipo, valor, turnos}]
	var escudo: float = 0.0
	var medidor: float = 0.0
	var revivido: bool = false

	func vivo() -> bool:
		return hp > 0

	## Si hay que voltear el dibujo para que mire hacia el bando rival.
	func voltear() -> bool:
		# Aliados miran a la derecha y enemigos a la izquierda
		return (lado == 1) != mira_izquierda

	func tiene(tipo: String) -> bool:
		for e in estados:
			if e["tipo"] == tipo:
				return true
		return false

	func mod(tipo: String) -> float:
		var t := 0.0
		for e in estados:
			if e["tipo"] == tipo:
				t += float(e.get("valor", 0.0))
		return t

	func vel() -> float:
		return spd * (1.0 + mod("mejora_spd"))

	func texto_estados() -> String:
		var partes := []
		var nombres := {"aturdir": "Aturdido", "provocar": "Provoca", "mejora_atk": "Atk+", "mejora_spd": "Vel+",
			"debil_atk": "Atk-", "debil_def": "Def-", "dot": "Quemado"}
		for e in estados:
			if not nombres.has(e["tipo"]):
				continue
			var n: String = nombres[e["tipo"]]
			if not n in partes:
				partes.append(n)
		if escudo > 0:
			partes.append("Escudo %d" % int(escudo))
		return " · ".join(partes)


var unidades: Array = []
var cola: Array = []
var ronda: int = 0
var actual: Unidad = null
var golpes_ronda: Dictionary = {}  # uid objetivo -> uid del último aliado que lo golpeó esta ronda
var medidor_banda: float = 0.0
var bonus_dano_aliados: float = 0.0
var quimica: Dictionary = {}  # "a|b" -> puntos
var adelantados: Array = []


# ---------------------------------------------------------------------
# Preparación
# ---------------------------------------------------------------------

## datos: {uid, base_id, nivel, hp_frac?, nombre?, bonus?, espectral?, fuerza?, fuerza_hp?}
func agregar(datos: Dictionary, lado: int) -> Unidad:
	var u := Unidad.new()
	var p: Dictionary = Datos.personaje(datos["base_id"])
	var st := Datos.stats(datos["base_id"], int(datos["nivel"]))
	u.uid = datos["uid"]
	u.base_id = datos["base_id"]
	u.nombre = datos.get("nombre", p.get("nombre", "?"))
	u.clase = p.get("clase", "guitarrista")
	u.genero = p.get("genero", "raiz")
	u.rareza = p.get("rareza", "comun")
	u.imagen = p.get("imagen", datos["base_id"])
	u.espectral = bool(datos.get("espectral", false))
	u.mira_izquierda = p.get("mira", "derecha") == "izquierda"
	u.lado = lado
	u.nivel = int(datos["nivel"])
	var fuerza := float(datos.get("fuerza", 1.0))
	var fuerza_hp := float(datos.get("fuerza_hp", 1.0))
	var bonus: Dictionary = datos.get("bonus", {})
	u.hp_max = int((st["hp"] + float(bonus.get("hp", 0.0))) * fuerza * fuerza_hp)
	u.atk = (st["atk"] + float(bonus.get("atk", 0.0))) * fuerza
	u.def = (st["def"] + float(bonus.get("def", 0.0))) * fuerza
	u.spd = st["spd"]
	u.poder_extra = int(bonus.get("maestria", 0)) * 0.005
	u.hp = max(1, int(round(u.hp_max * float(datos.get("hp_frac", 1.0)))))
	u.habilidades = Datos.habilidades_de(datos["base_id"])
	u.definitiva = Datos.definitiva_de(datos["base_id"])
	unidades.append(u)
	return u


func lado(l: int, solo_vivos := true) -> Array:
	var r := []
	for u in unidades:
		if u.lado == l and (u.vivo() or not solo_vivos):
			r.append(u)
	return r


func caidos(l: int) -> Array:
	var r := []
	for u in unidades:
		if u.lado == l and not u.vivo() and not u.revivido:
			r.append(u)
	return r


func por_uid(uid: String) -> Unidad:
	for u in unidades:
		if u.uid == uid:
			return u
	return null


# ---------------------------------------------------------------------
# Turnos
# ---------------------------------------------------------------------

func _nueva_ronda() -> void:
	ronda += 1
	golpes_ronda.clear()
	cola = []
	for u in unidades:
		if u.vivo():
			cola.append(u)
	cola.sort_custom(func(a, b): return a.vel() > b.vel())


## Avanza al siguiente combatiente. Devuelve eventos de inicio de turno
## (daño continuo, aturdido). Si el actual queda sin turno, se vuelve a llamar.
func siguiente_turno() -> Array:
	var eventos := []
	if resultado() != "":
		return eventos
	var u: Unidad = null
	if not adelantados.is_empty():
		u = adelantados.pop_front()
		cola.erase(u)
	else:
		while u == null:
			if cola.is_empty():
				_nueva_ronda()
				eventos.append({"t": "ronda", "valor": ronda})
			var c: Unidad = cola.pop_front()
			if c != null and c.vivo():
				u = c
	actual = u
	# Enfriamientos
	for k in u.enfriamientos.keys():
		u.enfriamientos[k] = max(0, int(u.enfriamientos[k]) - 1)
	# Daño continuo
	var dot := 0.0
	for e in u.estados:
		if e["tipo"] == "dot":
			dot += float(e["valor"]) * u.hp_max
	if dot > 0:
		var dmg := int(max(1.0, dot))
		u.hp = max(0, u.hp - dmg)
		eventos.append({"t": "dano", "obj": u.uid, "valor": dmg, "nota": "Quemadura"})
		if not u.vivo():
			u.estados.clear()
			eventos.append({"t": "cae", "obj": u.uid})
	# Duración de estados
	var aturdido := u.tiene("aturdir")
	var restantes := []
	for e in u.estados:
		if e["tipo"] == "aturdir":
			continue
		e["turnos"] = int(e["turnos"]) - 1
		if int(e["turnos"]) > 0:
			restantes.append(e)
	u.estados = restantes
	if u.vivo() and u.escudo > 0 and not _tiene_escudo_activo(u):
		u.escudo = 0.0
	if not u.vivo():
		eventos.append({"t": "salta", "obj": u.uid})
		return eventos
	if aturdido:
		eventos.append({"t": "aturdido", "obj": u.uid})
	return eventos


func _tiene_escudo_activo(u: Unidad) -> bool:
	return u.tiene("escudo_t")


func resultado() -> String:
	if lado(ENEMIGO).is_empty():
		return "victoria"
	if lado(ALIADO).is_empty():
		return "derrota"
	return ""


# ---------------------------------------------------------------------
# Habilidades
# ---------------------------------------------------------------------

func hab(id: String) -> Dictionary:
	return Datos.habilidades.get(id, {})


func banda_disponible(u: Unidad) -> bool:
	return u.lado == ALIADO and medidor_banda >= 100.0 and lado(ALIADO).size() >= 3


## Lista de habilidades del combatiente con disponibilidad.
func opciones(u: Unidad) -> Array:
	var r := []
	for id in u.habilidades:
		var h := hab(id)
		var cd := int(u.enfriamientos.get(id, 0))
		var ok := cd == 0
		if h.get("objetivo", "") == "aliado_caido" and caidos(u.lado).is_empty():
			ok = false
		r.append({"id": id, "h": h, "ok": ok, "cd": cd})
	if u.definitiva != "":
		r.append({"id": u.definitiva, "h": hab(u.definitiva), "ok": u.medidor >= 100.0, "cd": 0, "definitiva": true})
	if u.lado == ALIADO:
		r.append({"id": "banda", "h": hab("banda"), "ok": banda_disponible(u), "cd": 0, "banda": true})
	return r


func necesita_objetivo(id: String) -> bool:
	return hab(id).get("objetivo", "") in ["enemigo", "aliado", "aliado_caido"]


func objetivos_validos(u: Unidad, id: String) -> Array:
	var h := hab(id)
	var rival := ENEMIGO if u.lado == ALIADO else ALIADO
	match h.get("objetivo", ""):
		"enemigo":
			var vivos := lado(rival)
			var prov := vivos.filter(func(x): return x.tiene("provocar"))
			return prov if not prov.is_empty() else vivos
		"enemigos":
			return lado(rival)
		"aliado":
			return lado(u.lado)
		"aliados":
			return lado(u.lado)
		"propio":
			return [u]
		"aliado_caido":
			return caidos(u.lado)
	return []


func _calcular_dano(u: Unidad, t: Unidad, poder: float, eventos: Array) -> int:
	var atk: float = u.atk * maxf(0.2, 1.0 + u.mod("mejora_atk") - u.mod("debil_atk"))
	var defe: float = t.def * maxf(0.2, 1.0 - t.mod("debil_def"))
	var base := atk * poder * (1.0 + u.poder_extra) * (60.0 / (60.0 + defe * 2.0))
	var notas := []
	var af := Datos.multiplicador_afinidad(u.genero, t.genero)
	if af > 1.0:
		notas.append("Ventaja")
	elif af < 1.0:
		notas.append("Desventaja")
	var mult := af
	# Furia del público: a partir de la ronda 8 todo golpe pega más fuerte (evita combates eternos)
	if ronda > 8:
		mult += 0.2 * (ronda - 8)
		notas.append("Furia del público")
	if u.lado == ALIADO:
		mult += bonus_dano_aliados
		# Sinergia: otro aliado ya golpeó a este objetivo en la ronda
		var previo: String = golpes_ronda.get(t.uid, "")
		if previo != "" and previo != u.uid:
			var p := por_uid(previo)
			if p != null:
				var s := Datos.sinergia_generos(u.genero, p.genero)
				var q: int = min(int(Datos.generos["sinergia"]["quimica_max"]), int(quimica.get(_par(u.uid, p.uid), 0)))
				s += q / 100.0
				mult += s
				notas.append("Sinergia %+d%%" % int(round(s * 100)))
				if s > 0:
					medidor_banda = min(100.0, medidor_banda + 10.0)
		golpes_ronda[t.uid] = u.uid
	var dmg := int(max(1.0, base * mult * randf_range(0.92, 1.08)))
	return _aplicar_dano(t, dmg, ", ".join(notas), eventos)


func _par(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func _aplicar_dano(t: Unidad, dmg: int, nota: String, eventos: Array) -> int:
	var absorbido := 0
	if t.escudo > 0:
		absorbido = int(min(t.escudo, dmg))
		t.escudo -= absorbido
		dmg -= absorbido
	t.hp = max(0, t.hp - dmg)
	t.medidor = min(100.0, t.medidor + 10.0)
	var n := nota
	if absorbido > 0:
		n = (n + ", " if n != "" else "") + "Escudo -%d" % absorbido
	eventos.append({"t": "dano", "obj": t.uid, "valor": dmg, "nota": n})
	if not t.vivo():
		t.estados.clear()
		t.escudo = 0.0
		eventos.append({"t": "cae", "obj": t.uid})
	return dmg


func _curar(t: Unidad, cant: int, eventos: Array) -> void:
	if not t.vivo():
		return
	var antes := t.hp
	t.hp = min(t.hp_max, t.hp + cant)
	eventos.append({"t": "cura", "obj": t.uid, "valor": t.hp - antes})


## Ejecuta una habilidad. Devuelve la lista de eventos para mostrar.
func ejecutar(u: Unidad, id: String, objetivo: Unidad = null) -> Array:
	var eventos := []
	var h := hab(id)
	var es_banda := bool(h.get("banda", false))
	eventos.append({"t": "accion", "obj": u.uid, "nombre": h.get("nombre", id), "id": id})
	# Costos
	if es_banda:
		medidor_banda = 0.0
	elif bool(h.get("definitiva", false)):
		u.medidor = 0.0
	else:
		u.medidor = min(100.0, u.medidor + 20.0)
		if int(h.get("enfriamiento", 0)) > 0:
			u.enfriamientos[id] = int(h["enfriamiento"])
	if u.lado == ALIADO and not es_banda:
		medidor_banda = min(100.0, medidor_banda + 8.0)
	# Objetivos
	var objs := []
	match h.get("objetivo", ""):
		"enemigo", "aliado", "aliado_caido":
			if objetivo == null:
				var v := objetivos_validos(u, id)
				if v.is_empty():
					return eventos
				objetivo = v[0]
			objs = [objetivo]
		_:
			objs = objetivos_validos(u, id)
	# Daño
	var poder := float(h.get("poder", 0.0))
	if poder > 0 and h.get("objetivo", "") in ["enemigo", "enemigos"]:
		var atacante := u
		if es_banda:
			# La banda usa el ataque promedio del equipo
			var suma := 0.0
			var aliados := lado(ALIADO)
			for a in aliados:
				suma += a.atk
			var tmp := Unidad.new()
			tmp.uid = u.uid
			tmp.lado = u.lado
			tmp.genero = u.genero
			tmp.atk = suma / max(1, aliados.size())
			atacante = tmp
		for t in objs:
			if t.vivo():
				_calcular_dano(atacante, t, poder, eventos)
	# Efectos
	for e in h.get("efectos", []):
		var a: String = e.get("a", "objetivo")
		var dest := []
		match a:
			"propio":
				dest = [u]
			"aliados":
				dest = lado(u.lado)
			"enemigos":
				dest = lado(ENEMIGO if u.lado == ALIADO else ALIADO)
			_:
				dest = objs
		for t in dest:
			_efecto(u, t, e, eventos)
	return eventos


func _efecto(u: Unidad, t: Unidad, e: Dictionary, eventos: Array) -> void:
	var tipo: String = e["tipo"]
	match tipo:
		"curar":
			_curar(t, int(t.hp_max * float(e["valor"])), eventos)
		"escudo":
			if t.vivo():
				t.escudo = max(t.escudo, (u.hp_max * 0.5 + t.hp_max * 0.5) * float(e["valor"]) * 0.6)
				t.estados.append({"tipo": "escudo_t", "valor": 0, "turnos": int(e.get("turnos", 2)) + 1})
				eventos.append({"t": "estado", "obj": t.uid, "texto": "Escudo"})
		"revivir":
			if not t.vivo() and not t.revivido:
				t.hp = max(1, int(t.hp_max * float(e["valor"])))
				t.revivido = true
				eventos.append({"t": "revive", "obj": t.uid})
		"revivir_todos":
			for c in caidos(u.lado):
				c.hp = max(1, int(c.hp_max * float(e["valor"])))
				c.revivido = true
				eventos.append({"t": "revive", "obj": c.uid})
		"aturdir":
			if t.vivo() and randf() < float(e.get("prob", 1.0)):
				if not t.tiene("aturdir"):
					t.estados.append({"tipo": "aturdir", "valor": 0, "turnos": 1})
				eventos.append({"t": "estado", "obj": t.uid, "texto": "¡Aturdido!"})
		"adelantar":
			if t.vivo() and t != u and not t in adelantados:
				adelantados.append(t)
				eventos.append({"t": "estado", "obj": t.uid, "texto": "¡Actúa ya!"})
		"mejora_atk", "mejora_spd", "debil_atk", "debil_def", "dot", "provocar":
			if t.vivo():
				t.estados.append({"tipo": tipo, "valor": float(e.get("valor", 0.0)), "turnos": int(e.get("turnos", 2)) + (1 if t == u else 0)})
				var textos := {"mejora_atk": "Ataque +", "mejora_spd": "Velocidad +", "debil_atk": "Ataque -", "debil_def": "Defensa -", "dot": "Quemado", "provocar": "Provoca"}
				eventos.append({"t": "estado", "obj": t.uid, "texto": textos[tipo]})


# ---------------------------------------------------------------------
# Inteligencia de los enemigos (y auto-combate de pruebas)
# ---------------------------------------------------------------------

func ia_elegir(u: Unidad) -> Dictionary:
	var ops := opciones(u).filter(func(o): return o["ok"])
	var mios := lado(u.lado)
	var rivales := lado(ENEMIGO if u.lado == ALIADO else ALIADO)
	# 1) Banda o definitiva si está lista
	for o in ops:
		if o.get("banda", false) or o.get("definitiva", false):
			return {"id": o["id"], "obj": _mejor_objetivo(u, o["id"])}
	# 2) Revivir
	for o in ops:
		if o["h"].get("objetivo", "") == "aliado_caido":
			return {"id": o["id"], "obj": caidos(u.lado)[0]}
	# 3) Curar si alguien está bajo
	var herido: Unidad = null
	for m in mios:
		if float(m.hp) / m.hp_max < 0.5 and (herido == null or m.hp < herido.hp):
			herido = m
	if herido != null:
		for o in ops:
			for e in o["h"].get("efectos", []):
				if e["tipo"] == "curar" and o["h"].get("poder", 0) == 0:
					if o["h"]["objetivo"] == "propio" and herido != u:
						continue
					return {"id": o["id"], "obj": herido}
	# 4) Habilidades de apoyo de vez en cuando
	var apoyo := ops.filter(func(o): return o["h"].get("poder", 0) == 0 and o["h"].get("objetivo", "") in ["aliados", "propio", "aliado"] and not _solo_cura(o["h"]))
	if not apoyo.is_empty() and randf() < 0.35:
		var o = apoyo[randi() % apoyo.size()]
		return {"id": o["id"], "obj": _mejor_objetivo(u, o["id"])}
	# 5) Ataque: la habilidad ofensiva más fuerte disponible
	var ataque := ops.filter(func(o): return o["h"].get("poder", 0) > 0 and not o.get("banda", false))
	if not ataque.is_empty():
		ataque.sort_custom(func(a, b): return _valor_ataque(a["h"], rivales.size()) > _valor_ataque(b["h"], rivales.size()))
		var elegido = ataque[0] if randf() < 0.75 else ataque[randi() % ataque.size()]
		return {"id": elegido["id"], "obj": _mejor_objetivo(u, elegido["id"])}
	var o2 = ops[0]
	return {"id": o2["id"], "obj": _mejor_objetivo(u, o2["id"])}


func _solo_cura(h: Dictionary) -> bool:
	for e in h.get("efectos", []):
		if e["tipo"] != "curar":
			return false
	return true


func _valor_ataque(h: Dictionary, n: int) -> float:
	var p := float(h.get("poder", 0))
	if h.get("objetivo", "") == "enemigos":
		p *= n * 0.8
	return p + 0.2 * h.get("efectos", []).size()


func _mejor_objetivo(u: Unidad, id: String) -> Unidad:
	var v := objetivos_validos(u, id)
	if v.is_empty():
		return null
	var h := hab(id)
	if h.get("objetivo", "") == "enemigo":
		# Prefiere al más débil o al que tiene desventaja
		var mejor: Unidad = null
		var mejor_p := -999.0
		for t in v:
			var p := _puntaje(u, t)
			if p > mejor_p:
				mejor_p = p
				mejor = t
		return mejor
	if h.get("objetivo", "") == "aliado":
		v.sort_custom(func(a, b): return float(a.hp) / a.hp_max < float(b.hp) / b.hp_max)
		return v[0]
	return v[0]


func _puntaje(u: Unidad, t: Unidad) -> float:
	return (1.0 - float(t.hp) / t.hp_max) + (Datos.multiplicador_afinidad(u.genero, t.genero) - 1.0) * 2.0 + randf() * 0.3


# ---------------------------------------------------------------------
# Orden de turnos (para la barra superior)
# ---------------------------------------------------------------------

## Próximos combatientes: [[unidad, es_ronda_siguiente], ...]
func orden_proximo(cant: int) -> Array:
	var r := []
	var vistos := []
	if actual != null and actual.vivo():
		r.append([actual, false])
		vistos.append(actual)
	for u in adelantados + cola:
		if u.vivo() and not u in vistos:
			r.append([u, false])
			vistos.append(u)
	var sig := unidades.filter(func(x): return x.vivo())
	sig.sort_custom(func(a, b): return a.vel() > b.vel())
	while r.size() < cant and not sig.is_empty():
		for u in sig:
			r.append([u, true])
			if r.size() >= cant:
				break
	return r.slice(0, cant)
