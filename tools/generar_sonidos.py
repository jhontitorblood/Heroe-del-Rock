#!/usr/bin/env python3
"""Genera los sonidos PROVISIONALES de combate en assets/sonidos/ (síntesis por código).

- ataque_<clase>.wav   suena cuando un personaje de esa clase ataca
- ataque_<familia>.wav respaldo por tipo de instrumento si la clase no tiene sonido propio
- ataque_<id>.wav      sonido propio de un personaje (por ejemplo el Jichi con su marimba)
- golpe.wav / golpe_fuerte.wav  el rival al recibir el golpe (fuerte = definitiva)

Nunca sobrescribe un archivo que ya existe (así se respetan los sonidos finales que subas).
Usa --forzar para regenerar todos los provisionales.
"""
import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DESTINO = os.path.join(RAIZ, "assets", "sonidos")
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- utilidades
def t_(dur):
    return np.arange(int(SR * dur)) / SR


def env(dur, ataque=0.005, caida=0.3, sostener=0.0):
    t = t_(dur)
    e = np.minimum(1.0, t / max(ataque, 1e-4))
    e *= np.exp(-np.maximum(0, t - ataque - sostener) / caida)
    return e


def filtro(x, corte, tipo="low", orden=2):
    if isinstance(corte, (list, tuple)):
        w = [c / (SR / 2) for c in corte]
    else:
        w = corte / (SR / 2)
    b, a = butter(orden, w, btype=tipo)
    return lfilter(b, a, x)


def suavizar_final(x, dur=0.015):
    n = min(len(x), int(dur * SR))
    x = np.copy(x)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def mezclar(*capas):
    n = max(int(inicio * SR) + len(c) for c, inicio in capas)
    y = np.zeros(n)
    for c, inicio in capas:
        c = suavizar_final(c, 0.01)  # sin chasquidos al terminar cada capa
        i = int(inicio * SR)
        y[i:i + len(c)] += c[: max(0, n - i)]
    return y


def pad(x, dur):
    n = int(dur * SR)
    return np.pad(x, (0, max(0, n - len(x))))[:n] if len(x) < n else x


def eco(x, retardo=0.09, fb=0.3, veces=3):
    x = suavizar_final(x)
    y = np.copy(x)
    d = int(retardo * SR)
    y = np.pad(y, (0, d * veces))
    for k in range(1, veces + 1):
        y[d * k: d * k + len(x)] += x * (fb ** k)
    return y


def saw(f, t):
    fase = np.cumsum(np.broadcast_to(f, t.shape) / SR)
    return 2 * (fase % 1.0) - 1


def sq(f, t, ancho=0.5):
    fase = np.cumsum(np.broadcast_to(f, t.shape) / SR)
    return np.where(fase % 1.0 < ancho, 1.0, -1.0)


def sen(f, t):
    fase = np.cumsum(np.broadcast_to(f, t.shape) / SR)
    return np.sin(2 * np.pi * fase)


def ruido(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def cuerda(f, dur, brillo=0.5, decaimiento=0.996):
    """Karplus-Strong: cuerda punteada."""
    n = int(SR * dur)
    p = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, p)
    buf = filtro(buf, 1500 + brillo * 8000) if p > 12 else buf
    y = np.zeros(n)
    for i in range(n):
        y[i] = buf[i % p]
        buf[i % p] = decaimiento * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    return y


def distorsion(x, ganancia=8.0):
    return np.tanh(x * ganancia) / np.tanh(ganancia)


def formantes(fuente, vocal):
    tabla = {
        "a": [(800, 80), (1150, 90), (2900, 120)],
        "o": [(450, 70), (800, 80), (2830, 100)],
        "u": [(325, 50), (700, 60), (2530, 170)],
        "e": [(400, 60), (2000, 100), (2550, 120)],
    }
    y = np.zeros_like(fuente)
    for (fc, bw), g in zip(tabla[vocal], [1.0, 0.6, 0.25]):
        y += g * filtro(fuente, [max(30, fc - bw * 1.5), fc + bw * 1.5], "band")
    return y


