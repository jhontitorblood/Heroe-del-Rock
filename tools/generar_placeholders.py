#!/usr/bin/env python3
"""Genera el arte PROVISIONAL de Héroe del Rock con los nombres y medidas definitivos.

Uso:  python3 tools/generar_placeholders.py
Para poner arte final, reemplaza cada PNG por otro con el MISMO nombre y medida.
No sobrescribe imágenes que ya no sean provisionales (busca la marca en sus metadatos).
"""
import json
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from PIL.PngImagePlugin import PngInfo

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(RAIZ, "assets")
FUENTE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MARCA = "heroe-del-rock-provisional"


def fuente(t):
    try:
        return ImageFont.truetype(FUENTE, t)
    except OSError:
        return ImageFont.load_default()


def guardar(img, carpeta, nombre):
    ruta = os.path.join(ASSETS, carpeta, nombre + ".png")
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    if os.path.exists(ruta):
        try:
            if Image.open(ruta).info.get("origen") != MARCA:
                print("  (se conserva arte final)", ruta)
                return
        except Exception:
            pass
    meta = PngInfo()
    meta.add_text("origen", MARCA)
    img.save(ruta, pnginfo=meta)


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def silueta(color, instrumento, semilla, femenino=False, monstruo=False, tam=256, brazo=None):
    """Figura con fondo transparente (256x256 por defecto). brazo=0..1 levanta la mano con la señal de rock."""
    random.seed(semilla)
    s = 512  # se dibuja al doble y se reduce (bordes suaves)
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = color + (255,)
    oscuro = tuple(int(x * 0.45) for x in color) + (255,)
    if monstruo:
        # Serpiente de agua (Jichi)
        pts = []
        for i in range(60):
            t = i / 59
            x = 60 + t * 390
            y = 380 - math.sin(t * math.pi * 2.2) * 110 - t * 120
            pts.append((x, y))
        for i, (x, y) in enumerate(pts):
            r = 26 + 34 * (i / 59)
            d.ellipse([x - r, y - r, x + r, y + r], fill=c, outline=oscuro, width=6)
        hx, hy = pts[-1]
        d.ellipse([hx - 70, hy - 55, hx + 70, hy + 55], fill=c, outline=oscuro, width=8)
        d.ellipse([hx + 5, hy - 25, hx + 30, hy], fill=(255, 240, 120, 255))
        d.polygon([(hx - 40, hy - 50), (hx - 10, hy - 110), (hx + 10, hy - 50)], fill=oscuro)
    else:
        # Cuerpo
        d.rounded_rectangle([170, 210, 342, 420], 50, fill=c, outline=oscuro, width=8)
        if femenino:
            d.polygon([(170, 330), (342, 330), (380, 440), (132, 440)], fill=c, outline=oscuro)
        d.rectangle([190, 410, 235, 500], fill=oscuro)
        d.rectangle([277, 410, 322, 500], fill=oscuro)
        # Cabeza y pelo
        d.ellipse([196, 70, 316, 200], fill=(240, 205, 170, 255), outline=oscuro, width=6)
        pelo = tuple(int(x * 0.3) for x in color) + (255,)
        if femenino:
            d.pieslice([186, 58, 326, 210], 180, 360, fill=pelo)
            d.rectangle([186, 130, 210, 260], fill=pelo)
            d.rectangle([302, 130, 326, 260], fill=pelo)
        else:
            d.pieslice([190, 60, 322, 180], 180, 360, fill=pelo)
            for i in range(5):
                x = 200 + i * 26
                d.polygon([(x, 90), (x + 12, 20 + random.randint(0, 30)), (x + 24, 90)], fill=pelo)
        d.ellipse([228, 125, 242, 139], fill=(30, 20, 30, 255))
        d.ellipse([270, 125, 284, 139], fill=(30, 20, 30, 255))
        # Instrumento según la clase
        o = (40, 30, 40, 255)
        if instrumento in ("guitarrista", "bajista", "charanguista"):
            largo = {"guitarrista": 230, "bajista": 270, "charanguista": 170}[instrumento]
            cuerpo = {"guitarrista": 70, "bajista": 80, "charanguista": 50}[instrumento]
            d.line([(150, 380), (150 + largo, 380 - largo * 0.7)], fill=o, width=14)
            d.ellipse([150 - cuerpo, 380 - cuerpo * 0.7, 150 + cuerpo, 380 + cuerpo * 0.7], fill=(200, 60, 40, 255), outline=o, width=6)
        elif instrumento == "baterista":
            d.ellipse([120, 380, 392, 470], fill=(220, 220, 230, 255), outline=o, width=8)
            d.line([(150, 300), (110, 220)], fill=o, width=10)
            d.line([(362, 300), (402, 220)], fill=o, width=10)
        elif instrumento in ("vocalista", "corista"):
            d.line([(340, 230), (390, 120)], fill=o, width=10)
            d.ellipse([370, 90, 410, 135], fill=(160, 160, 170, 255), outline=o, width=5)
            if instrumento == "corista":
                d.ellipse([150, 20, 362, 60], outline=(255, 240, 160, 255), width=8)
        elif instrumento == "tecladista":
            d.rectangle([100, 330, 412, 390], fill=(30, 30, 40, 255), outline=o, width=6)
            for i in range(12):
                d.rectangle([110 + i * 25, 340, 128 + i * 25, 385], fill=(245, 245, 245, 255))
        elif instrumento == "ingeniero":
            d.arc([180, 60, 332, 200], 180, 360, fill=o, width=14)
            d.ellipse([168, 120, 204, 170], fill=o)
            d.ellipse([308, 120, 344, 170], fill=o)
            d.rectangle([110, 360, 220, 420], fill=(60, 60, 70, 255), outline=o, width=5)
        elif instrumento == "violinista":
            d.ellipse([300, 190, 380, 250], fill=(150, 80, 30, 255), outline=o, width=5)
            d.ellipse([310, 235, 400, 305], fill=(150, 80, 30, 255), outline=o, width=5)
            d.line([(330, 200), (250, 120)], fill=o, width=10)
            d.line([(200, 330), (420, 170)], fill=(220, 200, 160, 255), width=6)
        elif instrumento == "vientista":
            d.line([(270, 160), (420, 230)], fill=(170, 120, 60, 255), width=16)
            for i in range(4):
                d.ellipse([300 + i * 28, 168 + i * 13, 310 + i * 28, 178 + i * 13], fill=o)
    if brazo is not None:
        piel = (240, 205, 170, 255)
        hx = 380 + 30 * brazo
        hy = 330 - 190 * brazo
        d.line([(330, 250), (hx, hy)], fill=c, width=34)
        d.ellipse([hx - 26, hy - 26, hx + 26, hy + 26], fill=piel, outline=oscuro, width=4)
        if brazo > 0.6:
            # Índice y meñique arriba: la señal de rock
            d.rounded_rectangle([hx - 24, hy - 78, hx - 10, hy - 14], 6, fill=piel, outline=oscuro, width=3)
            d.rounded_rectangle([hx + 10, hy - 70, hx + 24, hy - 14], 6, fill=piel, outline=oscuro, width=3)
            for k in range(3):
                ang = random.uniform(0, math.tau)
                rx, ry = hx + math.cos(ang) * 95, hy - 40 + math.sin(ang) * 60
                d.line([(rx - 10, ry), (rx + 10, ry)], fill=(255, 210, 60, 255), width=5)
                d.line([(rx, ry - 10), (rx, ry + 10)], fill=(255, 210, 60, 255), width=5)
    im = im.resize((tam, tam), Image.LANCZOS)
    return im


