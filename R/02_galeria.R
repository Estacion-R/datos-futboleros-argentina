# ==========================================================================
# 02_galeria.R — Galería de los 29: foto + escudo del club + minimapa del país
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

# Plan B legal: SIN_FOTOS=1 arma la galería SIN la columna de fotos de jugador
# (las fotos de Transfermarkt son de agencias con copyright; la atribución no es
# licencia comercial). Escudos y minimapas se mantienen. Default = con fotos.
SIN_FOTOS <- Sys.getenv("SIN_FOTOS", "0") == "1"

suppressMessages({
  library(dplyr); library(stringr); library(ggplot2); library(gt)
  library(sf); library(rnaturalearth); library(tibble); library(purrr); library(ragg)
})

# Marca Estación R (paleta oficial)
ER_AZUL <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7"; ER_BLANCO <- "#FFFFFF"

# --- Club -> país ----------------------------------------------------------
club_pais <- tribble(
  ~club,                            ~pais_club,       ~admin,
  "AFC Bournemouth",                "Inglaterra",     "United Kingdom",
  "Aston Villa",                    "Inglaterra",     "United Kingdom",
  "Atlético de Madrid",             "España",         "Spain",
  "Bayer 04 Leverkusen",            "Alemania",       "Germany",
  "CA Boca Juniors",                "Argentina",      "Argentina",
  "CA River Plate",                 "Argentina",      "Argentina",
  "Chelsea FC",                     "Inglaterra",     "United Kingdom",
  "Club Estudiantes de La Plata",   "Argentina",      "Argentina",
  "Como 1907",                      "Italia",         "Italy",
  "Inter Miami CF",                 "Estados Unidos", "United States of America",
  "Inter Milan",                    "Italia",         "Italy",
  "Liverpool FC",                   "Inglaterra",     "United Kingdom",
  "Manchester United",              "Inglaterra",     "United Kingdom",
  "Olympique Lyon",                 "Francia",        "France",
  "Olympique Marseille",            "Francia",        "France",
  "Racing Club",                    "Argentina",      "Argentina",
  "RC Strasbourg Alsace",           "Francia",        "France",
  "Real Betis Balompié",            "España",         "Spain",
  "Real Madrid",                    "España",         "Spain",
  "SL Benfica",                     "Portugal",       "Portugal",
  "Sociedade Esportiva Palmeiras",  "Brasil",         "Brazil",
  "Tottenham Hotspur",              "Inglaterra",     "United Kingdom"
)

# --- Minimapas por país ----------------------------------------------------
dir.create(file.path(ROOT, "assets/minimapas"), showWarnings = FALSE, recursive = TRUE)
mundo <- ne_countries(scale = "medium", returnclass = "sf")

minimap_path <- function(admin) file.path(ROOT, "assets/minimapas",
  paste0(str_replace_all(str_to_lower(admin), "[^a-z]+", "_"), ".png"))

# Zoom al contorno del país (no el mundo entero).
# Argentina: geometría de geoAr (incluye Malvinas, regla del proyecto).
# Resto: polígono principal del país (excluye territorios lejanos / antimeridiano).
make_minimap <- function(admin) {
  out <- minimap_path(admin)
  if (file.exists(out)) return(out)
  if (admin == "Argentina") {
    geom <- sf::st_union(provincias_sf)
    bb <- sf::st_bbox(geom)
  } else {
    geom <- sf::st_geometry(mundo[mundo$admin == admin, ])
    parts <- suppressWarnings(sf::st_cast(geom, "POLYGON"))
    geom <- parts[which.max(sf::st_area(parts))]
    bb <- sf::st_bbox(geom)
  }
  mx <- as.numeric(bb["xmax"] - bb["xmin"]) * 0.10
  my <- as.numeric(bb["ymax"] - bb["ymin"]) * 0.10
  g <- ggplot() +
    geom_sf(data = geom, fill = ER_AZUL, color = "white", linewidth = 0.25) +
    coord_sf(xlim = c(bb["xmin"] - mx, bb["xmax"] + mx),
             ylim = c(bb["ymin"] - my, bb["ymax"] + my), expand = FALSE) +
    theme_void() +
    theme(plot.background = element_rect(fill = ER_BLANCO, color = "#E3E3E3"),
          panel.background = element_rect(fill = ER_BLANCO, color = NA),
          plot.margin = margin(2, 2, 2, 2))
  ggsave(out, g, width = 2.6, height = 2.2, dpi = 120, device = ragg::agg_png)
  out
}
walk(unique(club_pais$admin), make_minimap)

# --- Data de la galería (HTML de cada celda pre-construido) -----------------
img <- readRDS(file.path(ROOT, "data/img_urls.rds")) |>
  select(name, foto_file, escudo_file)

