extends "res://scripts/pantallas/pantalla.gd"
## Mapa de una zona: combates, sublíderes, líder, jefe y secretos.

const BASE := Vector2(1280, 720)

var zona: Dictionary
var botones := {}
var lienzo: Control  # nodos y caminos sobre el arte del mapa (coordenadas 1280×720)


func _ready() -> void:
	zona = Datos.zona(params.get("zona", "cotoca"))
	lienzo = UI.lienzo(self, Datos.textura("mapas", zona.get("mapa", "")))
	for n in zona["nodos"]:
		_crear_boton(n)

	var m := UI.margen(self, 20)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	v.add_child(UI.encabezado(zona["nombre"], volver_centro))
	var info := UI.panel()
	info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(info)
	var restantes := Estado.enemigos_restantes_antes_del_jefe(zona)
	var txt := "Enemigos por vencer antes del jefe: %d" % restantes
	if Estado.nodo_vencido(zona["jefe_nodo"]):
		txt = "¡Zona liberada! Puedes volver a combatir para entrenar y despertar seguidores."
	var iv := VBoxContainer.new()
	info.add_child(iv)
	iv.add_child(UI.etiqueta("Banda: %s" % zona["banda"], 22, UI.ORO))
	iv.add_child(UI.etiqueta("%s\nEnergía: %d   ·   Púas: %d" % [txt, int(Estado.d["energia"]), int(Estado.d["pua"])], 20))
	var ident: Dictionary = zona.get("identidad", {})
	if not ident.is_empty():
		var fi := HBoxContainer.new()
		fi.add_theme_constant_override("separation", 6)
		fi.add_child(UI.etiqueta("Sonido de la zona:", 18, UI.TENUE))
		for par in [["dominante", "dominante"], ["secundario", "secundario"], ["unico", "único"]]:
			if ident.has(par[0]):
				fi.add_child(UI.icono_tipo(ident[par[0]], 28))
				fi.add_child(UI.etiqueta(par[1] + "  ", 16, Datos.color_familia(ident[par[0]])))
		iv.add_child(fi)


## Punto del mapa: ícono de estado sobre el marcador del arte y etiqueta corta debajo.
func _crear_boton(n: Dictionary) -> void:
	var en := Estado.estado_nodo(n["id"])
	var bloqueo := Estado.bloqueo_nodo(n)
	var secreto: bool = n["tipo"] == "secreto"
	var estado := "bloqueado" if bloqueo != "" else ("vencido" if bool(en["vencido"]) else "desbloqueado")
	var espera := Estado.segundos_reaparece(n["id"])
	var tipos := {"sublider": "SUBLÍDER · ", "lider": "LÍDER · ", "jefe": "JEFE · ", "secreto": ""}
	var txt: String = "???" if secreto and bloqueo != "" else tipos.get(n["tipo"], "") + String(n.get("corto", n["nombre"])).to_upper()
	txt += "  NV %d" % int(n["nivel"])
	if espera > 0:
		txt += "\nREAPARECE EN " + Estado.formato_tiempo(espera)
	botones[n["id"]] = UI.marcador(lienzo, Vector2(n["pos"][0], n["pos"][1]), estado, txt, _abrir.bind(n), espera > 0)


func _abrir(n: Dictionary) -> void:
	var capa := UI.capa_modal(self)
	var v := UI.centrado(capa, 860)
	var bloqueo := Estado.bloqueo_nodo(n)
	var tipos := {"normal": "Combate", "sublider": "Sublíder", "lider": "Líder de banda", "jefe": "Jefe territorial", "secreto": "Zona secreta"}
	v.add_child(UI.etiqueta("%s · %s · Nivel %d" % [n["nombre"] if (n["tipo"] != "secreto" or bloqueo == "") else "???", tipos[n["tipo"]], int(n["nivel"])], 28, UI.ORO))
	if bloqueo != "":
		v.add_child(UI.etiqueta(bloqueo, 22, Color("#ff9a9a"), true))
	else:
		var info := Estado.enemigos_de_nodo(zona, n)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		for id in info["ids"]:
			var p := Datos.personaje(id)
			var c := VBoxContainer.new()
			var im := UI.imagen(Datos.sprite(p.get("imagen", id), false), Vector2(120, 120))
			UI.marcar_tipo(im, Datos.familia_de(id), 30)
			c.add_child(im)
			var rz := Datos.rareza(p.get("rareza", "comun"))
			c.add_child(UI.etiqueta(p.get("nombre", id), 16, Color(rz["color"])))
			c.add_child(UI.etiqueta("%s · %s" % [Datos.clases[p["clase"]]["nombre"], Datos.nombre_familia(Datos.familia_de(id))], 14, Datos.color_familia(Datos.familia_de(id))))
			h.add_child(c)
		v.add_child(h)
		if bool(info["aleatorio"]):
			v.add_child(UI.etiqueta("Su enemigo principal ya está en tu legión: ahora aparecen músicos aleatorios de la zona.", 18, UI.TENUE, true))
		else:
			var nombres := []
			for did in Estado.despertables_disponibles(info["despertable"]):
				var pd := Datos.personaje(did)
				nombres.append("%s (%s)" % [pd["nombre"], Datos.rareza(pd["rareza"])["nombre"]])
			if not nombres.is_empty():
				var pre := "Despertable: " if nombres.size() == 1 else "Despertables (eliges uno): "
				v.add_child(UI.etiqueta(pre + " o ".join(nombres), 20, UI.ESPECTRAL, true))
			elif not Estado.lista_despertables(info["despertable"]).is_empty():
				v.add_child(UI.etiqueta("Ya despertaste a este rival: puedes volver a pelear, pero no se despierta de nuevo.", 18, UI.TENUE, true))
		v.add_child(UI.etiqueta("Costo: %d de energía (tienes %d)" % [Estado.costo_nodo(n), int(Estado.d["energia"])], 20))
	var h2 := HBoxContainer.new()
	h2.add_theme_constant_override("separation", 14)
	h2.add_child(UI.boton("Cerrar", func(): capa.queue_free(), Vector2(200, 64)))
	var motivo := _motivo_no_combatir(n, bloqueo)
	var bc := UI.boton("¡Combatir!", func():
		capa.queue_free()
		_combatir(n), Vector2(260, 64))
	bc.disabled = motivo != ""
	h2.add_child(bc)
	v.add_child(h2)
	if motivo != "" and bloqueo == "":
		v.add_child(UI.etiqueta(motivo, 20, Color("#ff9a9a"), true))


func _motivo_no_combatir(n: Dictionary, bloqueo: String) -> String:
	if bloqueo != "":
		return bloqueo
	if Estado.esta_desafinado():
		return "Tu equipo está Desafinado: espera %s o registra ejercicios extra." % Estado.formato_tiempo(Estado.segundos_desafinado())
	var r := Estado.segundos_reaparece(n["id"])
	if r > 0:
		return "El enemigo se desvaneció. Reaparece en %s." % Estado.formato_tiempo(r)
	if int(Estado.d["energia"]) < Estado.costo_nodo(n):
		return "No tienes energía suficiente. Completa tareas reales para recargarla."
	return ""


func _combatir(n: Dictionary) -> void:
	UI.dialogo(self, n.get("dialogo_antes", []), func():
		Estado.d["energia"] = int(Estado.d["energia"]) - Estado.costo_nodo(n)
		Estado.guardar()
		Estado.ir("combate", {"zona": zona["id"], "nodo": n["id"]}))
