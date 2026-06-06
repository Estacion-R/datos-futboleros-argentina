# Semilla: Datos Futboleros sobre Argentina

**Estado:** 🌱 Semilla (registrada 2026-05-25)
**Origen:** Idea de Pablo en #proyecto-datos
**Inspiración:** INEGI — "33 Datos Futboleros sobre México" → https://inegi.org.mx/pasionporlosdatos/

## La idea

INEGI (instituto de estadística de México) publicó una presentación interactiva
deslizable, "33 Datos Futboleros sobre México", que vincula estadísticas
nacionales con la temática del Mundial FIFA. Formato mobile-first, tipo
scrollytelling, con datos curiosos del país, branding FIFA+INEGI, descargable,
y un cierre narrativo en el "minuto 90".

Objetivo: hacer un equivalente argentino aprovechando el Mundial 2026.

## El ángulo argentino (diferencial)

México es **sede** del Mundial 2026 → su narrativa es "el país anfitrión".
Argentina no es sede, pero es **el campeón del mundo vigente** (2022) y
**tricampeón** (1978, 1986, 2022). Ese es el gancho narrativo más fuerte:
"los datos del país del campeón del mundo".

## Decisiones de diseño propuestas (a validar)

- **Título / número:** "26 Datos Futboleros sobre Argentina" — 26 por el plantel
  de 26 jugadores del Mundial 2026 y por el año. Alternativas: 3 (tricampeón),
  10 (la 10), o el clásico 33 de INEGI.
- **Formato técnico:** Quarto + extensión `closeread` (scrollytelling nativo en R),
  mobile-first, que replica la experiencia deslizable de INEGI.
- **Visualización:** ggplot2 + gt para tablas; sf/ggiraph para mapas interactivos.
- **Difusión:** publicación web (Quarto Pub / GitHub Pages / Netlify) + thread
  en X/Instagram con cards estáticas (export de cada "dato").

## Fuentes de datos (R-accesibles)

- INDEC — población, geografía, economía
- datos.gob.ar (API de Datos Argentina)
- AFA / datasets públicos de fútbol (a investigar disponibilidad programática)

## Ideas de "datos curiosos" (brainstorm inicial)

- Cuántas veces entra la población argentina en el Estadio Monumental
- Consumo de mate per cápita vs. otros países mundialistas
- Cantidad de clubes / canchas registradas
- Mapa "una selección por provincia" o jugadores históricos por provincia
- Las 3 estrellas: timeline 1978 / 1986 / 2022
- Pico de bebés llamados "Thiago"/"Lionel" post-2022
- Costo del asado mundialista / inflación vs. precio de la camiseta

## Próximos pasos

1. Validar ángulo, número y alcance con Pablo
2. Mapear disponibilidad real de datasets en R
3. Prototipar 3-4 datos en Quarto+closeread como prueba de concepto
