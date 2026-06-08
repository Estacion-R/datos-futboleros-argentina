# El plantel de la Selección, en datos

Informe interactivo de [Estación R](https://estacion-r.com/) sobre el plantel argentino rumbo al **Mundial 2026**: orígenes geográficos, edades, caps, ligas, valores de mercado y trayectoria mundialista.

Construido en **R + Quarto** con scrollytelling ([closeread](https://closeread.dev/)) y gráficos interactivos ([ggiraph](https://davidgohel.github.io/ggiraph/)).

🔗 **Ver el informe:** <https://estacion-r.github.io/datos-futboleros-argentina/>

---

## Secciones del informe

| # | Sección | Tipo |
|---|---------|------|
| 1 | Galería del plantel (fotos + escudo + minimapa por país) | Tabla interactiva (gt) |
| 2 | Campeones del mundo en Qatar 2022 | Cards closeread |
| 3 | Mapa de orígenes por provincia | ggbump + sf |
| 4 | Distribución de edades | Beeswarm + ggbeeswarm |
| 5 | Experiencia mundialista (partidos × mundiales) | Scatter interactivo (ggiraph) |
| 6 | Jugadores en el exterior | Cards closeread |
| 7 | Valor de mercado | Packing chart interactivo (ggiraph) |
| 8 | Goleadores históricos de la era Scaloni | Cards closeread |
| 9 | El plantel en la cancha (por posición + cuerpo técnico) | Imágenes closeread |

---

## Estructura del repositorio

```
datos-futboleros-argentina/
├── index.qmd                   # Documento principal (fuente del informe)
├── index.html                  # Informe renderizado (GitHub Pages)
│
├── R/                          # Scripts de análisis y visualización
│   ├── 00_paleta.R             # Paleta oficial Estación R para ggplot2
│   ├── 01_scrape.R             # Obtención de datos (scraping Transfermarkt)
│   ├── 02_prep.R               # Carga, limpieza y variables derivadas  ← sourced
│   ├── 03_viz_edad.R           # Visualización de distribución de edades ← sourced
│   ├── 04_galeria.R            # Tabla-galería con fotos y escudos        ← sourced
│   ├── 05_stats.R              # Cards PNG: mapa, caps, exterior, goleadores, cancha
│   ├── 06_valor_packing.R      # Packing chart interactivo (ggiraph)      ← sourced
│   ├── 07_scatter.R            # Scatter caps × mundiales (ggiraph)       ← sourced
│   ├── 08_cards.R              # Cards PNG para redes sociales
│   ├── 09_cancha.R             # Plantel sobre cancha (por posición)
│   └── _archivo/               # Scripts de exploración (referencia, no necesarios para reproducir)
│
├── data/                       # Datasets del proyecto
│   ├── plantel_argentina.csv   # Plantel completo (fuente principal)
│   ├── permanencia_arg.csv     # Tasa de permanencia mundialista
│   └── provincias.geojson      # Geometrías de provincias argentinas
│
├── assets/                     # Recursos visuales
│   ├── caras/                  # Fotos circulares de jugadores
│   ├── fotos/                  # Fotos completas de jugadores
│   ├── fotos_ct/               # Fotos del cuerpo técnico
│   ├── escudos/                # Escudos de clubes (PNG)
│   ├── ligas/                  # Logos de ligas (PNG)
│   └── minimapas/              # Mapas de países (PNG)
│
├── cards/                      # Visualizaciones exportadas (PNG)
├── scripts/                    # Scripts auxiliares (Playwright, capturas de pantalla)
└── _extensions/qmd-lab/closeread/  # Extensión Quarto closeread
```

Los scripts marcados con ← sourced son llamados directamente desde `index.qmd` al renderizar.

---

## Cómo reproducir el análisis

### Requisitos

- R ≥ 4.3
- Quarto ≥ 1.5
- Paquetes R:

```r
install.packages(c(
  "tidyverse", "sf", "ggbeeswarm", "ggforce", "ggtext",
  "gt", "gtExtras", "ggiraph", "worldfootballR",
  "patchwork", "showtext", "sysfonts", "gdtools",
  "magick", "rvest", "polite"
))

# geoAr (geometrías de Argentina con Malvinas incluidas)
install.packages("geoAr", repos = c("https://cloud.r-project.org"))
```

### Pasos

1. Clonar el repositorio

```bash
git clone https://github.com/Estacion-R/datos-futboleros-argentina.git
cd datos-futboleros-argentina
```

2. Los datos ya están incluidos en `data/`. Para regenerarlos desde la fuente (Transfermarkt vía scraping), correr `R/01_scrape.R`. **Nota:** el scraping puede tardar varios minutos.

3. Renderizar el informe:

```bash
quarto render index.qmd
```

4. Para regenerar las cards de redes sociales (PNG), correr `R/08_cards.R` y `R/05_stats.R`.

---

## Datos y atribuciones

- **Datos del plantel** recopilados vía scraping de Transfermarkt. Las fotos e imágenes de jugadores se usan con fines educativos y de divulgación.
- **Geometrías de Argentina** vía paquete [`geoAr`](https://github.com/PoliticaArgentina/geoAr) (incluye las Islas Malvinas).
- **Datos de mundiales** vía paquete [`worldcup`](https://github.com/jfjelstul/worldcup) (Fjelstul World Cup Database).

---

## Sobre Estación R

[Estación R](https://estacion-r.com/) es un proyecto de formación en R orientado a ciencias sociales y sector público: cursos, talleres y podcast.

Seguinos en [Instagram](https://instagram.com/estacion.r), [LinkedIn](https://linkedin.com/company/estacion-r) y [YouTube](https://youtube.com/@estacionr).

---

Hecho con R por [Estación R](https://estacion-r.com/)
