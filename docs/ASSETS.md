# Arte del juego: nombres y medidas

Todas las imágenes actuales son **provisionales**. Para poner el arte final, reemplaza cada archivo por otro PNG con **el mismo nombre y la misma medida**. El código no cambia.

`tools/generar_placeholders.py` no sobrescribe una imagen que ya sea arte final.

## Personajes — `assets/personajes/` — 256 × 256 px, fondo transparente

Cada personaje tiene dos versiones:

- `pj_<id>_normal.png`: su apariencia normal (como enemigo).
- `pj_<id>_espectral.png`: su apariencia espectral (como seguidor). Debe conservar la identidad del personaje.

Los enemigos se muestran volteados horizontalmente: dibújalos mirando a la derecha.

| id | Personaje |
| --- | --- |
| `protagonista_m` | Protagonista masculino |
| `protagonista_f` | Protagonista femenina |
| `e_cuerdero` | Cuerdero de la Laguna (guitarrista) |
| `e_tamborero` | Tamborero del Jichi (baterista) |
| `e_tecladista` | Tecladista del Pantano |
| `e_bajista` | Bajista del Curiche |
| `e_corista` | Corista de Cotoca |
| `e_vientista` | Flautero de la Niebla (vientista) |
| `e_cantor` | Cantor del Taquirari (vocalista) |
| `s_brisa` | Brisa Taquirari (sublíder, charanguista) |
| `s_lazaro` | Lázaro Consola (sublíder, ingeniero de sonido) |
| `l_aruma` | Aruma (líder, vocalista) |
| `j_jichi` | Jichi Ancestral, Señor de la Laguna (jefe) |

## Escenarios — `assets/escenarios/` — 1280 × 720 px

| Archivo | Uso |
| --- | --- |
| `esc_titulo.png` | Pantalla de título y creación |
| `esc_centro_mando.png` | Centro de Mando y menús |
| `esc_sala_ensayo.png` | Sala de Ensayo |
| `esc_cotoca_pueblo.png` | Combates en el pueblo |
| `esc_cotoca_laguna.png` | Combates en la laguna |
| `esc_cotoca_curiche.png` | Combates en el curiche |
| `esc_cotoca_jichi.png` | Combate contra el Jichi |

## Mapas — `assets/mapas/` — 1280 × 720 px

| Archivo | Uso |
| --- | --- |
| `mapa_santa_cruz.png` | Mapa de campaña de Santa Cruz (la posición de cada zona está en `data/territorios.json`) |
| `mapa_cotoca.png` | Mapa de la zona Cotoca (la posición de cada combate está en `data/territorios.json`) |

## Ícono de la app

`icon.png` — 192 × 192 px.
