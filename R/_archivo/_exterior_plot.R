# ==========================================================================
# _exterior_plot.R — Card 4 "Una Selección de exportación" (AISLADA)
# Barra de proporción 24 vs 2. Toque de marca: el "2" en AMARILLO sobre el
# bloque negro (regla: amarillo sólo sobre negro). Nota con annotate que sale
# del "24" señalando la liga que más argentinos concentra en el exterior.
# Corre sola:  Rscript R/_exterior_plot.R   ->  cards/04_exterior.png
# También la sourcea R/01_cards.R (fuente única; ahí save_card/F_TIT ya existen).
# ==========================================================================
if (!exists("plantel")) source(file.path(if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina",
  "R/00_prep.R"))

suppressMessages({ library(ggplot2); library(ragg); library(dplyr) })

# --- Identidad visual (idempotente: no pisa lo que 01_cards.R ya definió) ----
ER_AZUL  <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
ER_NEGRO <- "#191919"; ER_BLANCO <- "#FFFFFF"; GRIS_TXT <- "#6F6F6F"
if (!exists("F_TIT")) {
  ok <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu", "ubuntu")
    showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
  F_TIT <- if (ok) "ubuntu" else "sans"; F_TXT <- F_TIT
}
if (!exists("theme_card")) {
  theme_card <- function() theme_minimal(base_family = F_TXT) +
    theme(
      plot.background  = element_rect(fill = ER_BLANCO, color = NA),
      panel.background = element_rect(fill = ER_BLANCO, color = NA),
      plot.title    = element_text(family = F_TIT, face = "bold", size = 27,
                                   color = ER_NEGRO, lineheight = 1),
      plot.subtitle = element_text(family = F_TXT, size = 14, color = GRIS_TXT,
                                   margin = margin(t = 4, b = 12)),
      plot.caption  = element_text(family = F_TXT, size = 11, color = GRIS_TXT,
                                   hjust = 0, lineheight = 1.05, margin = margin(t = 12)),
      plot.margin   = margin(34, 34, 26, 34),
      axis.title    = element_blank(), panel.grid.minor = element_blank())
}
if (!exists("save_card")) save_card <- function(p, file, w = 1080, h = 1350) {
  if (!dir.exists("cards")) dir.create("cards")
  ggsave(file.path("cards", file), p, width = w/150, height = h/150,
         dpi = 150, device = ragg::agg_png, bg = ER_BLANCO); cat("✔", file, "\n")
}
TAG <- "Estación R · Datos: Transfermarkt"

build_exterior_plot <- function() {
  n_total <- nrow(plantel)
  n_ext   <- sum(plantel$milita == "Exterior")
  n_loc   <- n_total - n_ext

  loc_lbl <- plantel |> dplyr::filter(milita == "Liga local") |>
    dplyr::mutate(ln = sub("^.*\\s", "", name),
                  cl = dplyr::case_when(grepl("Boca", club) ~ "Boca",
                                        grepl("River", club) ~ "River", TRUE ~ club),
                  t  = paste0(ln, " (", cl, ")"))
  locals_txt <- paste(loc_lbl$t, collapse = "    ·    ")

  # Liga que más argentinos concentra en el exterior (teaser; el detalle va en
  # la tabla de ligas). Dinámico: si cambia la convocatoria, se recalcula.
  top_liga <- plantel |> dplyr::filter(milita == "Exterior", !is.na(liga)) |>
    dplyr::count(liga, name = "n") |> dplyr::slice_max(n, n = 1, with_ties = FALSE)
  liga_pais <- liga_meta$pais[match(top_liga$liga, liga_meta$liga)]
  pct <- round(top_liga$n / n_ext * 100)
  nota_l1 <- paste0(top_liga$n, " de esos ", n_ext, " (", pct, "%)")
  nota_l2 <- paste0("provienen de ", top_liga$liga, " (", liga_pais, ")")

  seg <- data.frame(estado = factor(c("Exterior", "Liga local"),
                                    levels = c("Exterior", "Liga local")),
                    n = c(n_ext, n_loc))
  seg$frac <- seg$n / sum(seg$n)
  seg$xmax <- cumsum(seg$frac); seg$xmin <- seg$xmax - seg$frac
  seg$mid  <- (seg$xmin + seg$xmax) / 2

  ggplot(seg) +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = 1, fill = estado),
              color = ER_BLANCO, linewidth = 2.5) +
    scale_fill_manual(values = c("Exterior" = ER_AZUL, "Liga local" = ER_NEGRO),
                      guide = "none") +
    # número grande dentro del segmento "exterior"
    annotate("text", x = seg$mid[1], y = 0.60, label = n_ext, family = F_TIT,
             fontface = "bold", size = 34, color = "white") +
    annotate("text", x = seg$mid[1], y = 0.29, label = "juegan en el exterior",
             family = F_TXT, fontface = "bold", size = 6.4, color = "white") +
    # toque de marca: el "2" en AMARILLO sobre el bloque negro
    annotate("text", x = seg$mid[2], y = 0.5, label = n_loc, family = F_TIT,
             fontface = "bold", size = 12, color = ER_AMARILLO) +
    # callout a la astilla de la liga local (sin repetir el número)
    annotate("segment", x = seg$mid[2], xend = seg$mid[2], y = 1.03, yend = 1.16,
             color = ER_NEGRO, linewidth = 0.5) +
    annotate("text", x = 1, y = 1.33, hjust = 1, family = F_TIT, fontface = "bold",
             size = 6, color = ER_NEGRO, label = "en la liga local") +
    annotate("text", x = 1, y = 1.22, hjust = 1, family = F_TXT, size = 4.6,
             color = GRIS_TXT, label = locals_txt) +
    # NOTA que sale del "24": la flecha baja desde el bloque y apunta justo a la
    # parte de arriba del texto, que va centrado debajo (flecha y texto conectados).
    annotate("curve", x = seg$mid[1] + 0.06, xend = seg$mid[1], y = -0.05, yend = -0.24,
             curvature = -0.30, linewidth = 0.7, color = ER_AZUL_D,
             arrow = arrow(length = unit(0.022, "npc"), type = "closed")) +
    annotate("text", x = seg$mid[1], y = -0.33, hjust = 0.5, vjust = 1, lineheight = 1.05,
             family = F_TIT, fontface = "bold", size = 5.4, color = ER_AZUL_D,
             label = nota_l1) +
    annotate("text", x = seg$mid[1], y = -0.49, hjust = 0.5, vjust = 1, lineheight = 1.05,
             family = F_TXT, size = 5, color = ER_NEGRO, label = nota_l2) +
    scale_x_continuous(expand = expansion(mult = c(0, 0))) +
    coord_cartesian(ylim = c(-0.72, 1.40), clip = "off") +
    labs(title = "Una Selección de exportación",
         subtitle = paste0(n_ext, " de ", n_total, " juegan fuera del país"),
         caption = TAG) +
    theme_card() +
    theme(axis.text = element_blank(), panel.grid = element_blank(),
          plot.margin = margin(22, 34, 26, 34))
}

# Guard de standalone: sólo regenera la card si se corre el archivo directo.
if (sys.nframe() == 0) {
  p_ext <- build_exterior_plot()
  save_card(p_ext, "04_exterior.png", h = 1080)
}
