extends Node
## Simula combates (IA contra IA) para revisar el balance de Cotoca.
## Uso: godot --headless --path . res://tests/prueba_balance.tscn

const Batalla = preload("res://scripts/core/batalla.gd")

# [nodo, nivel prota, [seguidores base_id:nivel]]
var casos := [
	["c1", 1, []],
	["c2", 2, [["e_cuerdero", 1]]],
	["c3", 3, [["e_cantor", 2]]],
	["c4", 4, [["e_bajista", 3]]],
	["c5", 5, [["s_brisa", 4]]],
	["c6", 6, [["s_brisa", 5]]],
	["c7", 7, [["s_lazaro", 6]]],
	["c8", 7, [["l_aruma", 7], ["s_lazaro", 6]]],
	["c8", 6, [["l_aruma", 7], ["s_brisa", 5]]],
	["cs", 6, [["s_brisa", 5]]],
]

func _ready() -> void:
	var zona := Datos.zona("cotoca")
	for c in casos:
		var n := Datos.nodo("cotoca", c[0])
		var gan := 0
		var rondas := 0
		var hp_rest := 0.0
		var N := 300
		for i in N:
			var b := Batalla.new()
			b.agregar({"uid": "prota", "base_id": "protagonista_m", "nivel": c[1], "bonus": {"hp": 8, "atk": 0.6, "def": 0.3, "maestria": 2}}, 0)
			var k := 0
			for s in c[2]:
				b.agregar({"uid": "a%d" % k, "base_id": s[0], "nivel": s[1]}, 0)
				k += 1
			var j := 0
			for e in n["enemigos"]:
				b.agregar({"uid": "e%d" % j, "base_id": e, "nivel": n["nivel"], "fuerza": n.get("fuerza", 1.0), "fuerza_hp": n.get("fuerza_hp", 1.0)}, 1)
				j += 1
			var pasos := 0
			while b.resultado() == "" and pasos < 400:
				var ev := b.siguiente_turno()
				var aturd := false
				for x in ev:
					if x["t"] in ["aturdido", "salta"]:
						aturd = true
				if b.resultado() != "" or aturd:
					pasos += 1
					continue
				var u = b.actual
				var el := b.ia_elegir(u)
				b.ejecutar(u, el["id"], el["obj"])
				pasos += 1
			if b.resultado() == "victoria":
				gan += 1
				var t := 0.0
				for a in b.lado(0, false):
					t += float(a.hp) / a.hp_max
				hp_rest += t / b.lado(0, false).size()
			rondas += b.ronda
		print("%s %-28s prota nv%d  gana %3d%%  rondas %.1f  vida restante %.0f%%" % [c[0], n["nombre"], c[1], gan * 100 / N, float(rondas) / N, 100.0 * hp_rest / max(1, gan)])
	get_tree().quit()
