# Alcance definido: El plantel de la Selección en datos

**Estado:** 🔨 En construcción (definido 2026-05-25)
**Decisión de Pablo:** enfocar en los **jugadores de la Selección**, no en el país.

## Qué mostramos

### Por jugador
- Edad (destacar el más joven, el más viejo, promedio del plantel)
- Origen → **mapa de Argentina** por lugar de nacimiento
- Partidos jugados con la Selección (caps) + goles
- Club actual + posición
- (Yapa) Valor de mercado

### Por plantel
- Edad promedio
- Total de caps acumulados (experiencia mundialista)
- Exterior vs. liga local
- Mapa de orígenes

## Salidas
1. **HTML Quarto + closeread** (scrollytelling) → para el blog de Estación R
2. **Cards PNG** (una por dato) → difusión en redes
Mismo pipeline de R genera ambas.

## Stack
- Datos: `worldfootballR` (Transfermarkt) → edad, caps, club, lugar nacimiento, valor
- Wrangling: tidyverse
- Mapas: `sf` (provincias AR) + geocoding de ciudades de nacimiento
- Gráficos: ggplot2 (+ ggtext), tablas: gt
- Render: Quarto closeread

## Riesgo / supuesto clave
La lista final de **26 jugadores** del Mundial 2026 probablemente NO está
oficializada a la fecha. Arrancamos con la **última convocatoria / plantel
probable** y se actualiza cuando salga la lista oficial. El pipeline queda
parametrizado para regenerar todo con la lista nueva.

## Plan de ejecución
1. [en curso] Instalar worldfootballR + obtener datos del plantel
2. Construir dataset limpio (jugador × atributos) → guardar CSV
3. Geocodificar orígenes → mapa
4. Prototipo: 3-4 datos en Quarto closeread + 1-2 cards PNG
5. Mostrar a Pablo → iterar → set completo