def normal(x, pico=0.85, cola=0.02, rms=0.2):
    """Iguala el volumen percibido (RMS) entre sonidos y limita los picos sin cortar en seco."""
    x = np.asarray(x, dtype=float)
    m = np.max(np.abs(x)) or 1.0
    x = x / m
    r = float(np.sqrt(np.mean(x ** 2))) or 1.0
    x = x * (rms / r)
    if np.max(np.abs(x)) > pico:
        x = np.tanh(x / pico) * pico
    n = int(cola * SR)
    if n and len(x) > n:
        x[-n:] *= np.linspace(1, 0, n)
    return x


# ---------------------------------------------------------------- instrumentos
def guitarra():
    # Acorde de quinta (E5) rasgueado, con distorsión suave y "parlante" de guitarra
    f = [82.4, 123.5, 164.8, 246.9]
    capas = [(cuerda(fx, 0.9, 0.25, 0.998), i * 0.014) for i, fx in enumerate(f)]
    x = mezclar(*capas)
    x = filtro(x, [70, 2500], "band")
    x = distorsion(x / (np.max(np.abs(x)) or 1), 4)
    x = filtro(filtro(x, 3200), 90, "high")
    x = x * env(len(x) / SR, 0.002, 0.4, 0.12)
    return normal(suavizar_final(x))


def bajo():
    # Bajo eléctrico punteado. Lleva armónicos marcados para que se oiga en parlantes de celular
    dur = 0.7
    t = t_(dur)
    f = 55 * (1 + 0.04 * np.exp(-t * 30))
    x = sum((1 / k) * sen(k * f, t) * np.exp(-t * (2 + k * 1.5)) for k in range(1, 9))
    x = filtro(distorsion(x, 2.5), 1800) * env(dur, 0.004, 0.3, 0.08)
    puas = filtro(ruido(0.025), [1500, 5000], "band") * env(0.025, 0.001, 0.006) * 0.5
    return normal(suavizar_final(mezclar((x, 0), (puas, 0))))


def voz():
    # Grito rockero "aaah" con vibrato que sube
    dur = 0.75
    t = t_(dur)
    f = 220 * (1 + 0.35 * np.minimum(1, t / 0.25)) * (1 + 0.025 * np.sin(2 * np.pi * 6 * t))
    fuente = saw(f, t) + 0.25 * ruido(dur)
    x = formantes(fuente, "a")
    x = distorsion(x * 3, 2.5) * env(dur, 0.03, 0.25, 0.3)
    return normal(eco(x, 0.11, 0.25, 2))


def coro():
    dur = 0.8
    t = t_(dur)
    x = np.zeros(len(t))
    for fx, d in [(262, 0.0), (330, 0.4), (392, -0.3), (523, 0.2)]:
        f = fx * (1 + 0.006 * np.sin(2 * np.pi * (5 + d) * t))
        x += formantes(saw(f, t) + 0.1 * ruido(dur), "o")
    x *= env(dur, 0.06, 0.25, 0.3)
    return normal(eco(x, 0.13, 0.3, 3))


def teclado():
    # Golpe de sintetizador: acorde de sierras desafinadas con filtro que se cierra
    dur = 0.6
    t = t_(dur)
    x = np.zeros(len(t))
    for fx in [220, 261.6, 329.6, 440]:
        for det in (-0.006, 0.0, 0.006):
            x += saw(fx * (1 + det), t)
    corte = 600 + 5000 * np.exp(-t * 9)
    y = np.zeros_like(x)
    # filtro variable por bloques
    blk = 512
    for i in range(0, len(x), blk):
        y[i:i + blk] = filtro(x[max(0, i - 2048):i + blk], float(corte[min(i, len(corte) - 1)]))[-len(x[i:i + blk]):]
    y *= env(dur, 0.004, 0.2, 0.05)
    return normal(eco(y, 0.09, 0.3, 2))


