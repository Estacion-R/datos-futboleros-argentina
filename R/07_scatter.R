# ==========================================================================
# 09_scatter_mundiales.R — Partidos con la Selección vs. Mundiales jugados.
# Scatter: cada punto = un jugador. Messi en la esquina opuesta a todos.
# Mundiales hardcodeados desde Wikipedia; verificar antes de publicar:
#   - Paredes: 2018 (Sampaoli) + 2022 = 2 ✓
#   - Lo Celso: 2018 (jugó); 2022 convocado pero lesionado = 1
#   - De Paul: NO estuvo en 2018 (llegó con Scaloni, post-2018) = 1
#   - Nico González: convocado 2022 pero se lesionó antes = 0
#
# REQUISITO Quarto: en el HTML este gráfico VA interactivo (no PNG estático).
#   - geom_point_interactive(tooltip = paste0(name, "\n", caps, " partidos · ", club))
#     + girafe() — hover por jugador con nombre, partidos y club.
#   - ggiraph no renderiza los círculos de ggforce ni los annotate() de coordenadas
#     fijas (flecha Nico González, "5 Mundiales", etiquetas de grupo). Antes de
#     convertir: reemplazar geom_mark_ellipse por shapes/encierros compatibles y
#     las anotaciones por geom_richtext/labels interactivos o capas estáticas
#     superpuestas. El PNG actual queda como fallback/redes.
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

suppressMessages({
  library(ggplot2); library(ggrepel); library(ggforce)
  library(dplyr); library(tibble); library(ragg); library(ggiraph)
})

