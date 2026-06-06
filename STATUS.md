# Estado — Datos Futboleros: el plantel de la Selección

**Actualizado:** 2026-06-06
**Fase:** ✅ Proyecto publicado en GitHub Pages. **Nueva sección agregada (2026-06-06):** "El plantel en la cancha" — 5 imágenes closeread (arq/def/mid/fwd/ct) con fotos circulares de jugadores y cuerpo técnico sobre cancha de fútbol. Script: `R/10_cancha.R`. Fotos CT descargadas de Transfermarkt en `assets/fotos_ct/`.
Antes: regeneración con lista oficial 26 completa + rótulos (sección "🟡 ABIERTO").

## 🔄 REVISIÓN GRÁFICO POR GRÁFICO (en curso — retomar acá 2026-05-31)
**Plan (Pablo):** revisar y aprobar la versión NUEVA de cada gráfico del informe,
de a uno. El agente muestra cada pieza con su lectura crítica + mejoras; Pablo
valida o pide cambios; recién entonces se pasa al siguiente.

**Numeración CANÓNICA = orden de aparición en `index.qmd`** (lista de 10 piezas
que Pablo aprobó como referencia el 2026-05-31; reemplaza la vieja numeración por
8 cards). Estado:
1. ✅ **Galería del plantel línea por línea** (4 tablas gt: arqueros/defensores/
   mediocampistas/delanteros, foto+escudo+minimapa). `R/02_galeria.R`. **OK.**
2. ✅ **Campeones del mundo 2022** — caras color/gris, 17 de 26. `cards/07_campeones.png`. **OK.**
3. ✅ **Mapa por origen** — ggbump / `geom_sigmoid`, fondo oscuro + sombra.
   `pruebas/ggbump_origen.R` (EFECTO=sombra) → `cards/01_origen.png`. **OK.**
4. ✅ **Edad** — beeswarm (`ggbeeswarm`) + ggforce `geom_mark_rect`.
   `R/_edad_plot.R` → `cards/02_edad.png`. **OK.**
5. ✅ **Partidos × Mundiales (scatter) — INTEGRADO Y RENDEREADO (2026-05-31 mediodía).**
   Reemplazó al viejo caps: se sacó `cards/03_caps.png`/`#cr-caps` y se metió como **sección
   normal** "## Experiencia mundialista" en `index.qmd` (chunk `scatter-mundiales-interactivo`
   → `build_scatter_girafe()`), con copy nuevo (Messi universo aparte, Otamendi único con 3,
   7 sin Mundial, "pasá el mouse"). `R/09_scatter_mundiales.R`: `build_scatter()` (PNG redes,
   ggforce) + `build_scatter_girafe()` (INTERACTIVO ggiraph, tooltip nombre/partidos/Mundiales/club).
   **Verificado en el HTML real renderizado**, no en aislado (ver P1 abajo).
6. ✅ **Exterior — APROBADO (2026-05-31).** Barra 24 vs 2. Versión B: el **"2" en AMARILLO**
   dentro del bloque negro (regla amarillo-sobre-negro) + bajado el aire superior + **nota
   `annotate`** que baja del "24" con curva azul y apunta a un texto centrado: **"7 de esos 24
   (29%) provienen de LaLiga (España)"** (n, % y liga DINÁMICOS vía `top_liga`/`pct` sobre los
   del exterior). **REFACTOR:** el exterior se aisló de `01_cards.R` a **`R/_exterior_plot.R`**
   (`build_exterior_plot()`, guard `sys.nframe()==0`); `01_cards.R` lo sourcea. Regenerar solo:
   `Rscript R/_exterior_plot.R`.
7. ✅ **Valor (circular packing) — APROBADO (2026-05-31).** (`cards/05_valor_packing.png`,
   `R/08_valor_packing.R`). Al revisarlo se aplicaron 3 fixes de dato aprobados por Pablo:
   **(a) BUG PAREDES RESUELTO** en `00_prep.R` (regla "Midfield" movida ANTES que "Back|Defen";
   Paredes ahora Mediocampista). Nuevos totales: Mediocampistas 8/€325 M, Defensores 8/€152 M,
   Delanteros 7/€299 M, Arqueros 3/€26 M. **(b) "Julián Álvarez" con acento** — era clave de cruce
   en 6 lugares: `data/plantel_argentina.csv`, `data/img_urls.rds` (fotos), `03_stats.R`
   (vector `campeones_2022` + short), `09_scatter_mundiales.R` (tabla mundiales), `07_goleadores.R`
   y `06_ligas_tabla.R` (short). TODOS actualizados (si no, Álvarez perdía campeón/Mundial/foto).
   **(c) Nota convocatoria #1** en `index.qmd`: "3 arqueros, 8 defensores, 8 mediocampistas y 7
   delanteros" (antes 12/6/8 = 29, plantel viejo). Regeneradas: 05_valor_packing, 05_valor, 07_campeones
   (las que cambian visualmente). Goleadores/scatter sin cambio visible. Campeones siguen 17/26.
   **Ajustes visuales aprobados:** más aire arriba (`scale_y` expand top 0.16) + etiqueta del arquero
   más valioso (Dibu €15, vía `top_arq_id`). **INTERACTIVO EN EL REPORTE:** en `index.qmd` se fusionó el
   sticky estático `#cr-valor` + la sección "burbuja por burbuja" en UNA sola sección interactiva
   (`build_packing_girafe`); se quitó el closeread del valor. ⚠️ **El render del HTML murió por OOM
   (exit 137)** — el cambio está codeado (mismo patrón girafe que ya rendereaba antes) pero NO verificado
   en render; el doc es pesado (~24 MB de fotos embebidas). Resolver antes de publicar (optimizar fotos /
   más memoria al render).
