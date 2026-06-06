# ==========================================================================
# _edad_plot.R — Gráfico de edades del plantel
# jitter de puntos + línea de promedio + anotaciones con ggforce.
# build_edad_plot()   → ggplot estático (card de redes 01_cards.R)
# build_edad_girafe() → widget ggiraph interactivo (index.qmd)
# ==========================================================================
suppressMessages({
  library(ggplot2); library(dplyr); library(ggforce); library(ggiraph)
})

# Marca Estación R (por si el caller no las definió)
if (!exists("ER_AZUL")) {
  ER_AZUL <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
  ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7"; ER_BLANCO <- "#FFFFFF"
  GRIS_TXT <- "#6F6F6F"
}

# Prepara el data.frame con jitter fijo (semilla 42) y metadatos de grupos.
# Reutilizado por las dos funciones para garantizar coordenadas idénticas.
.prep_edad <- function(plantel) {
  sn <- function(nm) dplyr::case_when(nm == "Nico Paz"    ~ "Nico Paz",
                                      nm == "Lionel Messi" ~ "Messi",
                                      TRUE ~ sub("^.*\\s", "", nm))
  set.seed(42)
  d <- plantel |> dplyr::mutate(y = 1 + runif(dplyr::n(), -0.34, 0.34))
  jov <- d[d$age == min(d$age), ]
  gra <- d[d$age == max(d$age), ]
  d |> dplyr::mutate(
    marca   = dplyr::case_when(age == min(age) ~ "j",
                               age == max(age) ~ "g", TRUE ~ NA_character_),
    m_label = dplyr::case_when(marca == "j" ~ "Los más jóvenes",
                               marca == "g" ~ "Los más grandes", TRUE ~ NA_character_),
    m_desc  = dplyr::case_when(
      marca == "j" ~ paste0(paste(sn(jov$name), collapse = " y "), ", ", min(age), " años"),
      marca == "g" ~ paste0(paste(sn(gra$name), collapse = " y "), ", ", max(age), " años"),
      TRUE ~ NA_character_),
    tooltip_txt = paste0(name, "\n", age, " años"))
}

# ---------------------------------------------------------------------------
# Gráfico base (capas estáticas compartidas entre la versión PNG y la girafe)
# ---------------------------------------------------------------------------
.build_base <- function(d, prom, FF, scale) {
  prom_txt <- formatC(prom, format = "f", digits = 1, decimal.mark = ",")
  destac   <- d |> dplyr::filter(!is.na(marca))
  s        <- function(x) x * scale

  list(
    geom_vline(xintercept = prom, color = ER_NEGRO, linewidth = 0.8, linetype = "22"),
    annotate("label", x = prom, y = 1.66,
             label = paste0("Promedio: ", prom_txt, " años"),
             family = FF, color = ER_NEGRO, size = s(4.4), fontface = "bold",
             fill = ER_BLANCO, label.size = 0, label.padding = unit(0.15, "lines")),
    ggforce::geom_mark_rect(
      aes(filter = !is.na(marca), group = marca,
          label = m_label, description = m_desc),
      color = ER_NEGRO, fill = NA, linewidth = 0.45, expand = unit(2.8, "mm"),
      radius = unit(1.6, "mm"), con.colour = ER_NEGRO, con.cap = unit(0.8, "mm"),
      label.family = FF, label.fontsize = c(s(13), s(10)),
      label.fill = ER_BLANCO, label.colour = ER_NEGRO,
      label.buffer = unit(6, "mm")),
    scale_x_continuous(breaks = seq(18, 38, 4), labels = \(x) paste0(x, "a")),
    coord_cartesian(ylim = c(0.30, 1.78)),
    labs(x = NULL, y = NULL,
         title    = "Edad del plantel",
         subtitle = "Edad de cada jugador del plantel"),
    theme_minimal(base_family = FF),
    theme(
      plot.background  = element_rect(fill = ER_BLANCO, color = NA),
      panel.background = element_rect(fill = ER_BLANCO, color = NA),
      plot.title    = element_text(family = FF, face = "bold",
                                   size = s(26), color = ER_NEGRO),
      plot.subtitle = element_text(family = FF, size = s(12), color = GRIS_TXT,
                                   margin = margin(t = 3, b = 10)),
      axis.text.y  = element_blank(),
      axis.text.x  = element_text(size = s(12), color = GRIS_TXT),
      panel.grid   = element_blank(),
      plot.margin  = margin(14, 18, 10, 14))
  )
}

# ---------------------------------------------------------------------------
# Versión ESTÁTICA (PNG) — usada por 01_cards.R para la card de redes
# ---------------------------------------------------------------------------
build_edad_plot <- function(plantel, prom = NULL, FF = "sans", scale = 1) {
  if (is.null(prom)) prom <- round(mean(plantel$age), 1)
  d      <- .prep_edad(plantel)
  destac <- d |> dplyr::filter(!is.na(marca))

  ggplot(d, aes(age, y)) +
    .build_base(d, prom, FF, scale) +
    geom_point(size = scale * 5.4, color = ER_AZUL, alpha = 0.85) +
    geom_point(data = destac, size = scale * 6.6, color = ER_AZUL_D)
}

# ---------------------------------------------------------------------------
# Versión INTERACTIVA (girafe) — usada por index.qmd
# Hover sobre cada punto muestra nombre + edad; los demás se atenúan.
# ---------------------------------------------------------------------------
build_edad_girafe <- function(plantel, prom = NULL, FF = "sans", scale = 1,
                               width_svg = 9.2, height_svg = 5) {
  if (is.null(prom)) prom <- round(mean(plantel$age), 1)
  d      <- .prep_edad(plantel)
  destac <- d |> dplyr::filter(!is.na(marca))

  CSS_TT <- paste0(
    "background:white;border:1px solid #405BFF;padding:6px 10px;",
    "border-radius:6px;font-family:Ubuntu,sans-serif;",
    "font-size:14px;color:#191919;white-space:pre;")

  p <- ggplot(d, aes(age, y)) +
    .build_base(d, prom, FF, scale) +
    ggiraph::geom_point_interactive(
      aes(tooltip = tooltip_txt, data_id = name),
      size = scale * 5.4, color = ER_AZUL, alpha = 0.85) +
    ggiraph::geom_point_interactive(
      data = destac,
      aes(tooltip = tooltip_txt, data_id = name),
      size = scale * 6.6, color = ER_AZUL_D)

  ggiraph::girafe(
    ggobj = p,
    width_svg  = width_svg,
    height_svg = height_svg,
    options = list(
      ggiraph::opts_hover(css = "opacity:1;"),
      ggiraph::opts_hover_inv(css = "opacity:0.25;"),
      ggiraph::opts_tooltip(css = CSS_TT, use_fill = FALSE),
      ggiraph::opts_sizing(rescale = TRUE, width = 1)
    )
  )
}