def espectral(img):
    """Versión espectral: azul-cian, translúcida y con resplandor."""
    r, g, b, a = img.split()
    gris = Image.merge("RGB", (r, g, b)).convert("L")
    col = Image.merge("RGB", (gris.point(lambda x: int(x * 0.35)), gris.point(lambda x: min(255, int(90 + x * 0.65))), gris.point(lambda x: min(255, int(140 + x * 0.45)))))
    cuerpo = Image.merge("RGBA", (*col.split(), a.point(lambda x: int(x * 0.82))))
    brillo = Image.new("RGBA", img.size, (94, 242, 255, 0))
    brillo.putalpha(a.filter(ImageFilter.GaussianBlur(9)).point(lambda x: int(x * 0.9)))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out = Image.alpha_composite(out, brillo)
    out = Image.alpha_composite(out, cuerpo)
    return out


def ataque(img):
    """Pose de ataque PROVISIONAL a partir de la imagen normal: inclinada hacia adelante,
    un poco más brillante y con líneas de velocidad detrás."""
    w, h = img.size
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    a = img.split()[3]
    caja = a.getbbox() or (0, 0, w, h)
    cy = (caja[1] + caja[3]) // 2
    for i, dy in enumerate((-40, -10, 20, 50)):
        y = cy + dy * h // 256
        x0 = max(0, caja[0] - 50 * w // 256)
        d.line([(x0, y), (x0 + (36 - i * 4) * w // 256, y)], fill=(255, 230, 160, 200), width=max(2, 4 * w // 256))
    inclinada = img.rotate(-9, resample=Image.BICUBIC, center=(w // 2, h - 4))
    inclinada = Image.eval(inclinada, lambda v: min(255, int(v * 1.08)))
    base.alpha_composite(inclinada, (int(w * 0.04), 0))
    return base


def es_provisional(ruta):
    if not os.path.exists(ruta):
        return True
    try:
        return Image.open(ruta).info.get("origen") == MARCA
    except Exception:
        return True


def escenario(nombre, arriba, abajo, tipo, w=1280, h=720):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(arriba[i] * (1 - t) + abajo[i] * t) for i in range(3)))
    random.seed(nombre)
    if tipo == "laguna":
        d.rectangle([0, 470, w, h], fill=(20, 60, 80))
        for i in range(40):
            x = random.randint(0, w)
            y = random.randint(480, h)
            d.line([(x, y), (x + 60, y)], fill=(70, 140, 160), width=3)
        for i in range(30):
            x = random.randint(0, w)
            d.line([(x, 470), (x + random.randint(-10, 10), 380)], fill=(40, 90, 40), width=5)
    elif tipo == "pueblo":
        for i in range(9):
            x = i * 150 + random.randint(-20, 20)
            ht = random.randint(120, 220)
            d.rectangle([x, 520 - ht, x + 130, 520], fill=(90, 50, 60), outline=(40, 20, 30), width=4)
            d.polygon([(x - 10, 520 - ht), (x + 65, 470 - ht), (x + 140, 520 - ht)], fill=(140, 60, 40))
        d.rectangle([0, 520, w, h], fill=(70, 50, 40))
        d.rectangle([560, 220, 720, 520], fill=(220, 210, 190), outline=(80, 60, 50), width=5)
        d.polygon([(540, 220), (640, 120), (740, 220)], fill=(200, 190, 170))
    elif tipo == "curiche":
        d.rectangle([0, 480, w, h], fill=(25, 40, 30))
        for i in range(25):
            x = random.randint(0, w)
            d.ellipse([x, random.randint(150, 400), x + 220, random.randint(420, 520)], fill=(15, 30, 25))
        for i in range(60):
            x, y = random.randint(0, w), random.randint(0, 480)
            d.ellipse([x, y, x + 4, y + 4], fill=(140, 255, 160))
    elif tipo == "jichi":
        d.rectangle([0, 430, w, h], fill=(10, 30, 50))
        for i in range(8):
            d.arc([100 + i * 130, 380, 400 + i * 130, 560], 180, 360, fill=(60, 160, 200), width=6)
        d.ellipse([980, 60, 1120, 200], fill=(230, 230, 200))
    elif tipo == "escenario":
        d.polygon([(0, h), (w, h), (w - 160, 470), (160, 470)], fill=(40, 25, 35))
        for i in range(6):
            x = 140 + i * 200
            d.polygon([(x, 0), (x - 80, 470), (x + 80, 470)], fill=tuple(min(255, c + 40) for c in arriba))
        d.rectangle([180, 360, 330, 470], fill=(25, 25, 30), outline=(90, 90, 100), width=5)
        d.rectangle([950, 360, 1100, 470], fill=(25, 25, 30), outline=(90, 90, 100), width=5)
    elif tipo == "sala":
        d.rectangle([0, 500, w, h], fill=(60, 40, 30))
        for i in range(12):
            d.rectangle([i * 110, 80, i * 110 + 90, 470], fill=(50, 35, 60), outline=(30, 20, 40), width=6)
        d.ellipse([520, 380, 760, 520], fill=(200, 200, 210), outline=(40, 40, 50), width=6)
    d.text((20, h - 40), "PROVISIONAL · " + nombre, font=fuente(22), fill=(255, 255, 255))
    return im


def mapa_santa_cruz(zonas):
    w, h = 1280, 720
    im = Image.new("RGB", (w, h), (40, 70, 40))
    d = ImageDraw.Draw(im)
    random.seed(7)
    for i in range(300):
        x, y = random.randint(0, w), random.randint(0, h)
        r = random.randint(10, 40)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(35 + random.randint(0, 20), 75 + random.randint(0, 30), 35))
    d.line([(0, 620), (300, 560), (700, 600), (1280, 520)], fill=(60, 120, 170), width=18)
    # Santa Cruz de la Sierra (capital, reservada para el final)
    d.ellipse([560, 300, 700, 420], fill=(120, 90, 80), outline=(255, 210, 60), width=6)
    d.text((540, 425), "Santa Cruz de la Sierra", font=fuente(24), fill=(255, 230, 150))
    for z in zonas:
        x, y = z["pos"]
        d.ellipse([x - 18, y - 70, x + 18, y - 34], fill=(255, 58, 94))
    d.text((20, 20), "PROVISIONAL · mapa_santa_cruz", font=fuente(22), fill=(255, 255, 255))
    return im


def mapa_zona(nombre, nodos):
    w, h = 1280, 720
    im = escenario("mapa_" + nombre, (40, 90, 70), (20, 50, 60), "laguna")
    d = ImageDraw.Draw(im)
    return im


def icono_mapa(estado):
    """Púa de guitarra: bloqueada (gris con candado), desbloqueada (roja) o vencida (dorada con visto)."""
    s = 512
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    colores = {"bloqueado": ((70, 66, 74), (30, 28, 34)), "desbloqueado": ((225, 35, 45), (90, 8, 14)), "vencido": ((240, 190, 50), (120, 80, 10))}
    relleno, borde = colores[estado]
    # Contorno de púa (triángulo redondeado)
    pts = []
    for i in range(120):
        t = i / 120 * math.tau
        r = 200 * (1 + 0.18 * math.cos(3 * t - math.pi / 2) * 0 )
        x = 256 + 190 * math.sin(t)
        y = 236 - 150 * math.cos(t) + 60 * (math.cos(t) < 0) * (-math.cos(t)) ** 2 * 1.6
        pts.append((x, y))
    d.polygon(pts, fill=borde)
    pts2 = [(256 + (x - 256) * 0.84, 236 + (y - 236) * 0.84) for x, y in pts]
    d.polygon(pts2, fill=relleno)
    d.ellipse([150, 120, 250, 190], fill=tuple(min(255, c + 60) for c in relleno))  # brillo
    if estado == "bloqueado":
        d.rounded_rectangle([186, 230, 326, 340], 18, fill=(20, 18, 24), outline=(150, 145, 160), width=10)
        d.arc([206, 168, 306, 296], 180, 360, fill=(150, 145, 160), width=22)
        d.ellipse([244, 266, 268, 290], fill=(150, 145, 160))
        d.rectangle([251, 285, 261, 315], fill=(150, 145, 160))
    elif estado == "desbloqueado":
        # Estrella blanca
        estrella = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            rr = 90 if i % 2 == 0 else 38
            estrella.append((256 + rr * math.cos(a), 250 + rr * math.sin(a)))
        d.polygon(estrella, fill=(255, 245, 235))
    else:
        d.line([(180, 250), (238, 310), (340, 190)], fill=(255, 255, 255), width=34, joint="curve")
    return im.resize((256, 256), Image.LANCZOS)


def icono_tipo(tipo, color):
    """Ícono plano de tipo de instrumento: círculo de color con un pictograma blanco (128x128)."""
    S = 512
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    blanco = (255, 255, 255, 255)
    d.ellipse([16, 16, S - 16, S - 16], fill=(20, 14, 24, 255))
    d.ellipse([40, 40, S - 40, S - 40], fill=color + (255,))
    c = S // 2
    if tipo == "cordofono":
        # Púa con tres cuerdas
        d.polygon([(c - 120, c - 110), (c + 120, c - 110), (c + 130, c - 60), (c, c + 140), (c - 130, c - 60)], fill=blanco)
        for dx in (-50, 0, 50):
            d.line([(c + dx, c - 90), (c + dx * 0.4, c + 90)], fill=color + (255,), width=16)
    elif tipo == "aerofono":
        # Quena con agujeros y soplo
        d.rounded_rectangle([c - 50, c - 160, c + 50, c + 160], 40, fill=blanco)
        for dy in (-80, -20, 40, 100):
            d.ellipse([c - 18, c + dy - 18, c + 18, c + dy + 18], fill=color + (255,))
        for k, dy in enumerate((-110, -30)):
            d.arc([c + 75, c + dy - 40, c + 175, c + dy + 40], 270, 90, fill=blanco, width=16)
    elif tipo == "membranofono":
        # Tambor
        d.rectangle([c - 130, c - 60, c + 130, c + 110], fill=blanco)
        d.ellipse([c - 130, c - 110, c + 130, c - 10], fill=blanco, outline=color + (255,), width=14)
        d.ellipse([c - 130, c + 60, c + 130, c + 160], fill=blanco)
        for x in (-80, 0, 80):
            d.line([(c + x - 30, c - 10), (c + x + 30, c + 100)], fill=color + (255,), width=12)
        d.line([(c + 60, c - 190), (c + 170, c - 90)], fill=blanco, width=22)
    elif tipo == "idiofono":
        # Campana
        d.pieslice([c - 130, c - 150, c + 130, c + 110], 180, 360, fill=blanco)
        d.polygon([(c - 130, c - 20), (c + 130, c - 20), (c + 160, c + 90), (c - 160, c + 90)], fill=blanco)
        d.rectangle([c - 175, c + 80, c + 175, c + 115], fill=blanco)
        d.ellipse([c - 35, c + 105, c + 35, c + 170], fill=blanco)
        d.ellipse([c - 25, c - 190, c + 25, c - 140], fill=blanco)
    elif tipo == "electrofono":
        # Rayo
        d.polygon([(c + 40, c - 190), (c - 110, c + 20), (c - 10, c + 20), (c - 50, c + 190), (c + 110, c - 30), (c + 10, c - 30)], fill=blanco)
    return im.resize((128, 128), Image.LANCZOS)


def icono():
    im = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, 191, 191], 36, fill=(30, 15, 40))
    d.polygon([(96, 18), (172, 96), (96, 174), (20, 96)], fill=(255, 58, 94))
    d.text((48, 66), "HR", font=fuente(56), fill=(255, 210, 60))
    return im


def main():
    with open(os.path.join(RAIZ, "data", "personajes.json"), encoding="utf-8") as f:
        personajes = json.load(f)
    with open(os.path.join(RAIZ, "data", "clases.json"), encoding="utf-8") as f:
        clases = json.load(f)
    with open(os.path.join(RAIZ, "data", "territorios.json"), encoding="utf-8") as f:
        terr = json.load(f)
    hechos = set()
    for pid, p in personajes.items():
        img_id = p.get("imagen", pid)
        if img_id in hechos:
            continue
        hechos.add(img_id)
        color = hex_rgb(clases[p["clase"]]["color"])
        if pid.startswith("e_"):
            color = tuple(int(c * 0.85) for c in color)
        ruta_normal = os.path.join(ASSETS, "personajes", "pj_%s_normal.png" % img_id)
        if es_provisional(ruta_normal):
            normal = silueta(color, p["clase"], img_id, femenino=img_id.endswith("_f") or img_id in ("l_aruma", "s_brisa", "e_corista"), monstruo=img_id == "j_jichi")
            guardar(normal, "personajes", "pj_%s_normal" % img_id)
        else:
            # Arte final del usuario: las variantes provisionales salen de su dibujo
            normal = Image.open(ruta_normal).convert("RGBA").resize((256, 256), Image.LANCZOS)
        guardar(espectral(normal), "personajes", "pj_%s_espectral" % img_id)
        ruta_ataque = os.path.join(ASSETS, "personajes", "pj_%s_normal_ataque.png" % img_id)
        if es_provisional(ruta_ataque):
            pose = ataque(normal)
            guardar(pose, "personajes", "pj_%s_normal_ataque" % img_id)
        else:
            # Pose de ataque dibujada por el usuario
            pose = Image.open(ruta_ataque).convert("RGBA").resize((256, 256), Image.LANCZOS)
        guardar(espectral(pose), "personajes", "pj_%s_espectral_ataque" % img_id)
    esc = {
        "esc_centro_mando": ((30, 15, 50), (10, 5, 15), "sala"),
        "esc_sala_ensayo": ((50, 25, 20), (15, 10, 10), "sala"),
        "esc_cotoca_pueblo": ((250, 150, 80), (80, 40, 60), "pueblo"),
        "esc_cotoca_laguna": ((120, 180, 210), (30, 70, 90), "laguna"),
        "esc_cotoca_curiche": ((20, 40, 35), (5, 15, 10), "curiche"),
        "esc_cotoca_jichi": ((15, 20, 50), (5, 10, 25), "jichi"),
    }
    for n, (a, b, t) in esc.items():
        guardar(escenario(n, a, b, t), "escenarios", n)
    sc = terr["santa_cruz"]
    guardar(mapa_santa_cruz(sc["zonas"]), "mapas", sc["mapa"])
    for z in sc["zonas"]:
        if z.get("mapa"):
            guardar(mapa_zona(z["id"], z.get("nodos", [])), "mapas", z["mapa"])
    # Pantalla de inicio y selección
    ini = escenario("esc_inicio", (70, 10, 40), (10, 5, 20), "escenario")
    d = ImageDraw.Draw(ini)
    d.text((640, 300), "HÉROE DEL ROCK", font=fuente(110), fill=(255, 58, 94), anchor="mm", stroke_width=8, stroke_fill=(0, 0, 0))
    d.text((640, 400), "imagen provisional · assets/escenarios/esc_inicio.png", font=fuente(26), fill=(255, 210, 60), anchor="mm")
    guardar(ini, "escenarios", "esc_inicio")
    guardar(escenario("esc_seleccion", (40, 15, 60), (10, 5, 20), "escenario"), "escenarios", "esc_seleccion")
    # Protagonistas: imagen fija de selección y animación de la señal de rock
    for g in ("m", "f"):
        color = hex_rgb(clases["guitarrista"]["color"])
        guardar(silueta(color, "guitarrista", "protagonista_" + g, femenino=(g == "f"), tam=512), "personajes", "seleccion_protagonista_" + g)
        pasos = [0.0, 0.3, 0.6, 0.85, 1.0, 0.95, 1.0, 0.95]
        for i, b in enumerate(pasos):
            cuadro = silueta(color, "guitarrista", "protagonista_%s_%d" % (g, i), femenino=(g == "f"), tam=512, brazo=b)
            guardar(cuadro, os.path.join("animaciones", "protagonista_%s_rock" % g), "%04d" % (i + 1))
    # Íconos de tipo de instrumento (128x128)
    with open(os.path.join(RAIZ, "data", "familias.json"), encoding="utf-8") as f:
        fams = json.load(f)
    for fam, col in fams["colores"].items():
        guardar(icono_tipo(fam, hex_rgb(col)), "ui", "tipo_" + fam)
    # Íconos de los puntos del mapa (256x256, transparentes)
    for estado in ("bloqueado", "desbloqueado", "vencido"):
        guardar(icono_mapa(estado), "ui", "icono_" + estado)
    ruta_icono = os.path.join(RAIZ, "icon.png")
    if not os.path.exists(ruta_icono) or Image.open(ruta_icono).info.get("origen") == MARCA:
        meta = PngInfo()
        meta.add_text("origen", MARCA)
        icono().save(ruta_icono, pnginfo=meta)
    print("Listo:", len(hechos), "personajes,", len(esc), "escenarios")


if __name__ == "__main__":
    main()
