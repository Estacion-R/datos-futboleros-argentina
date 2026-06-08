# ==========================================================================
# 07_goleadores.R — Goleadores con la Selección. Bar chart con caras (magick
# + ggtext). Messi destacado: 116 de 175 goles del plantel (2 de cada 3).
# Inspiración: rankings con headshots (The MockUp) + anotación editorial
# en espacio negativo y resalte de un único elemento (Cédric Scherer).
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

suppressMessages({
  library(dplyr); library(stringr); library(ggplot2); library(ggtext)
  library(magick); library(ragg)
})

# --- Marca Estación R -------------------------------------------------------
ER_AZUL <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7"; ER_BLANCO <- "#FFFFFF"; GRIS_TXT <- "#6F6F6F"
ok_font <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu", "ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
FF <- if (ok_font) "ubuntu" else "sans"

# Plan B legal: SIN_FOTOS=1 omite las caras en la punta de cada barra (las barras
# y los números cuentan la historia igual). Default = con caras.
SIN_FOTOS <- Sys.getenv("SIN_FOTOS", "0") == "1"

# --- Caras circulares (helper compartido, cache en assets/caras) ------------
source(file.path(ROOT, "R/_caras.R"))

# --- Datos: top goleadores --------------------------------------------------
img <- readRDS(file.path(ROOT, "data/img_urls.rds")) |> select(name, foto_file, slug)
total_g <- sum(plantel$goals_nt)
sin_gol <- sum(plantel$goals_nt == 0)

short_name <- function(x) {
  x <- str_replace(x, "^Lionel Messi$", "Messi")
  x <- str_replace(x, "^Julián Álvarez$", "J. Álvarez")
  x <- str_replace(x, "^(\\S)\\S+\\s+(.+)$", "\\1. \\2")  # "Nicolás Otamendi" -> "N. Otamendi"
  x
}

gol <- plantel |>
  filter(goals_nt > 0) |>
  arrange(desc(goals_nt)) |>
  slice_head(n = 8) |>
  left_join(img, by = "name") |>
  mutate(
    cara  = if (SIN_FOTOS) NA_character_ else
            mapply(function(f, s) make_circle(file.path(ROOT, f),
                     file.path(ROOT, "assets/caras", paste0(s, ".png"))), foto_file, slug),
    nombre = short_name(name),
    es_messi = name == "Lionel Messi",
    nombre = factor(nombre, levels = rev(nombre))   # mayor arriba
  )

# showtext (dpi 150) escala el <img> de gridtext ~2x, así que un width chico basta
FACE_PX <- 22
gol$label <- sprintf("<img src='%s' width='%d'/>", gol$cara, FACE_PX)
xmax <- max(gol$goals_nt) * 1.30
messi_g   <- max(gol$goals_nt)
pct_messi <- round(messi_g / total_g * 100)   # % de los goles del plantel que son de Messi
con_gol   <- sum(plantel$goals_nt > 0)         # jugadores que ya marcaron al menos una vez

# Capa de caras (NULL en modo SIN_FOTOS → ggplot la ignora).
cara_layer <- if (SIN_FOTOS) NULL else
  geom_richtext(aes(x = goals_nt, label = label), hjust = 0, nudge_x = xmax * 0.006,
                fill = NA, label.color = NA, label.padding = unit(0, "pt"))

# --- Plot -------------------------------------------------------------------
# Layout por fila: a la IZQUIERDA nombre (negro) + posición (gris) debajo; luego
# barra · cara (en la punta) · número en oscuro. Recuadro de marca (negro+amarillo)
# con el % de los goles que aporta Messi, en el espacio negativo abajo-derecha.
p <- ggplot(gol, aes(goals_nt, nombre)) +
  geom_col(aes(fill = es_messi), width = 0.66) +
  # etiquetas a la izquierda: nombre + posición (gris) debajo
  geom_text(aes(label = nombre), x = -xmax * 0.015, hjust = 1, nudge_y = 0.085,
            family = FF, fontface = "bold", size = 4.8, color = ER_NEGRO) +
  geom_text(aes(label = pos_grupo), x = -xmax * 0.015, hjust = 1, nudge_y = -0.16,
            family = FF, size = 3.2, color = GRIS_TXT) +
  cara_layer +
  geom_text(aes(x = goals_nt, label = goals_nt), hjust = 0,
            nudge_x = if (SIN_FOTOS) xmax * 0.02 else xmax * 0.082,
            color = ER_NEGRO, family = FF, fontface = "bold", size = 5.2) +
  # UNA sola caja de marca (negro + amarillo) con las dos estadísticas clave,
  # separadas por una línea tenue.
  annotate("rect", xmin = xmax * 0.42, xmax = xmax * 0.99, ymin = 0.48, ymax = 4.55,
           fill = ER_NEGRO) +
  annotate("text", x = xmax * 0.705, y = 3.92, label = paste0(pct_messi, "%"),
           family = FF, fontface = "bold", size = 12, color = ER_AMARILLO) +
  annotate("text", x = xmax * 0.705, y = 3.06, lineheight = 1.0,
           label = "de todos los goles del\nplantel los hizo Messi",
           family = FF, fontface = "bold", size = 3.6, color = "white") +
  annotate("segment", x = xmax * 0.50, xend = xmax * 0.91, y = 2.52, yend = 2.52,
           color = "#4A4A4A", linewidth = 0.5) +
  annotate("text", x = xmax * 0.705, y = 1.78, label = paste0(con_gol, " de ", nrow(plantel)),
           family = FF, fontface = "bold", size = 9, color = ER_AMARILLO) +
  annotate("text", x = xmax * 0.705, y = 0.92, lineheight = 1.0,
           label = "convirtieron al menos\nuna vez con la Selección",
           family = FF, fontface = "bold", size = 3.6, color = "white") +
  scale_fill_manual(values = c(`FALSE` = ER_AZUL, `TRUE` = ER_NEGRO), guide = "none") +
  scale_x_continuous(limits = c(-xmax * 0.5, xmax), expand = expansion(mult = c(0, 0))) +
  coord_cartesian(clip = "off") +
  labs(title = "¿Quién mete los goles?",
       subtitle = "Goles con la Selección mayor · plantel actual",
       caption = if (SIN_FOTOS) "Datos: Transfermarkt · Estación R"
                 else "Datos e imágenes: Transfermarkt · Estación R") +
  theme_minimal(base_family = FF) +
  theme(
    plot.background = element_rect(fill = ER_BLANCO, color = NA),
    panel.background = element_rect(fill = ER_BLANCO, color = NA),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = element_text(face = "bold", size = 30, color = ER_NEGRO),
    plot.subtitle = element_text(size = 15, color = GRIS_TXT, margin = margin(t = 4, b = 16)),
    plot.caption = element_text(size = 11.5, color = GRIS_TXT, hjust = 0,
                                lineheight = 1.1, margin = margin(t = 18)),
    plot.margin = margin(34, 40, 26, 34),
    axis.title = element_blank(),
    axis.text = element_blank(),
    panel.grid = element_blank())

# --- Guardado ---------------------------------------------------------------
if (sys.nframe() == 0) {
  out_gol <- if (SIN_FOTOS) "08_goleadores_sf.png" else "08_goleadores.png"
  ggsave(file.path(ROOT, "cards", out_gol), p,
         width = 1080/150, height = 1200/150, dpi = 150,
         device = ragg::agg_png, bg = ER_BLANCO)
  cat("✔", out_gol, "· top", nrow(gol), "· total goles:", total_g,
      "· sin gol:", sin_gol, "\n")
}
