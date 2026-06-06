# Propuesta · Paletas de visualización de Estación R

Las paletas de visualización son distintas del **logo/UI** (azul #405BFF,
amarillo #EAFF38, etc.): esas son para interfaz y marca. Para **gráficos de
datos** hacen falta rampas pensadas con criterios perceptuales. Propuesta de
tres familias, **ancladas en el azul de marca** e interpoladas en espacio Lab,
y **chequeadas para daltonismo** (deuteranopia, protanopia, tritanopia).

> **Dirección elegida (2026-05-26): B · bitono de marca** (azul + amarillo).
> Incorpora los dos colores oficiales a la codificación de datos.

## 1. Secuencial — variables ordenadas (de menor a mayor)
Uso: cantidades, intensidades, conteos (ej. jugadores por provincia).
Bitono azul → amarillo (estilo *cividis*): bajo = navy, alto = amarillo.
Luminosidad monótona, óptima para daltonismo.

`#0E1A52` → `#405BFF` (marca) → `#1FA8B8` → `#A8E05A` → `#EAFF38`

## 2. Divergente — desvíos respecto de un centro
Uso: diferencias hacia dos lados de un punto neutro (ej. edad vs promedio,
% sobre/bajo la media). Azul ↔ amarillo, centro gris neutro.
El par azul–amarillo es de los más seguros para daltonismo.

`#1B2E9E` ↔ `#5E78FF` ↔ `#C9D2FF` ↔ `#F2F2EF` ↔ `#E8EE9E` ↔ `#C9D400` ↔ `#7E8400`

## 3. Cualitativa — categorías sin orden
Uso: grupos discretos (ej. posiciones, ligas, sí/no). 6 tonos distinguibles,
arranca en el azul de marca. CVD min_dist ≥ 8,5 en los tres tipos de daltonismo.

| # | Hex | Tono |
|---|------|------|
| 1 | `#405BFF` | Azul (marca) |
| 2 | `#E6A100` | Ámbar |
| 3 | `#2CA6C4` | Cian |
| 4 | `#B3294E` | Vino |
| 5 | `#6A4C93` | Violeta |
| 6 | `#D4499B` | Magenta |

⚠️ Más de 6 categorías degrada la separación bajo daltonismo: conviene
**agrupar** categorías chicas o **etiquetar directo** en vez de sumar colores.

## Cómo usarlas en R
`source("R/paleta_estacion_r.R")` expone escalas listas para ggplot2:

```r
+ scale_fill_er_c()              # secuencial (continua)
+ scale_fill_er_div(midpoint=0)  # divergente (centrada en un valor)
+ scale_fill_er_q()              # cualitativa (discreta)
# y sus variantes scale_colour_*
```

## Criterios aplicados
- **Coherencia de marca**: todas anclan en `#405BFF`.
- **Perceptual**: interpolación en Lab; luminosidad monótona en la secuencial.
- **Accesibilidad**: verificado con `colorblindcheck` para los 3 daltonismos.
- **Separación de roles**: el amarillo flúor `#EAFF38` queda para UI/acento
  sobre negro, NO para codificar datos (es ilegible sobre fondo claro).

## Para incorporar a la marca
Sugerencia: agregar esta sección a `identidad_visual/GUIA_DE_ESTILO.md` como
"Paletas de datos", y versionar `paleta_estacion_r.R` como asset compartido
(reusable en todos los proyectos con gráficos).