8. ➡️ **FUSIONADO en el #7** — la versión interactiva ggiraph YA es la del reporte; dejó de ser ítem aparte.
9. ✅ **Ligas (tabla gt con caras) — APROBADO (2026-05-31).** (`06_ligas_tabla.R`). 3 mejoras: (a) función
   `apellido()` reescrita con `case_when` → **iniciales para nombres largos** (José Manuel López →
   "J. M. López"), respeta compuestos (Mac Allister/Lo Celso/De Paul); (b) **escudo del club** como badge
   abajo-derecha de cada cara (`escudo_file` de `img_urls.rds`, `local_image` h=17); (c) **nota al pie
   dinámica** `nota_atm`: "De los 7 jugadores en LaLiga, 6 militan en el Atlético de Madrid". Regenerada
   vía `Rscript R/06_ligas_tabla.R` + `python3 R/_shoot_tabla.py`.
10. ✅ **Goleadores — APROBADO (2026-05-31).** (`R/07_goleadores.R`). Cambios: (a) **posición en gris
    bajo cada nombre** (etiquetas izquierdas redibujadas como `geom_text` manual — el eje no admite 2
    colores con showtext — con `scale_x` extendido a negativo + `clip="off"`); (b) **UNA caja de marca
    negra** (reemplazó el callout "Messi metió 116") con DOS estadísticas separadas por línea tenue:
    `pct_messi`% ("53% de los goles los hizo Messi") + `con_gol` de 26 ("19 de 26 convirtieron al menos
    una vez"), ambos dinámicos; (c) **caption depurado** a solo la fuente (se quitó el desglose redundante
    y el "7 no marcaron", complemento de la caja). Empezó con 2 cajas → Pablo pidió fusionar en una sola.

✅✅ **REVISIÓN GRÁFICO POR GRÁFICO COMPLETA — los 10 aprobados (2026-05-31).**
**PENDIENTES post-revisión (en este orden):**
- **(P1) ✅ COMPLETO Y VERIFICADO EN HTML (2026-05-31 mediodía).** Scatter Partidos × Mundiales
  integrado al `index.qmd` (sección "Experiencia mundialista", reemplazó `#cr-caps`+`cards/03_caps.png`)
  y **rendereado al HTML real** (`index.html`, 09:11). Verificado con Playwright (nuevo
  **`R/_shoot_scatter.py`** → `previews/scatter_html*.png`): tooltip por jugador OK (hover Messi =
  "Lionel Messi · 198 partidos · 5 Mundiales · Inter Miami CF"), hover atenúa el resto a 0.30.
  Screenshot del hover enviado al canal.
- **(P2) ✅ DESTRABADO (2026-05-31 mediodía).** El render full salió **sin OOM** y el `index.html`
  quedó en **8.8 MB** (vs ~24 MB que disparaban el exit 137). No re-confirmado qué cambió exacto en
  la sesión previa (probable optimización de fotos); este render concreto funcionó. Si volviera a
  morir: reintentar (loop 2-3) y/o optimizar fotos embebidas (95 PNG + 26 JPG).
