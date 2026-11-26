# Héroe del Rock

RPG táctico por turnos para Android, ambientado en Bolivia, donde el progreso nace de **tareas reales**: ejercicio, práctica de instrumento, tareas de la casa y trabajo o estudio.

**Versión 0.1.0: beta de Cotoca.** Arte provisional.

## Descargar e instalar el APK

1. Entra a la pestaña **Actions** de este repositorio.
2. Abre la ejecución más reciente de **Compilar APK** que tenga la marca verde.
3. Al final de la página, en **Artifacts**, descarga `heroe-del-rock-apk` (es un .zip).
4. Descomprímelo en el celular y abre `heroe-del-rock.apk`. Android pedirá permitir "instalar apps de origen desconocido".

Es un APK de prueba (debug). No necesita internet y guarda la partida en el propio teléfono.

## Qué incluye la beta

- Creación de personaje (masculino o femenino) con nombre propio.
- **Centro de Mando:** Campaña, Mapa, Escuadrón, Equipo, Archivo, Tareas reales y Sala de Ensayo.
- **Cotoca completo:** 7 combates (con 2 sublíderes y la líder Aruma), el jefe Jichi Ancestral y una zona secreta que se abre con una racha de 3 días.
- **Combate por turnos:** una acción por combatiente cada ronda, orden por velocidad, selección de objetivo, 9 clases musicales, afinidades de género, sinergias en ataques conjuntos, definitivas individuales y de banda, resurrección y modo automático.
- **Despertar espectral:** 3 intentos con probabilidad según la diferencia de nivel, +10 % por cada fallo y Púa Espectral (+15 %). Si fallas los 3, el enemigo reaparece en 6, 12 o 24 horas reales según su rareza.
- **Tareas reales:** suben atributos; las cadenas de 3 tareas y la cadena completa recargan energía y dan Púas; rachas con un día de gracia por semana y un tope diario de experiencia.
- **Sala de Ensayo:** rápido, completo y real (con práctica real de instrumento), más química entre los integrantes del equipo.
- **Desafinados:** tras perder, 5 minutos sin combatir; cada ejercicio extra resta 1 minuto.
- **Equipo:** empiezas solo, llegas a 2 con tu primer Despertar y a 3 al vencer a Aruma.

## Cómo está organizado

| Carpeta | Contenido |
| --- | --- |
| `data/` | Todo el contenido en JSON: clases, habilidades, personajes, territorios, reglas, géneros y tareas |
| `scripts/autoload/` | `datos.gd` (carga los datos) y `estado.gd` (partida, guardado y reglas de progreso) |
| `scripts/core/batalla.gd` | Motor de combate, sin interfaz |
| `scripts/pantallas/` | Una pantalla por archivo |
| `assets/` | Imágenes (provisionales por ahora) |
| `tools/generar_placeholders.py` | Genera el arte provisional |
| `tests/` | Prueba automática de pantallas, prueba de balance y capturas |

Para **agregar contenido** (otra zona, banda, personaje o habilidad), se editan los JSON de `data/`. No hace falta tocar el código.
Para **ajustar el balance** (energía, probabilidades, esperas, sinergias), se edita `data/reglas.json` y `data/generos.json`.

## Reemplazar el arte provisional

Consulta [`docs/ASSETS.md`](docs/ASSETS.md). Cada imagen final debe tener **el mismo nombre y la misma medida** que la provisional.

## Compilar en tu computadora

Necesitas Godot 4.3 con las plantillas de exportación para Android. Abre el proyecto y usa *Proyecto → Exportar → Android*.

Las pruebas automáticas se ejecutan así:

```
godot --headless --path . res://tests/prueba_pantallas.tscn
godot --headless --path . res://tests/prueba_balance.tscn
```

## Diseño

El documento maestro de diseño vive fuera del repositorio. Los diálogos de esta beta (Silvano Roca, Aruma, el Jichi) son provisionales.