galeria_df <- plantel |>
  left_join(img, by = "name") |>
  left_join(club_pais, by = "club") |>
  arrange(desc(caps)) |>
  mutate(
    foto_path   = file.path(ROOT, foto_file),
    escudo_path = file.path(ROOT, escudo_file),
    mapa_path   = map_chr(admin, minimap_path),
    Foto = if (SIN_FOTOS) "" else map_chr(foto_path, ~local_image(.x, height = 56)),
    Jugador = paste0("<strong>", name, "</strong><br>",
                     "<span style='color:#6F6F6F;font-size:12px'>", pos_grupo, "</span>"),
    Club = paste0(map_chr(escudo_path, ~local_image(.x, height = 34)),
                  " &nbsp;<span style='font-size:13px'>", club, "</span>"),
    `País del club` = paste0(map_chr(mapa_path, ~local_image(.x, height = 42)),
                  "<br><span style='font-size:11px;color:#6F6F6F'>", pais_club, "</span>")
  ) |>
  select(pos_grupo, Foto, Jugador, Edad = age, Caps = caps, Club, `País del club`)

# --- Líneas del equipo (hojas por posición) ---------------------------------
LINEAS       <- c("Arquero", "Defensor", "Mediocampista", "Delantero")
LINEA_LABEL  <- c(Arquero = "Arqueros", Defensor = "Defensores",
                  Mediocampista = "Mediocampistas", Delantero = "Delanteros")
LINEA_EMOJI  <- c(Arquero = "🧤", Defensor = "🛡️",
                  Mediocampista = "🎯", Delantero = "⚽")

# --- Construcción del gt ----------------------------------------------------
# `df` puede venir filtrado por línea; se quita pos_grupo antes de renderizar.
build_galeria_gt <- function(df = galeria_df,
                             title = "**El plantel, cara por cara**",
                             subtitle = "Los 29 con su club y el país donde juegan") {
  if (SIN_FOTOS) df <- df |> select(-any_of("Foto"))
  md_cols     <- intersect(c("Foto", "Jugador", "Club", "País del club"), names(df))
  center_cols <- intersect(c("Foto", "Edad", "Caps", "País del club"), names(df))
  fuente_nota <- if (SIN_FOTOS)
    "*Datos: Transfermarkt · Mapas: rnaturalearth (geoAr para Argentina) · Escudos: clubes · Estación R*"
  else
    "*Datos e imágenes: Transfermarkt · Mapas: rnaturalearth (geoAr para Argentina) · Estación R*"
  df |>
    select(-any_of("pos_grupo")) |>
    gt() |>
    fmt_markdown(columns = all_of(md_cols)) |>
    cols_align("center", columns = all_of(center_cols)) |>
    cols_align("left", columns = c(Jugador, Club)) |>
    tab_header(title = md(title), subtitle = subtitle) |>
    tab_source_note(md(fuente_nota)) |>
    # Nombre de fuente como string (NO google_font): la página ya carga Ubuntu
    # vía el <link> del header; google_font() embebía el TTF por tabla (~17 MB en
    # 5 tablas) y disparaba el OOM del render.
    opt_table_font(font = c("Ubuntu", "sans-serif")) |>
    tab_options(
      heading.title.font.size = px(24),
      heading.subtitle.font.size = px(14),
      heading.title.font.weight = "bold",
      column_labels.background.color = ER_AZUL,
      column_labels.font.weight = "bold",
      column_labels.text_transform = "uppercase",
      table.font.color = ER_NEGRO,
      heading.background.color = ER_BLANCO,
      row.striping.include_table_body = TRUE,
      row.striping.background_color = ER_GRIS,
      table_body.hlines.color = "#ECECEC",
      data_row.padding = px(7),
      table.border.top.color = ER_AZUL,
      table.border.top.width = px(3),
      table.width = px(760)
    )
}

# Una "hoja" por línea: filtra galeria_df a la posición y arma su propia tabla.
build_galeria_linea <- function(grupo, df = galeria_df) {
  d <- df |> filter(pos_grupo == grupo) |> arrange(desc(Caps)) |>
    # dentro de su propia hoja, el rol bajo el nombre es redundante: se quita
    mutate(Jugador = str_remove(Jugador, "<br><span[^>]*>[^<]*</span>$"))
  n <- nrow(d)
  build_galeria_gt(
    d,
    title    = paste0("**", LINEA_EMOJI[[grupo]], " ", LINEA_LABEL[[grupo]], "**"),
    subtitle = paste0(n, if (n == 1) " jugador" else " jugadores",
                      " · ordenados por partidos con la Selección")
  )
}

galeria_gt <- build_galeria_gt()

# Guardado standalone (HTML) — sólo al correr `Rscript R/02_galeria.R`,
# no cuando lo sourcea knitr al renderizar el .qmd (ahí sys.nframe() > 0).
if (sys.nframe() == 0) {
  dir.create(file.path(ROOT, "output"), showWarnings = FALSE)
  gtsave(galeria_gt, file.path(ROOT, "output", "galeria.html"))
  cat("✔ output/galeria.html · minimapas:", length(unique(club_pais$admin)),
      "· jugadores:", nrow(galeria_df), "\n")
  for (g in LINEAS) {
    out <- file.path(ROOT, "output", paste0("galeria_", tolower(g), ".html"))
    gtsave(build_galeria_linea(g), out)
  }
  cat("✔ hojas por línea:", paste(LINEA_LABEL[LINEAS], collapse = " · "), "\n")
}