def flauta():
    # Ráfaga de flauta / quena: tres notas rápidas con soplido
    notas = [(659, 0.09), (784, 0.09), (988, 0.32)]
    capas, ini = [], 0.0
    for f, d in notas:
        t = t_(d)
        tono = sen(f * (1 + 0.01 * np.sin(2 * np.pi * 7 * t)), t) + 0.2 * sen(2 * f, t)
        aire = filtro(ruido(d), [f * 0.8, f * 3], "band") * 0.5
        capas.append(((tono + aire) * env(d, 0.012, d * 0.7, d * 0.2), ini))
        ini += d * 0.9
    return normal(eco(mezclar(*capas), 0.1, 0.25, 2))


def clarinete():
    # Tono de madera (solo armónicos impares) con subida al agudo
    dur = 0.55
    t = t_(dur)
    f = 196 * (1 + 0.5 * np.clip((t - 0.15) / 0.12, 0, 1))
    x = sum((1 / k) * sen(k * f, t) for k in (1, 3, 5, 7, 9))
    x += 0.1 * filtro(ruido(dur), [800, 3000], "band")
    x = filtro(x, 3500) * env(dur, 0.02, 0.2, 0.25)
    return normal(eco(x, 0.1, 0.2, 2))


def violin():
    # Arco con ataque marcado y vibrato
    dur = 0.6
    t = t_(dur)
    f = 659 * (1 + 0.012 * np.sin(2 * np.pi * 6.5 * t) * np.minimum(1, t / 0.15))
    x = saw(f, t) + 0.5 * saw(f * 1.5, t)
    x = filtro(x, [400, 6000], "band")
    x += 0.15 * filtro(ruido(dur), [2000, 7000], "band") * np.exp(-t * 20)
    x *= env(dur, 0.015, 0.18, 0.3)
    return normal(eco(x, 0.12, 0.25, 2))


def punteo(f_base, notas, brillo, espacio):
    capas = [(cuerda(f_base * r, 0.6, brillo, 0.995), i * espacio) for i, r in enumerate(notas)]
    x = mezclar(*capas)
    return normal(filtro(x, 7000) * env(len(x) / SR, 0.002, 0.3, 0.1))


def charango():
    # Rasgueo agudo y brillante, dos veces
    a = punteo(392, [1, 1.26, 1.5, 2, 2.52], 0.95, 0.008)
    return normal(mezclar((a, 0), (a * 0.8, 0.14)))


def laud():
    return punteo(147, [1, 1.5, 2, 2.5, 3], 0.6, 0.03)


def tambor_golpe(f=180, dur=0.25, cuerpo=0.6, cascabel=0.6):
    t = t_(dur)
    tono = sen(f * (1 + 0.5 * np.exp(-t * 40)), t) * np.exp(-t * 18) * cuerpo
    ch = filtro(ruido(dur), [1500, 9000], "band") * np.exp(-t * 25) * cascabel
    return tono + ch


def bombo(dur=0.35):
    t = t_(dur)
    return sen(55 * (1 + 2.5 * np.exp(-t * 35)), t) * np.exp(-t * 9)


def platillo(dur=0.9):
    t = t_(dur)
    return filtro(ruido(dur), 5000, "high") * np.exp(-t * 4) * 0.5


def bateria():
    # Redoble: caja, tom alto, tom bajo, bombo + platillo
    capas = [
        (tambor_golpe(200, 0.2), 0.0),
        (tambor_golpe(200, 0.2) * 0.7, 0.07),
        (tambor_golpe(150, 0.25, 1.0, 0.15), 0.14),
        (tambor_golpe(105, 0.3, 1.0, 0.1), 0.21),
        (bombo() * 1.3, 0.3),
        (platillo(), 0.3),
    ]
    return normal(mezclar(*capas))