- **(P-final) Pre-publicación:**
  - **(a) ✅ REVISIÓN DE PUNTA A PUNTA HECHA (2026-05-31 mediodía).** Capturadas y revisadas
    las 12 piezas del HTML (`R/_shoot_revision.py` → `previews/revision/*.png`). Veredicto:
    informe sólido y consistente (26 en todas las piezas; 24 ext + 2 local; 7 LaLiga/6 Atlético;
    14 BA + 2 exterior; fix Paredes propagado a galería/scatter/valor/goles; "Julián Álvarez"
    con acento; Messi €15/116 goles/53%; scatter y packing interactivos OK). **3 observaciones
    (ninguna bloqueante):** (1) DATOS a cotejar con Transfermarkt por ser clubes volátiles —
    Tagliafico figura en Olympique Marseille (¿Lyon?), Nico González y Thiago Almada en Atlético
    de Madrid (internamente consistentes en galería+ligas+valor, pero conviene confirmar);
    (2) COSMÉTICO — beeswarm de edad con mucho aire vertical en el HTML, comprimir altura;
    (3) MENOR — el caption "Datos e imágenes: Transfermarkt…" se repite en las 4 tablas de
    galería, dejar solo en la última.
  - **✅ CAMBIOS APLICADOS (2026-05-31 mediodía, tras OK de Pablo):**
    - **Punto 2 (edad):** comprimido el aire vertical → chunk `edad-plot` de `index.qmd` a
      `fig-height: 4.5` + `scale = 1.05`. **Luego (pedido Pablo) REVERTIDO el beeswarm a JITTER
      aleatorio** en `R/_edad_plot.R` (`set.seed(42)` + `runif(n(), -0.34, 0.34)`, ya no
      `beeswarm::beeswarm`): los puntos se dispersan al azar, no en columnas verticales. Las
      anotaciones `geom_mark_rect` (jóvenes/grandes) usan las mismas coords. Card de redes
      `cards/02_edad.png` regenerada (`Rscript R/01_cards.R`, scale 1.5) + HTML re-renderizado.
    - **Punto 3:** ANULADO a propósito. Pablo pidió atribución de fuente en CADA pieza con fotos,
      así que se MANTIENE el caption en las 4 tablas de galería (no se unifica).
    - **Derechos de fotos (pedido de Pablo):** leyenda de fuente debajo de cada pieza con caras.
      Faltaba solo **campeones** → agregada `"Datos e imágenes: Transfermarkt · Estación R"` al
      caption en `R/03_stats.R` (build campeones). Galería (`02_galeria.R`), ligas (`06_ligas_tabla.R`)
      y goleadores (`07_goleadores.R`) ya la tenían. Las **7 piezas con fotos** quedan atribuidas.
    - Regenerado `cards/07_campeones.png` (`Rscript R/03_stats.R`) + **HTML re-renderizado OK al
      primer intento, sin OOM, 8.8 MB** (09:41). Verificado con `R/_shoot_revision.py`.
  - **(b) Punto 1 (DATOS) — ✅ COTEJADO, TODO CORRECTO (2026-05-31, web_search + CSV).** Los 3
    clubes "sospechosos" están bien y NO se tocó nada: **Tagliafico = Olympique Lyon** (CSV
    `data/plantel_argentina.csv` ya decía Lyon; la galería muestra Lyon con escudo OL — mi
    "Marseille" de la 1ª revisión fue lectura errónea, lo confundí con Balerdi/Medina que sí son
    Marseille); **Nico González = Atlético de Madrid** (cedido por Juventus, web confirma);
    **Thiago Almada = Atlético de Madrid** (fichó 2025, contrato 2030, web confirma). El scrape
    del 28/05 quedó validado.
  - **✅ PROYECTO CERRADO Y TRASPASADO A COORDINACIÓN (2026-05-31 ~10:16).** Pablo pidió avisar
    a coordinación para organizar el lanzamiento. Aviso entregado vía `sessions_send` al canal
    **#coordinadora** (sessionKey `agent:main:discord:channel:1492495300340879430`, agente `main`;
    OJO: el agente `proyectos` NO tiene acceso de escritura directa a ese canal → solo `sessions_send`).
    Coordinación lo tomó y ya organiza: pedido a Pablo 3 definiciones + fecha y armó el flujo
    **Proyectos regenera → Plomero/web-devops publica → Redes difunde (LinkedIn primero)**, nada sale
    sin OK de Pablo.
  - **✅ DECISIONES DE PABLO RECIBIDAS VÍA COORDINACIÓN (2026-05-31):**
    1. **Fotos Transfermarkt:** publicar CON fotos + atribución. Pablo asume el riesgo. La versión
       con fotos + atribución es la **oficial**. La versión sin fotos queda como backup OPCIONAL
       (no hay que generarla salvo que la pidan).
    2. **Publicación (actualizado 2026-06-01):** vía **GitHub Pages** en la org Estacion-R.
       El `index.html` self-contained quedó live en estacion-r.github.io/datos-futboleros-argentina
       (repo público Estacion-R/datos-futboleros-argentina). El post a medias del blog lo borra Pablo.
    3. **Difusión:** el orden es blog primero → Pablo revisa → recién ahí entra Redes. NO antes.
    4. **Fecha de lanzamiento:** pendiente. Pablo todavía no la definió. **No publicar ni difundir
       hasta tener fecha confirmada.** Mi parte queda en standby; estoy listo para regenerar/exportar
       lo que pida el lanzamiento (otros formatos de cards, versión sin fotos si la piden, etc.).

**Decisiones tomadas en esta ronda:** 1-4 aprobados; 5 reemplazado por scatter Mundiales (ya integrado);
6-10 aprobados; scatter pasado a interactivo en el HTML.

**Reglas vigentes** (ahorro de tokens): NO `quarto render` salvo pedido explícito;
tocar 1 gráfico = correr solo su PNG (`Rscript R/<script>.R`), nunca las 8 cards.

## Qué está hecho
- **Pipeline de datos real**: `R/00_prep.R` baja el plantel de Argentina de
  Transfermarkt (29 jugadores) vía rvest: nombre, posición, fecha nac./edad,
  club, valor de mercado, caps, goles y lugar de nacimiento. Limpio en
  `data/plantel_argentina.csv`. Deriva `pos_grupo` (Arquero/Defensor/
  Mediocampista/Delantero) usado por la galería.
- **Mapa**: provincias vía paquete **geoAr** + **Islas Malvinas** siempre (regla
  del proyecto), cache en `data/provincias_geoar.rds`. Ciudad→provincia a mano
  (verificada). Choropleth con paleta Estación R dirección B (bitono azul→amarillo).
- **8 cards para redes** (`R/01_cards.R` + `R/03_stats.R` + `R/07_goleadores.R`
  → `cards/01..08_*.png`, 1080×~1350, marca Estación R): 1. Mapa de orígenes
  2. Edades  3. Caps  4. Exterior vs local  5. Valor de mercado  6. Ligas
  7. Campeones 2022  8. Goleadores (barras con caras circulares; Messi destacado).