# --- Marca Estación R -------------------------------------------------------
ER_AZUL  <- "#405BFF"; ER_AZUL_D <- "#1839F4"
ER_NEGRO <- "#191919"; ER_BLANCO <- "#FFFFFF"; ER_GRIS <- "#F7F7F7"; GRIS_TXT <- "#6F6F6F"
ok_font <- tryCatch({
  library(showtext); sysfonts::font_add_google("Ubuntu", "ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE
}, error = function(e) FALSE)
FF <- if (ok_font) "ubuntu" else "sans"

# --- Mundiales por jugador --------------------------------------------------
mundiales_tbl <- tribble(
  ~name,                    ~mundiales,
  "Emiliano Martínez",      1,  # 2022
  "Gerónimo Rulli",         1,  # 2022
  "Juan Musso",             1,  # 2022
  "Cristian Romero",        1,  # 2022
  "Lisandro Martínez",      1,  # 2022
  "Leonardo Balerdi",       0,
  "Facundo Medina",         0,
  "Nicolás Otamendi",       3,  # 2014 + 2018 + 2022
  "Nicolás Tagliafico",     2,  # 2018 + 2022
  "Nahuel Molina",          1,  # 2022
  "Gonzalo Montiel",        1,  # 2022
  "Leandro Paredes",        2,  # 2018 + 2022
  "Enzo Fernández",         1,  # 2022
  "Alexis Mac Allister",    1,  # 2022
  "Valentín Barco",         0,
  "Exequiel Palacios",      1,  # 2022
  "Rodrigo De Paul",        1,  # 2022 (llegó con Scaloni)
  "Nico Paz",               0,
  "Giovani Lo Celso",       1,  # 2018 (2022: lesionado antes del torneo)
  "Nico González",          0,  # 2022: lesionado antes del torneo
  "Thiago Almada",          1,  # 2022 (reemplazó a J. Correa)
  "Giuliano Simeone",       0,
  "Lionel Messi",           5,  # 2006+2010+2014+2018+2022
  "Julián Álvarez",         1,  # 2022
  "Lautaro Martínez",       1,  # 2022
  "José Manuel López",      0
)

datos <- plantel |>
  left_join(mundiales_tbl, by = "name") |>
  mutate(
    es_messi = name == "Lionel Messi",
    label = case_when(
      name == "Lionel Messi"       ~ "Messi",
      name == "Nicolás Otamendi"   ~ "Otamendi",
      name == "Rodrigo De Paul"    ~ "De Paul",
      name == "Leandro Paredes"    ~ "Paredes",
      name == "Nicolás Tagliafico" ~ "Tagliafico",
      name == "Giovani Lo Celso"   ~ "Lo Celso",
      name == "Valentín Barco"     ~ "Barco",
      name == "Nico Paz"           ~ "N. Paz",
      name == "Gerónimo Rulli"     ~ "Rulli",
      # G. Simeone: se omite para descongestionar el cluster denso de "0 Mundiales".
      # Nico González: lo identifica su anotación editorial, no se repite en repel.
      TRUE ~ ""
    ),
    mundiales_f = factor(mundiales),
    grupo_ggforce = case_when(
      mundiales == 0 ~ "Sin Mundial todavía",
      mundiales == 1 ~ "1 Mundial",
      mundiales == 2 ~ "2 Mundiales",
      mundiales == 3 ~ "3 Mundiales",
      mundiales == 5 ~ "5 Mundiales"
    )
  )

# Jitter precomputado — puntos y labels comparten las mismas posiciones
set.seed(42)
datos <- datos |>
  mutate(y_j = mundiales + runif(n(), -0.13, 0.13))

# Posiciones reales de puntos a anotar a mano (anclas dinámicas, no hardcode)
ng    <- dplyr::filter(datos, name == "Nico González")
messi <- dplyr::filter(datos, es_messi)

# Colores por nivel de Mundiales
MUND_COL <- c(
  "0" = "#ADADAD",
  "1" = ER_AZUL,
  "2" = "#2CA6C4",
  "3" = ER_AZUL_D,
  "5" = ER_NEGRO
)
MUND_LAB <- c(
  "0" = "Sin Mundial todavía",
  "1" = "1 Mundial",
  "2" = "2 Mundiales",
  "3" = "3 Mundiales",
  "5" = "5 Mundiales — Messi"
)

n_sin <- sum(datos$mundiales == 0)

# === Versión ESTÁTICA (PNG / redes): ggforce + anotaciones editoriales ======
build_scatter <- function() {

# Una capa ggforce por categoría — fill = NA (solo borde coloreado).
# Híbrido: ggforce etiqueta automática para 2/3 Mundiales (clusters reales);
# "0", "1" y "5" usan ellipse sin label (se añaden a mano abajo). El "5" es un
# único punto (Messi): el label automático de ggforce le cuelga un connector feo.
marks_ellipse <- lapply(names(MUND_COL), function(lvl) {
  clr <- MUND_COL[[lvl]]
  d   <- dplyr::filter(datos, as.character(mundiales_f) == lvl)
  if (nrow(d) == 0) return(NULL)
  if (lvl %in% c("0", "1", "5")) {
    ggforce::geom_mark_ellipse(
      data        = d,
      aes(group   = grupo_ggforce),
      colour      = clr,
      fill        = NA,
      expand      = unit(4, "mm"),
      show.legend = FALSE
    )
  } else {
    ggforce::geom_mark_ellipse(
      data           = d,
      aes(group = grupo_ggforce, label = grupo_ggforce),
      colour         = clr,
      fill           = NA,
      expand         = unit(4, "mm"),
      label.family   = FF,
      label.fontsize = 9,
      label.fontface = "bold",
      label.colour   = clr,
      con.colour     = clr,
      con.size       = 0.45,
      show.legend    = FALSE
    )
  }
})
marks_ellipse <- Filter(Negate(is.null), marks_ellipse)

p <- ggplot(datos, aes(x = caps, y = y_j)) +
  # ---- líneas de referencia en todos los niveles, incluido el 4 vacío --------
  geom_hline(yintercept = 0:5, color = "#EBEBEB", linewidth = 0.5) +
  # ---- círculos de grupo (ggforce, una capa por categoría) ------------------
  marks_ellipse +
  # ---- puntos ---------------------------------------------------------------
  geom_point(aes(color = mundiales_f, size = es_messi), alpha = 0.92) +
  # ---- labels solo para puntos notables ------------------------------------
  geom_text_repel(
    data = \(d) filter(d, label != ""),
    aes(label = label, color = mundiales_f),
    size = 3.3, family = FF, fontface = "bold",
    box.padding = 0.6, point.padding = 0.3,
    min.segment.length = 0.4, max.overlaps = 20,
    show.legend = FALSE
  ) +
  # ---- "5 Mundiales" — debajo de Messi, sin connector (era el feo de ggforce) -
  annotate("text",
           x = messi$caps, y = messi$y_j - 0.95,
           label = "5 Mundiales",
           hjust = 0.5, size = 3.2, family = FF, fontface = "bold",
           colour = MUND_COL[["5"]]) +
  # ---- etiqueta "1 Mundial" — arriba a la izquierda -----------------------
  annotate("text",
           x = -20, y = 1.55,
           label = "1 Mundial",
           hjust = 0.5, size = 3.2, family = FF, fontface = "bold",
           colour = MUND_COL[["1"]]) +
  annotate("segment",
           x = -12, xend = -3, y = 1.50, yend = 1.08,
           colour = MUND_COL[["1"]], linewidth = 0.4) +
  # ---- etiqueta "Sin Mundial" — debajo del cluster, línea corta -----------
  annotate("text",
           x = 22, y = -0.72,
           label = "Sin Mundial todavía",
           hjust = 0.5, size = 3.2, family = FF, fontface = "bold",
           colour = MUND_COL[["0"]]) +
  annotate("segment",
           x = 22, xend = 18, y = -0.65, yend = -0.22,
           colour = MUND_COL[["0"]], linewidth = 0.4) +
  # ---- anotación editorial: caso Nico González (texto + flecha al punto real) -
  annotate("text",
           x = ng$caps + 60, y = 0.62,
           label = paste0(ng$caps, " partidos, 0 Mundiales\nSe lesionó antes\nde Qatar 2022"),
           hjust = 0, vjust = 1,
           family = FF, size = 2.85, lineheight = 0.95, fontface = "italic",
           colour = MUND_COL[["0"]]) +
  annotate("curve",
           x = ng$caps + 55, xend = ng$caps + 4, y = 0.5, yend = ng$y_j + 0.06,
           curvature = -0.35,
           arrow = arrow(length = unit(2, "mm"), type = "closed"),
           colour = MUND_COL[["0"]], linewidth = 0.5) +
  scale_color_manual(values = MUND_COL, guide = "none") +
  scale_size_manual(values = c(`FALSE` = 3.2, `TRUE` = 5.5), guide = "none") +
  scale_x_continuous(breaks = seq(0, 200, 50),
                     expand = expansion(mult = c(0.18, 0.13))) +
  scale_y_continuous(
    breaks = 0:5,   # el 4 se muestra vacío a propósito: nadie tiene 4 Mundiales
    labels = as.character(0:5),
    expand = expansion(add = c(1.4, 0.7))
  ) +
  coord_cartesian(clip = "off") +
  labs(
    title    = "Mundiales y partidos con la Selección",
    subtitle = "Cada punto es un jugador del plantel actual",
    x        = "Partidos con la Selección",
    y        = "Mundiales jugados",
    caption  = paste0(
      "Messi: 198 partidos y 5 Mundiales — universo aparte.\n",
      "Otamendi es el único con 3 (2014 · 2018 · 2022).\n",
      n_sin, " jugadores aún no disputaron un Mundial.\n",
      "Datos: Transfermarkt + Wikipedia · Estación R"
    )
  ) +
  theme_minimal(base_family = FF) +
  theme(
    plot.background   = element_rect(fill = ER_BLANCO, color = NA),
    panel.background  = element_rect(fill = ER_BLANCO, color = NA),
    plot.title.position   = "plot",
    plot.caption.position = "plot",
    plot.title    = element_text(face = "bold", size = 27, color = ER_NEGRO),
    plot.subtitle = element_text(size = 14, color = GRIS_TXT, margin = margin(t = 4, b = 12)),
    plot.caption  = element_text(size = 11, color = GRIS_TXT, hjust = 0,
                                 lineheight = 1.1, margin = margin(t = 14)),
    plot.margin   = margin(34, 34, 26, 34),
    axis.title.x  = element_text(size = 12, color = GRIS_TXT, margin = margin(t = 8)),
    axis.title.y  = element_text(size = 12, color = GRIS_TXT, margin = margin(r = 8)),
    axis.text     = element_text(size = 11, color = ER_NEGRO),
    panel.grid.major.x = element_line(color = "#EBEBEB", linewidth = 0.4),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position = "none"
  )
  p
}

# === Versión INTERACTIVA (HTML): mismas anotaciones que el PNG + ggiraph ====
# Incluye los círculos de ggforce, etiquetas de grupo, labels de jugadores y
# el caption. Solo los puntos son interactivos (tooltip + hover).
build_scatter_girafe <- function(width_svg = 8, height_svg = 6.8) {
  # showtext vectoriza el texto a paths e infla el widget -> apagar solo acá.
  if (ok_font) { showtext::showtext_auto(FALSE); on.exit(showtext::showtext_auto(TRUE), add = TRUE) }
  # Registrar Ubuntu para gdtools/svglite. El HTML de Quarto ya carga Ubuntu
  # vía Google Fonts; el SVG declara la familia y el browser la resuelve.
  tryCatch(gdtools::register_gfont("Ubuntu"), error = function(e) NULL)
  GF <- "Ubuntu"

  d <- datos |>
    dplyr::mutate(tip = paste0(
      "<b>", name, "</b><br/>", caps, " partidos · ",
      mundiales, ifelse(mundiales == 1, " Mundial", " Mundiales"), "<br/>", club))

  # Círculos de ggforce — mismos que en build_scatter()
  marks_ellipse <- lapply(names(MUND_COL), function(lvl) {
    clr <- MUND_COL[[lvl]]
    dd  <- dplyr::filter(d, as.character(mundiales_f) == lvl)
    if (nrow(dd) == 0) return(NULL)
    if (lvl %in% c("0", "1", "5")) {
      ggforce::geom_mark_ellipse(
        data = dd, aes(group = grupo_ggforce),
        colour = clr, fill = NA, expand = unit(4, "mm"), show.legend = FALSE)
    } else {
      ggforce::geom_mark_ellipse(
        data = dd, aes(group = grupo_ggforce, label = grupo_ggforce),
        colour = clr, fill = NA, expand = unit(4, "mm"),
        label.family = GF, label.fontsize = 9, label.fontface = "bold",
        label.colour = clr, con.colour = clr, con.size = 0.45, show.legend = FALSE)
    }
  })
  marks_ellipse <- Filter(Negate(is.null), marks_ellipse)

  g <- ggplot(d, aes(x = caps, y = y_j)) +
    geom_hline(yintercept = 0:5, color = "#EBEBEB", linewidth = 0.5) +
    marks_ellipse +
    ggiraph::geom_point_interactive(
      aes(color = mundiales_f, size = es_messi, tooltip = tip, data_id = name),
      alpha = 0.92) +
    ggrepel::geom_text_repel(
      data = \(x) dplyr::filter(x, label != ""),
      aes(label = label, color = mundiales_f),
      size = 3.3, family = GF, fontface = "bold",
      box.padding = 0.6, point.padding = 0.3,
      min.segment.length = 0.4, max.overlaps = 20, show.legend = FALSE) +
    annotate("text", x = messi$caps, y = messi$y_j - 0.95,
             label = "5 Mundiales", hjust = 0.5, size = 3.2, family = GF, fontface = "bold",
             colour = MUND_COL[["5"]]) +
    annotate("text", x = -20, y = 1.55, label = "1 Mundial",
             hjust = 0.5, size = 3.2, family = GF, fontface = "bold",
             colour = MUND_COL[["1"]]) +
    annotate("segment", x = -12, xend = -3, y = 1.50, yend = 1.08,
             colour = MUND_COL[["1"]], linewidth = 0.4) +
    annotate("text", x = 22, y = -0.72, label = "Sin Mundial todavía",
             hjust = 0.5, size = 3.2, family = GF, fontface = "bold",
             colour = MUND_COL[["0"]]) +
    annotate("segment", x = 22, xend = 18, y = -0.65, yend = -0.22,
             colour = MUND_COL[["0"]], linewidth = 0.4) +
    annotate("text", x = ng$caps + 60, y = 0.62,
             label = paste0(ng$caps, " partidos, 0 Mundiales\nSe lesionó antes\nde Qatar 2022"),
             hjust = 0, vjust = 1, size = 2.85, family = GF, lineheight = 0.95, fontface = "italic",
             colour = MUND_COL[["0"]]) +
    annotate("curve", x = ng$caps + 55, xend = ng$caps + 4, y = 0.5, yend = ng$y_j + 0.06,
             curvature = -0.35, arrow = arrow(length = unit(2, "mm"), type = "closed"),
             colour = MUND_COL[["0"]], linewidth = 0.5) +
    scale_color_manual(values = MUND_COL, guide = "none") +
    scale_size_manual(values = c(`FALSE` = 2.6, `TRUE` = 4.8), guide = "none") +
    scale_x_continuous(breaks = seq(0, 200, 50),
                       expand = expansion(mult = c(0.18, 0.13))) +
    scale_y_continuous(breaks = 0:5, labels = as.character(0:5),
                       expand = expansion(add = c(1.4, 0.7))) +
    coord_cartesian(clip = "off") +
    labs(title = "Mundiales y partidos con la Selección",
         subtitle = "Pasá el mouse sobre cada punto para ver quién es",
         x = "Partidos con la Selección", y = "Mundiales jugados",
         caption = paste0(
           "Messi: 198 partidos y 5 Mundiales — universo aparte.\n",
           "Otamendi es el único con 3 (2014 · 2018 · 2022).\n",
           n_sin, " jugadores aún no disputaron un Mundial.\n",
           "Datos: Transfermarkt + Wikipedia · Estación R")) +
    theme_minimal(base_family = GF) +
    theme(
      plot.background   = element_rect(fill = ER_BLANCO, color = NA),
      panel.background  = element_rect(fill = ER_BLANCO, color = NA),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.title    = element_text(face = "bold", size = 27, color = ER_NEGRO),
      plot.subtitle = element_text(size = 14, color = GRIS_TXT, margin = margin(t = 4, b = 12)),
      plot.caption  = element_text(size = 11, color = GRIS_TXT, hjust = 0,
                                   lineheight = 1.1, margin = margin(t = 14)),
      plot.margin   = margin(34, 34, 26, 34),
      axis.title.x  = element_text(size = 12, color = GRIS_TXT, margin = margin(t = 8)),
      axis.title.y  = element_text(size = 12, color = GRIS_TXT, margin = margin(r = 8)),
      axis.text     = element_text(size = 11, color = ER_NEGRO),
      panel.grid.major.x = element_line(color = "#EBEBEB", linewidth = 0.4),
      panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
      legend.position = "none")

  fs <- gdtools::font_set_auto(); fs$dependencies <- list()
  ggiraph::girafe(
    ggobj = g, width_svg = width_svg, height_svg = height_svg, font_set = fs,
    options = list(
      ggiraph::opts_hover(css = "fill-opacity:1;stroke:#191919;stroke-width:1.4px;"),
      ggiraph::opts_hover_inv(css = "opacity:0.30;"),
      ggiraph::opts_tooltip(css = paste0(
        "background:#191919;color:#fff;padding:7px 10px;border-radius:8px;",
        "font-family:Ubuntu,sans-serif;font-size:13px;box-shadow:0 4px 14px rgba(0,0,0,.25);")),
      ggiraph::opts_toolbar(saveaspng = FALSE),
      ggiraph::opts_sizing(rescale = TRUE)))
}

if (sys.nframe() == 0) {
  ggsave(file.path(ROOT, "cards", "09_scatter_mundiales.png"), build_scatter(),
         width = 1080/150, height = 1080/150, dpi = 150,
         device = ragg::agg_png, bg = ER_BLANCO)
  cat("✔ 09_scatter_mundiales.png\n")
}