def tamborilero():
    # Redoble rápido de tambor con golpe final acentuado
    capas = [(tambor_golpe(230, 0.12, 0.4, 0.8) * (0.4 + 0.05 * i), i * 0.035) for i in range(9)]
    capas.append((tambor_golpe(210, 0.35, 0.8, 1.0) * 1.4, 0.34))
    return normal(mezclar(*capas))


def consola():
    # Acople (feedback) que sube y se corta con un fallo digital
    dur = 0.55
    t = t_(dur)
    f = 1800 + 1400 * t / dur
    x = sen(f, t) * np.minimum(1, t / 0.2) * 0.8
    x += 0.3 * sq(f / 4, t, 0.3)
    x *= np.where((t > 0.42) & ((t * 60) % 1 < 0.5), 0.0, 1.0)
    return normal(filtro(x, 6000) * env(dur, 0.01, 0.3, 0.3))


def marimba_nota(f, dur=0.45):
    t = t_(dur)
    return (sen(f, t) * np.exp(-t * 7) + 0.35 * sen(f * 3.9, t) * np.exp(-t * 18)
            + 0.15 * sen(f * 9.2, t) * np.exp(-t * 40))


def marimba():
    # Corrida descendente grave de marimba (cuerpo / idiófono)
    notas = [330, 262, 220, 165, 110]
    capas = [(marimba_nota(f, 0.5), i * 0.07) for i, f in enumerate(notas)]
    capas.append((marimba_nota(55, 0.9) * 1.3, 0.35))
    return normal(eco(mezclar(*capas), 0.12, 0.3, 2))


def golpe(fuerte=False):
    dur = 0.45 if fuerte else 0.25
    t = t_(dur)
    seco = sen(90 * (1 + 1.5 * np.exp(-t * 30)), t) * np.exp(-t * (8 if fuerte else 16))
    chasquido = filtro(ruido(dur), [800, 6000], "band") * np.exp(-t * (14 if fuerte else 30))
    x = 1.1 * seco + 0.7 * chasquido
    if fuerte:
        x += 0.5 * platillo(dur)[: len(x)]
        x = eco(x, 0.07, 0.35, 3)
    return normal(distorsion(x, 2.0), 0.9)


SONIDOS = {
    # por clase
    "ataque_guitarrista": guitarra,
    "ataque_bajista": bajo,
    "ataque_vocalista": voz,
    "ataque_corista": coro,
    "ataque_tecladista": teclado,
    "ataque_vientista": flauta,
    "ataque_clarinetista": clarinete,
    "ataque_violinista": violin,
    "ataque_charanguista": charango,
    "ataque_laudista": laud,
    "ataque_baterista": bateria,
    "ataque_tamborilero": tamborilero,
    "ataque_ingeniero": consola,
    # por tipo de instrumento (respaldo)
    "ataque_cordofono": guitarra,
    "ataque_membranofono": bateria,
    "ataque_aerofono": flauta,
    "ataque_electrofono": teclado,
    "ataque_idiofono": marimba,
    # personajes con sonido propio
    "ataque_j_jichi": marimba,
    # al recibir
    "golpe": golpe,
    "golpe_fuerte": lambda: golpe(True),
}


def main():
    forzar = "--forzar" in sys.argv
    os.makedirs(DESTINO, exist_ok=True)
    hechos = 0
    for nombre, fn in SONIDOS.items():
        ruta = os.path.join(DESTINO, nombre + ".wav")
        if os.path.exists(ruta) and not forzar:
            continue
        if any(os.path.exists(os.path.join(DESTINO, nombre + ext)) for ext in (".ogg", ".mp3")):
            continue  # hay un sonido final en otro formato
        x = fn()
        wavfile.write(ruta, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        hechos += 1
    print("Listo: %d sonidos generados en assets/sonidos" % hechos)


if __name__ == "__main__":
    main()