- **HTML scrollytelling** (`index.qmd` → `index.html`): Quarto + closeread, marca
  Estación R (sidebar negro #191919, azul #405BFF, amarillo #EAFF38 SOLO sobre
  negro, Ubuntu). 7 secciones con visuales sticky — la de edades es **interactiva**
  (ggiraph, hover) — y al final la **galería por líneas del equipo** que se revela
  al scrollear (`.linea-reveal`, `R/02_galeria.R`). Renderiza OK; verificado con
  screenshots (`preview_*.png`).
- **Sección "Los goles"**: tarjetas "serie de datos" que aparecen al scrollear
  (175 / 116 / 2 de cada 3 / 14; las dos del medio en negro con número amarillo)
  + el gráfico de goleadores (card 08). Patrón que pidió Pablo: stat-cards +
  gráfico, no sólo el gráfico.

## Datos clave encontrados
- 16/29 nacidos en prov. de Buenos Aires; 2 en el exterior (Nico Paz/España, Simeone/Italia)
- Edad prom. 27.7 · más joven Mastantuono (18) · veterano Otamendi (38)
- 24/29 juegan en el exterior; 5 en liga local
- Messi: 198 caps / 116 goles. Plantel suma 1092 caps.

## Stack confirmado
R 4.6 · rvest · sf · ggplot2 + showtext (Oswald/Barlow) · ragg · gt · Quarto 1.6 + closeread (qmd-lab/closeread)

## Feedback aplicado
- 2026-05-26 (Pablo): sumado **inset de zoom a CABA** en la card del mapa para
  diferenciar capital de provincia. Dato reforzado: ninguno de los 29 nació en
  CABA (los 16 son de la provincia). Narrativa del HTML actualizada igual.
- 2026-05-26 (Pablo) 2ª ronda:
  - Mapa migrado a **geoAr** + **Islas Malvinas** siempre (regla del proyecto).
    Cache en `data/provincias_geoar.rds`.
  - Card de edades con 6 referencias; versión **interactiva** (ggiraph, hover)
    embebida en el HTML.
  - Nueva visualización: **galería de los 29** (`R/02_galeria.R` → `galeria.html`,
    e integrada en `index.qmd`): foto + escudo del club + minimapa del país del
    club. Fotos/escudos de Transfermarkt en `assets/`, minimapas con
    rnaturalearth en `assets/minimapas/`. ⚠️ revisar derechos de las fotos antes
    de publicar.

- 2026-05-26 (Pablo) 3ª ronda:
  - Card del mapa: zoom de CABA movido a un **panel a la derecha** de Argentina,
    con el **número de nacidos en CABA (0)** bien visible.
  - Galería: minimapas ahora son **zoom al contorno del país** (no el mundo).
    Argentina vía geoAr + Malvinas; resto = polígono principal del país.
  - Tabla rebrandeada a **Estación R**: header azul #405BFF, tipografía Ubuntu,
    striping gris claro #F7F7F7, texto negro #191919. Sin guiones largos.
  - PENDIENTE DECISIÓN: ¿rebrandear también las 4 cards (hoy en celeste/dorado
    temático) a la paleta Estación R? Consultado a Pablo.
- Marca oficial Estación R (de brand-enforcer): azul #405BFF, azul osc #1839F4,
  amarillo #EAFF38 (SOLO sobre negro), negro #191919, gris claro #F7F7F7;
  fuentes Array (títulos) + Ubuntu (cuerpo); nunca em dash (—) en copy.

