# Arte del juego: nombres y medidas

Todas las imágenes actuales son **provisionales**. Para poner el arte final, reemplaza cada archivo por otro PNG con **el mismo nombre y la misma medida**. El código no cambia.

`tools/generar_placeholders.py` no sobrescribe una imagen que ya sea arte final.

## Entrada del juego

| Archivo | Uso | Formato y medida |
| --- | --- | --- |
| `assets/video/intro.ogv` | Video al abrir la app (se salta tocando 2 veces) | **Ogg Theora (.ogv)**, horizontal, 1280 × 720 |
| `assets/escenarios/esc_inicio.png` | Pantalla de inicio con el nombre del juego y el mensaje para tocar (el juego no agrega texto) | PNG, 1280 × 720 |
| `assets/escenarios/esc_seleccion.png` | Fondo de la selección de personaje | PNG, 1280 × 720 |
| `assets/personajes/seleccion_protagonista_m.png` | Imagen fija del protagonista masculino en la selección | PNG transparente, 512 × 512 |
| `assets/personajes/seleccion_protagonista_f.png` | Imagen fija de la protagonista femenina en la selección | PNG transparente, 512 × 512 |
| `assets/animaciones/protagonista_m_rock/0001.png`, `0002.png`, ... | Animación "señal de rock" masculina (reemplaza al GIF) | Cuadros PNG numerados, 512 × 512 |
| `assets/animaciones/protagonista_f_rock/0001.png`, `0002.png`, ... | Animación "señal de rock" femenina | Cuadros PNG numerados, 512 × 512 |

**Video:** si tu video es .mp4, conviértelo a .ogv. Con ffmpeg:
`ffmpeg -i video.mp4 -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 intro.ogv`

**GIF → cuadros:** Godot no reproduce GIF. Sepáralo en cuadros (por ejemplo en ezgif.com, opción "Split GIF"), renómbralos `0001.png`, `0002.png`, ... y súbelos a la carpeta. Se reproducen a 12 cuadros por segundo; puedes subir la cantidad de cuadros que quieras. Borra los cuadros de ejemplo que sobren.

Las imágenes fijas de selección también se usan en el menú principal mientras el jugador no elija una foto propia.

## Menú principal (vertical)

| Archivo | Uso | Medida |
| --- | --- | --- |
| `assets/ui/logo.png` | Logo en la parte superior del menú principal | PNG transparente, 1000 × 300 |
| `assets/escenarios/esc_centro_mando_vertical.png` | Fondo del menú principal, Equipo, Archivo y Tareas reales | PNG, 720 × 1280 |

## Personajes en combate — `assets/personajes/` — 256 × 256 px, fondo transparente

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
| `esc_centro_mando.png` | Escuadrón (horizontal) |
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
