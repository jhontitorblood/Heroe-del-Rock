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

## Menú principal

| Archivo | Uso | Medida |
| --- | --- | --- |
| `assets/escenarios/esc_menu_principal.png` | Fondo del menú principal. Incluye el logo: el perfil va debajo del logo (sobre la calavera) y las opciones sobre la zona oscura del callejón | PNG, **2520 × 1440** con zona segura (o 16:9) |

El texto del menú usa la tipografía **Bangers** (`assets/fuentes/Bangers-Regular.ttf`, licencia libre SIL OFL, ver `OFL-Bangers.txt`). Si mueves el logo o la zona oscura en tu imagen, las posiciones se ajustan en `scripts/pantallas/centro.gd`.

**Imágenes con margen extra (recomendado):** si un fondo mide **2520 × 1440**, el juego lo usa en modo "zona segura": la imagen llena la pantalla de cualquier celular o tablet sin deformarse ni dejar bordes, y solo se recorta parte del margen. Lo importante (logos, personajes, zonas donde va texto) debe ir dentro de la zona segura central de **1920 × 1080** (300 px de margen a los lados, 180 px arriba y abajo). Guía: [`plantilla_zona_segura.png`](plantilla_zona_segura.png). Las posiciones del menú y de los mapas se expresan en coordenadas de 1280 × 720 **sobre la zona segura**.

**Imágenes 16:9 normales:** el menú y los mapas se dibujan sobre un lienzo de 1280 × 720 que se escala junto con la imagen, así que el texto queda siempre sobre la misma parte del arte en cualquier celular. En pantallas más alargadas que 16:9, los costados se rellenan con la misma imagen muy oscurecida. Las posiciones de los nodos en `data/territorios.json` están en coordenadas de 1280 × 720 sobre la imagen del mapa.

## Personajes en combate — `assets/personajes/` — 256 × 256 px, fondo transparente

Cada personaje tiene cuatro imágenes:

- `pj_<id>_normal.png`: su apariencia normal (como enemigo).
- `pj_<id>_espectral.png`: su apariencia espectral (como seguidor). Debe conservar la identidad del personaje.
- `pj_<id>_normal_ataque.png`: pose de ataque; se muestra solo mientras dura su golpe.
- `pj_<id>_espectral_ataque.png`: pose de ataque en su versión espectral.

Si subes solo la imagen normal, `tools/generar_placeholders.py` crea a partir de ella las otras tres como provisionales (espectral con filtro azul y ataque inclinado con líneas de velocidad), hasta que subas las definitivas. Si falta la imagen de ataque, el personaje ataca con su imagen normal.

Dibuja a los personajes **mirando a la derecha**: el juego voltea a los enemigos para que miren hacia tu equipo. Si un dibujo mira a la izquierda, agrega `"mira": "izquierda"` a ese personaje en `data/personajes.json` y el juego lo voltea al revés (como Sonso de Cotoca).
En combate se muestran sin recuadro, con la sombra bajo los pies: deja los pies cerca del borde inferior de la imagen.

| id | Personaje |
| --- | --- |
| `protagonista_m` | Protagonista masculino |
| `protagonista_f` | Protagonista femenina |
| `e_hawkins` | 01 · J. Hawkins (guitarrista, guitarra eléctrica) |
| `e_lokillo` | 02 · P. Lokillo (tamborilero) |
| `e_umbra` | 02 · R. Umbra (vocalista) |
| `e_rosie` | 03 · R. Rosie (bajista) |
| `e_idarkness` | 03 · P. IDarkness (guitarrista, guitarra acústica) |
| `s_ivy` | 04 · R. Ivy (sublíder, vocalista) |
| `e_miguel` | 04 · R. Miguel (laudista) |
| `e_darklordbeer` | 05 · P. DarkLordBeer (clarinetista) |
| `s_jiujiu` | 06 · JiuJiu (sublíder, tecladista) |
| `e_sam` | 06 · R. Sam (bajista) |
| `e_herlanx` | 06 · P. Herlanx (tecladista, sintetizador) |
| `e_tamborero` | Tamborero del Jichi (baterista) |
| `e_corista` | Corista de Cotoca |
| `e_vientista` | Flautero de la Niebla (vientista) |
| `e_cuerdero` | Cuerdero de la Laguna (guitarrista, sin uso en el mapa) |
| `e_cantor` | Cantor del Taquirari (vocalista, sin uso en el mapa) |
| `l_aruma` | Aruma (líder, vocalista) |
| `j_jichi` | Jichi Ancestral, Señor de la Laguna (jefe) |

## Escenarios — `assets/escenarios/` — 1280 × 720 px

| Archivo | Uso |
| --- | --- |
| `esc_centro_mando.png` | Fondo de Escuadrón, Equipo, Archivo y Tareas reales |
| `esc_sala_ensayo.png` | Sala de Ensayo |
| `esc_cotoca_pueblo.png` | Combates en el pueblo |
| `esc_cotoca_laguna.png` | Combates en la laguna |
| `esc_cotoca_curiche.png` | Combates en el curiche |
| `esc_cotoca_jichi.png` | Combate contra el Jichi |

## Mapas — `assets/mapas/` — 1280 × 720 px

| Archivo | Uso |
| --- | --- |
| `mapa_santa_cruz.png` | Mapa de campaña de Santa Cruz, **2520 × 1440** con zona segura: Yapacaní, Portachuelo, Montero, Warnes, Cotoca y la capital. El espacio vacío de la izquierda lleva el panel de información |
| `mapa_cotoca.png` | Mapa de la zona Cotoca, **2520 × 1440** con zona segura. Marcadores 01–08 = misiones en orden, 09 = zona secreta |

## Íconos de los puntos del mapa — `assets/ui/` — 256 × 256 px, fondo transparente

| Archivo | Cuándo se muestra |
| --- | --- |
| `icono_bloqueado.png` | El punto todavía no se puede jugar |
| `icono_desbloqueado.png` | El punto se puede jugar (late suavemente) |
| `icono_vencido.png` | El punto ya fue vencido |

Los íconos tapan los marcadores dibujados en el mapa. Las posiciones de cada punto están en `data/territorios.json` (coordenadas 1280 × 720 sobre la zona segura del mapa). Si mueves un marcador en el dibujo, avísame o cambia ahí su `pos`.

## Íconos de tipo de instrumento — `assets/ui/` — 128 × 128 px, fondo transparente

Ícono plano de un color por tipo. Se muestra junto al nombre en combate, en la barra de turnos, en el mapa, el Despertar, Escuadrón, Archivo y Equipo.

| Archivo | Tipo | Color |
| --- | --- | --- |
| `tipo_cordofono.png` | De cuerda | Rojo |
| `tipo_aerofono.png` | De viento | Verde |
| `tipo_membranofono.png` | De membrana | Naranja |
| `tipo_idiofono.png` | De cuerpo | Morado |
| `tipo_electrofono.png` | Eléctricos/Digitales | Celeste |

Los colores están en `data/familias.json`.

## Ícono de la app

`icon.png` — 192 × 192 px.