- 2026-05-26 (Pablo) 4ª ronda:
  - **Brandeo total Estación R**: las 4 cards + HTML (barra narrativa negra
    #191919, números clave en amarillo #EAFF38 sobre negro, Ubuntu, azul #405BFF)
    + gráfico interactivo en azul. Tipografía Ubuntu en todo.
  - CABA: número SÓLO si nació alguien ahí. Como es 0, no muestra número; el
    zoom la pinta clara (0) como el resto, distinta de la provincia (16). Saqué
    el panel del "0". Los números van dentro del polígono como las provincias.
  - Estadísticas nuevas: propuesta enviada a Pablo (valor de mercado, goles,
    posiciones, ligas, clubes con más jugadores, campeones 2022, edad vs caps).

- 2026-05-26 (Pablo aprobó propuesta) — 3 estadísticas nuevas (`R/03_stats.R`):
  - 💰 Valor de mercado (€762,5M total; Enzo y Julián €90M) → `cards/05_valor.png`
  - 🏆 Ligas (LaLiga 7, Premier 5, Liga Arg 5...) → `cards/06_ligas.png`
  - ⭐ Campeones 2022: **15 de 29** (verificado: Nico González se lesionó y no
    cuenta; Almada sí) → `cards/07_campeones.png`
  - Las 3 integradas como secciones nuevas del HTML. Total: 7 cards + HTML.

- 2026-05-26 (Pablo) — Paletas de visualización ER (propuesta):
  - `R/paleta_estacion_r.R`: secuencial, divergente, cualitativa (ancladas en
    #405BFF, Lab, CVD-chequeadas). Escalas ggplot listas (scale_*_er_c/div/q).
  - `paleta_guia.png` (lámina con las 3 + simulación daltonismo) y
    `paleta_aplicada.png` (aplicadas a datos reales). Doc: `PALETA_PROPUESTA.md`.
  - Distinción clave: paleta de DATOS ≠ paleta de UI; el amarillo #EAFF38 se
    reserva para UI/acento sobre negro, no para codificar datos.
  - Propuesto incorporar a identidad_visual/GUIA_DE_ESTILO.md (pendiente OK Pablo).

- 2026-05-26 — Alternativas de paleta (`R/06_paleta_alternativas.R` →
  `paleta_alternativas.png`): A (un tono / azul+ámbar = propuesta original),
  B (bitono azul→amarillo, usa los 2 colores de marca, estilo cividis, máxima
  seguridad CVD), C (sobria/desaturada, editorial). Recomendación: B.

- 2026-05-27 (Pablo) — **Galería por líneas del equipo**: la sección (ahora
  "El plantel, línea por línea") muestra las 4 líneas — 🧤 Arqueros (3),
  🛡️ Defensores (12), 🎯 Mediocampistas (6), ⚽ Delanteros (8) — cada una con su
  tabla `gt` ordenada por caps. `R/02_galeria.R`: `build_galeria_gt(df, title,
  subtitle)` parametrizado + `build_galeria_linea(grupo)` (que ya quita el rol
  redundante bajo el nombre); el standalone exporta `galeria_<linea>.html`.
  - 1ª versión fue un `.panel-tabset` (pestañas). Pablo pidió que en el Quarto
    las líneas **aparezcan a medida que se scrollea** → reemplazado por secciones
    `.linea-reveal` con animación scroll-driven CSS nativa (`animation-timeline:
    view()`, con `@supports` + `prefers-reduced-motion` como fallback elegante).
  - Fix: el guard del bloque standalone de `02_galeria.R` ahora es sólo
    `sys.nframe() == 0`, para que knitr no regenere los HTML ni imprima `cat()`
    al renderizar el `.qmd`. El setup chunk va con `#| include: false`.

- 2026-05-27 (Pablo, 2ª ronda — respuestas a las preguntas abiertas):
  - **"Todos" va de vuelta**: re-agregada como cierre ("👥 El plantel completo",
    los 29 por caps). OJO: una tabla de 29 filas es muy alta para el reveal
    scroll-driven (se quedaba casi transparente), así que va SIN animación
    (clase `.galeria-todos`, no `.linea-reveal`).
  - **Reveal aprobado** ("se ve bien").
  - **Imágenes revisadas**: fotos 56px y minimapas 42px quedan bien; escudos
    subidos 30→34px (se leían chicos). En `R/02_galeria.R`.
  - **Fotos**: Pablo dijo NO preocuparse por los derechos → se publican.
  - **Paleta → guía central**: Pablo dio OK para versionar `paleta_estacion_r.R`
    y sumar la sección "Paletas de datos" a `identidad_visual/GUIA_DE_ESTILO.md`
    (ya no espera aprobación; queda por hacer).
  - **Más datos**: Pablo quiere revisar qué más sumar (ver Pendiente).
  - Nota infra: el render del `.qmd` (self-contained ~31MB) es pesado en RAM y
    en la máquina con poca memoria libre llegó a morir por OOM (exit 137);
    reintentar suele alcanzar. Assets son chicos (~1MB), no es por las imágenes.

- 2026-05-26 — Pablo eligió **dirección B**. Hecha oficial en
  `R/paleta_estacion_r.R` (ER_SEQ/ER_DIV = bitono azul-amarillo). Aplicada al
  mapa del proyecto (choropleth cividis, etiquetas con contraste por luminancia)
  y re-renderizado el HTML. Guía/aplicada/doc actualizados. Memoria guardada
  ([[paletas-datos-estacion-r]]).

- 2026-05-27 (Pablo) — **Goleadores** (idea elegida del set "más datos"):
  - Card `cards/08_goleadores.png` (`R/07_goleadores.R`): barras horizontales
    con la **foto circular** de cada jugador en la punta (magick recorta círculo
    a `assets/caras/`, ggtext `geom_richtext <img>` la ubica). Messi destacado
    (barra negra) + callout en espacio negativo "Messi metió 116 / 2 de cada 3".
    Nota: showtext (dpi 150) escala el `<img>` ~2x → usar width chico (22).
  - Sección "Los goles" en `index.qmd`: tarjetas "serie de datos" (`.stat-card`
    `.linea-reveal`, las clave en `.stat-dark` negro+amarillo) que aparecen al
    scrollear, + la card 08. Inspiración: headshots en barras (The MockUp) +
    resaltar un elemento y anotar en negativo (Cédric Scherer). Ver memoria
    [[dataviz-inspiracion-fuentes]] (recursos que pidió usar Pablo siempre).

- 2026-05-27 (Pablo) — **Auditoría de viz**: revisé las 8 contra las fuentes de
  inspiración. Veredicto: la mayoría OK; sugerí repensar **edades**.
  - Probé un **dot-plot apilado + caras** en edades, pero **Pablo prefirió la
    versión ANTERIOR** (jitter con labels de varios nombres: Mastantuono, Enzo,
    J. Álvarez, De Paul, Messi, Otamendi). **Revertida**. ⚠️ Aprendizaje de gusto:
    no asumir que el rediseño "más editorial/minimal" gana; a Pablo le gustó la
    versión con más nombres etiquetados. Ante la duda, mostrar opciones.
  - **Fix de etiquetas (pedido de Pablo)**: que no se superpongan. ggrepel ahora
    repele de TODOS los puntos (se pasan todos con etq "" como obstáculo) + puntos
    falsos sobre la línea del promedio para que las labels no la crucen; el label
    "Promedio" lleva fondo blanco (`annotate("label", fill=blanco)`). Sin solapes.
  - **Caps con caras**: probado y REVERTIDO. Las barras largas (Messi 198 llena
    el ancho) hacen que la cara se monte sobre la barra y tape el dato → las
    caras sólo sirven en barras cortas (goleadores). Caps queda limpia.
  - `make_circle` factorizado a `R/_caras.R` (lo usa 07_goleadores.R; 01_cards.R
    volvió a NO usarlo tras revertir edades).
  - Pendientes opcionales NO hechos (sugeridos a Pablo): escala por tramos en el
    mapa; diferenciar los dos waffles (exterior/campeones); pasar el dot-plot al
    gráfico interactivo de edades del HTML (hoy sigue con jitter).

## 2026-05-29 (Pablo, ronda de feedback completa) — APLICADO
Pablo mandó 3 capturas (mapa cortado, edad chico, mochila cortada) + 11 cambios,
y después un 12º (ligas → tabla con caras). Todo aplicado y verificado.
**Modelo del agente subido a Opus 4.8.**

| # | Pedido | Resolución |
|---|--------|-----------|
| 1 | Mapa: etiqueta en TODA provincia con ≥1 | `cents` filtra `jugadores >= 1` (antes ≥2). Aparecen Entre Ríos/La Pampa/San Luis/Tucumán con su "1". `R/01_cards.R` |
| 2 | Mapa cortado al sur (HTML) | Era el sticky del closeread. CSS `.cr-section img { max-height:86vh; object-fit:contain }`. Entra hasta T. del Fuego + Malvinas. `index.qmd` |
| 3 | Edad chico → grande + annotator | Nuevo `R/_edad_plot.R` (jitter + promedio + **flechas curvas** a Barco / Otamendi-Messi). Card (retrato) + HTML (apaisado inline, `fig-width:9.2`). |
| 4 | Mochila cortada (HTML) | Mismo fix CSS max-height. |
| 5 | Exportación: otro gráfico (no repetir waffle) | **Barra de proporción 100%** (24 exterior + astilla negra con callout a los 2 locales). `R/01_cards.R` |
| 6 | Valor: no aparece Messi | Antes top-12. Ahora **los 26 coloreados por posición**. `R/03_stats.R` |
| 7 | Ligas: NA + escudo + país subtítulo | NA = Inter/Man Utd/Betis (faltaban). Logos `assets/ligas/`. `geom_col(orientation="y")` o salen verticales. `element_markdown` en ejes NO va con showtext → `geom_richtext`. `R/03_stats.R` |
| 8 | Campeones: caras + nombre | Grilla 6 cols, caras color/gris (`make_circle(gray=TRUE)`) + apellido. `R/03_stats.R`, `R/_caras.R` |
| 9 | Goles: sólo gráfico | Borradas las 5 `.stat-card`. `index.qmd` |
| 10 | Plantel línea-por-línea PRIMERO + convocados + seguido de campeones 2022 | Reordenado. `index.qmd` |
| 11 | Quitar tabla plantel entero | Borrado el `build_galeria_gt()` de los 26. `index.qmd` |
| 12 | Ligas → **tabla con caras** (quiénes + cuántos) | Nuevo `R/06_ligas_tabla.R`: gt, 1 fila por liga (logo+nombre+país · N · caras+apellido). `club_liga`/`liga_meta` movidos a `00_prep.R` (fuente única). Embebida en el HTML reemplazando la card 06. |

**Nuevos assets:** `assets/ligas/*.png` (9 logos), `R/_edad_plot.R`, `R/06_ligas_tabla.R`,
`ligas_tabla.html`, `cards/06_ligas_tabla.png`, `R/_shoot_html.py` + `R/_shoot_tabla.py`,
`previews/html_*.png`.
⚠️ Aprendizajes infra: (a) `geom_col` con eje y numérico necesita `orientation="y"`;
(b) `element_markdown` en ejes NO renderiza con showtext, usar `geom_richtext`; (c) el viewer
de imágenes interno se puso intermitente (placeholders) — `identify`/PIL siguen confiables;
(d) **Playwright es paquete Python** en `~/.local/lib/python3.12`, correr con `python3`
(NO node); el browser bundled apunta a build inexistente → pasar `executable_path` al chromium
de `~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`; (e) `mcp message upload-file`
sólo acepta rutas dentro del workspace (NO `/tmp`) → copiar a `previews/` antes de enviar.
Pendiente: OK de Pablo → publicar (HTML al blog + cards a redes).

## 2026-05-30 (Pablo) — verificación CABA + hallazgo en el scroll
- Pablo pidió **verificar que ninguno de los 14 "provincia BA" naciera en CABA**
  (la Ciudad no es parte de la provincia). Revisado uno por uno (dudosos con web_search
  vs Wikipedia ES/EN + fuentes locales): los 14 son de partidos del Gran Buenos Aires o
  interior bonaerense. Casos que se prestaban a confusión: **Otamendi → El Talar (Tigre)**,
  **Nico González → Belén de Escobar (Escobar)**. Confirmado: **14 provincia, 0 CABA**.
  El dato del mapa está correcto, no se cambió nada.
- Pablo: "rescatemos eso como hallazgo entre los datos mientras hacemos el scroll".
  En `index.qmd`, sección del mapa (`cr-section`), el dato CABA pasó de nota al pie a
  **hallazgo destacado**: beat "Pero acá hay un dato que sorprende: de la Ciudad… no nació
  **ninguno**" (con `ninguno` en `.cr-hl` amarillo) + beat "Cuidado con la trampa: esos 14
  porteños son bonaerenses del conurbano/interior. De CABA, cero." HTML re-renderizado y
  screenshot (`previews/html_hallazgo.png`) enviado. Esperando OK de fraseo.

## 🟡 ABIERTO — Sesión próxima retoma desde acá (a 2026-05-29 03:00 CST)
Estado al cierre: proyecto **regenerado con los 26 oficiales** y HTML
re-renderizado. Las 8 cards y la galería están listas; Pablo las recibió todas
por Discord y arrancó una revisión de **rótulos / categorías** (uso interno y
para los posts en redes — todavía sin confirmar si tocamos también los títulos
ON-card o sólo los rótulos de catálogo). Cambios pedidos:

| # | Card                | Rótulo viejo  | Rótulo nuevo de Pablo            |
|---|---------------------|---------------|----------------------------------|
| 1 | 01_mapa_origenes    | Orígenes      | **Origen**                       |
| 2 | 02_edad             | Edades        | **Edad**                         |
| 3 | 03_caps             | Caps          | **Experiencia**                  |
| 4 | 04_exterior         | Exterior      | **Liga Argentina vs exterior**   |
| 5 | 05_valor            | Valor         | ✅ queda                          |
| 6 | 06_ligas            | Ligas         | **Liga**                         |
| 7 | 07_campeones        | Campeones     | ✅ queda                          |
| 8 | 08_goleadores       | Goleadores    | **Goleador**                     |

**Pablo cerró la sesión con**: "No ejecutes aún, sigo revisando cosas". O sea,
puede haber más cambios cuando vuelva. La próxima sesión: esperar lista final,
confirmar si los rótulos son sólo de catálogo/posts o también títulos ON-card,
y recién ahí aplicar.

Después de eso queda **publicar**: HTML al blog + cards a redes (con los
rótulos finales como categoría del post).

---

## Resuelto con Pablo (2026-05-27, 2ª ronda)
- Vista "Todos" ✅ va (sin reveal). Reveal ✅ aprobado. Imágenes ✅ (escudos 34px).
- Fotos ✅ se publican (Pablo no se preocupa por derechos). Paleta→guía ✅ con OK.

## Pendiente / próximos pasos
- [ ] **Más datos**: goleadores ✅ hecho. Quedan candidatos por si suma: clubes
      con más jugadores (Atlético 6...), el plantel por el mundo (países/destinos),
      edad vs caps.
- [ ] Versionar `paleta_estacion_r.R` como asset compartido + sección "Paletas
      de datos" en `identidad_visual/GUIA_DE_ESTILO.md` (Pablo ya dio OK).
- [x] ~~Actualizar con la lista oficial de 26 cuando salga.~~ ✅ HECHO 2026-05-28
      (anuncio confirmado por Scaloni; rutina desactivada; pipeline regenerado
      con `R/00_scrape.R`). Para futuras ventanas, correr de nuevo `00_scrape.R`.
- [ ] Publicar: subir HTML al blog + exportar cards definitivas.
- [ ] (Opcional) marca Estación R / logo en las cards.

- 2026-05-28 — **Lista oficial 26 anunciada por Scaloni** (confirmada con
  Infobae + La Nación). Rutina remota desactivada (ya no hace falta el daily check).
  Re-generación COMPLETA del proyecto con los 26 oficiales:
  - **`R/00_scrape.R` (nuevo)**: scraper rvest+httr de Transfermarkt. Squad page
    (URL: argentinien/startseite/verein/3437) + perfil de cada uno. Extrae shirt,
    name, pos, dob, age, club, mv, caps, goals_nt, pob. También baja fotos y
    escudos y reescribe `data/img_urls.rds`. Invalida la caché de caras circulares.
    Polite (UA realista + sleep 1.2s entre requests). Backup automático del CSV viejo.
  - **6 altas**: Montiel, Lisandro Martínez, Balerdi, Facundo Medina, Lo Celso,
    Lautaro Martínez. **9 bajas**: Acuña, Senesi, Mastantuono, M. Quarta, Rojas,
    Giay, T. Palacios, Perrone, Prestianni.
  - **`R/00_prep.R`**: agregados 5 lugares nuevos a `ciudad_prov` (Gualeguay→Entre
    Ríos, Villa Mercedes→**San Luis** [nueva provincia en dataset], Villa Fiorito,
    González Catán, Bahía Blanca → BA). Fix de dos textos truncados ("San Nicolás
    de los Arroyos", "Santa Cruz de Tenerife").
  - **`R/03_stats.R`**: `campeones_2022` actualizada (+Lautaro, +Lisandro, +Montiel;
    -Acuña). 17 campeones en los 26.
  - **`R/02_galeria.R`**: agregados al `club_pais` (Inter Milan→Italia,
    Manchester United→Inglaterra, Real Betis Balompié→España).
  - **Cards 01 mapa, 04 exterior, 07 campeones**: refactorizadas a totales
    **dinámicos** (`nrow(plantel)`, `por_provincia`, `n_camp`). Adios al "29"
    hardcodeado en todo el proyecto.
  - **`index.qmd`**: copy reescrito en todas las secciones. Highlights del nuevo
    plantel: edad prom 28.6 (era 27.7), más joven Barco 21 (Mastantuono 18 era
    el del 29), 14 en BA, 24 de 26 exterior, sólo Paredes/Boca + Montiel/River
    locales, €801 M, **218 goles totales** (era 175), 17 campeones de 26.
  - **Sección "Los goles"**: 5 stat-cards (218 / 116 / Más de la mitad / **36 de
    Lautaro** / 7 sin gol). El callout del gráfico pasó de "2 de cada 3" a
    "Más de la mitad" (53 % real, antes 67 %).
  - HTML renderizado OK al 1er intento (~30 MB self-contained). Verificado.

## Aprendizajes técnicos (reusables)
- **Render OOM**: el `.qmd` self-contained (~31MB, ggiraph + 5 tablas gt con
  imágenes base64) es pesado en RAM. En esta máquina (Positron come varios GB,
  ~2GB libres) el render muere con **exit 137** (OOM). Solución: reintentar
  (loop de 2-3 intentos). Los assets son chicos (~1MB), no son la causa.
- **Reveal scroll-driven** (`animation-timeline: view()`): funciona para
  elementos cortos (tablas de 3-12 filas, stat-cards). Para elementos MUY altos
  (tabla de 29 filas) el rango "entry" es enorme y quedan casi transparentes →
  esos van SIN animación. Fallback con `@supports` + `prefers-reduced-motion`.
- **Caras en barras sin ggimage** (no está instalado; tampoco cropcircles/
  gtExtras): recortar círculo con `magick` (crop cuadrado desde arriba + máscara
  circular `CopyOpacity`, helper en `R/_caras.R`) y ubicar con
  `ggtext::geom_richtext` `<img>`. OJO: `showtext` a dpi 150 escala el `<img>`
  ~2x → usar `width` chico (~22). Y `fill` de highlight va en el `geom_col`, NO
  en el `aes()` global, o las capas de caras fallan ("objeto es_messi no encontrado").
- **Caras sólo en barras CORTAS**: en barras largas (caps: Messi llena el ancho)
  la cara se monta sobre la barra y tapa el número. Sirve para rankings de
  valores chicos (goleadores) o como marcador de extremos en un dot-plot (edades).
- **Side-effect de source en knitr**: guardar standalone sólo con
  `if (sys.nframe() == 0)` para que el `source()` desde el chunk no regenere
  archivos ni imprima `cat()`. Chunk de setup con `#| include: false`.
- **Screenshots de verificación**: ver memoria [[entorno-screenshots-playwright]].
- **Scraping de Transfermarkt**: `WebFetch` lo bloquea (anti-bot); `curl`/`httr`
  con User-Agent realista funciona OK. Selectores clave en `R/00_scrape.R`:
  squad table = `table.items > tbody > tr`; portrait = `img.bilderrahmen-fixed`
  data-src; club crest URL = `https://tmssl.akamaized.net/images/wappen/medium/<id>.png`
  (id desde `/verein/<id>` en la URL del club); caps/goals con la Selección =
  `li.data-header__label` con texto "Caps/Goals:" y dos `a.data-header__content`.
- **Refactor anti-hardcoded**: cuando hay un número grande visible (29, 16, etc.)
  conviene calcularlo siempre con `nrow(plantel)` / agregados de `00_prep.R`. Hoy
  rompe en el próximo cambio si está hardcodeado.

## Cómo regenerar todo
```bash
cd proyectos/datos-futboleros-argentina
Rscript R/01_cards.R       # datos + cards 1-4
Rscript R/03_stats.R       # cards 5-7 (valor, ligas, campeones)
Rscript R/07_goleadores.R  # card 8 (goleadores con caras; usa magick + ggtext)
Rscript R/02_galeria.R     # output/galeria.html + output/galeria_<linea>.html
quarto render index.qmd    # HTML scrollytelling → index.html
```
Nota: al renderizar el `.qmd`, `02_galeria.R` se sourcea pero NO regenera los
HTML standalone (guard `sys.nframe() == 0`); eso sólo pasa al correrlo con Rscript.

## Scripts utilitarios (verificación con Playwright)
```bash
python3 scripts/shoot_html.py      # screenshots del HTML completo
python3 scripts/shoot_revision.py  # revisión de las 12 piezas → previews/revision/
python3 scripts/shoot_scatter.py   # screenshot del scatter interactivo
python3 scripts/shoot_tabla.py     # screenshot de la tabla de ligas
python3 scripts/shoot_widget.py    # screenshot de un widget ggiraph
```
