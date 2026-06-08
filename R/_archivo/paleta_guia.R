# ==========================================================================
# 04_paleta_guia.R — Lámina visual de las paletas ER + ejemplos aplicados
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
source(file.path(ROOT, "R/paleta_estacion_r.R"))
suppressMessages({ library(ggplot2); library(dplyr); library(colorspace)
  library(patchwork); library(ragg) })
ok <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu","ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
FF <- if (ok) "ubuntu" else "sans"
NEG <- "#191919"; GR <- "#6F6F6F"

# ---- Helper: fila de swatches a una altura y --------------------------------
swatch_row <- function(cols, y, h = 0.8) {
  n <- length(cols)
  data.frame(xmin = seq(0, n - 1) / n, xmax = seq(1, n) / n,
             ymin = y, ymax = y + h, fill = cols)
}

seq9 <- er_pal_seq(9); div9 <- er_pal_div(9); qual <- ER_QUAL
tiles <- rbind(
  transform(swatch_row(seq9, 5.30), grp = "s"),
  transform(swatch_row(div9, 3.15), grp = "d"),
  transform(swatch_row(qual, 1.00), grp = "q")
)
# Etiquetas hex de la cualitativa
qlab <- data.frame(x = (seq_along(qual) - 0.5) / length(qual), y = 0.78, lab = qual)

guia <- ggplot() +
  geom_rect(data = tiles, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                              fill = fill), color = "white", linewidth = 0.4) +
  scale_fill_identity() +
  # Títulos de sección (título arriba, descripción debajo)
  annotate("text", x = 0, y = 6.52, label = "SECUENCIAL", family = FF,
           fontface = "bold", size = 6, color = NEG, hjust = 0) +
  annotate("text", x = 0, y = 6.27, label = "orden de menor a mayor · ej. cantidad por provincia",
           family = FF, size = 3.7, color = GR, hjust = 0) +
  annotate("text", x = 0, y = 4.37, label = "DIVERGENTE", family = FF,
           fontface = "bold", size = 6, color = NEG, hjust = 0) +
  annotate("text", x = 0, y = 4.12, label = "desvíos respecto de un centro · ej. edad vs promedio",
           family = FF, size = 3.7, color = GR, hjust = 0) +
  annotate("text", x = 0, y = 2.22, label = "CUALITATIVA", family = FF,
           fontface = "bold", size = 6, color = NEG, hjust = 0) +
  annotate("text", x = 0, y = 1.97, label = "categorías sin orden · ej. posiciones, ligas",
           family = FF, size = 3.7, color = GR, hjust = 0) +
  geom_text(data = qlab, aes(x, y, label = lab), family = FF, size = 3.1, color = GR) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0.55, 6.7), clip = "off") +
  labs(title = "Paletas de visualización · Estación R",
       subtitle = "Ancladas en el azul de marca (#405BFF), interpoladas en Lab y chequeadas para daltonismo") +
  theme_void(base_family = FF) +
  theme(plot.title = element_text(face = "bold", size = 19, color = NEG),
        plot.subtitle = element_text(size = 11, color = GR, margin = margin(t = 3, b = 10)),
        plot.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(22, 26, 14, 26))

# ---- Simulación de daltonismo de la cualitativa -----------------------------
sims <- list(Normal = qual, Deuteranopia = deutan(qual),
             Protanopia = protan(qual), Tritanopia = tritan(qual))
sim_df <- do.call(rbind, lapply(seq_along(sims), function(i) {
  transform(swatch_row(sims[[i]], y = length(sims) - i), tipo = names(sims)[i])
}))
lab_df <- data.frame(y = (length(sims):1) - 1 + 0.4, tipo = names(sims))

cvd <- ggplot() +
  geom_rect(data = sim_df, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                               fill = fill), color = "white", linewidth = 0.4) +
  scale_fill_identity() +
  geom_text(data = lab_df, aes(x = -0.02, y = y, label = tipo), family = FF,
            size = 3.6, color = NEG, hjust = 1) +
  coord_cartesian(xlim = c(-0.32, 1), ylim = c(-0.2, 4.1), clip = "off") +
  labs(title = "Cómo ve la cualitativa una persona con daltonismo",
       subtitle = "Los 6 tonos siguen siendo distinguibles en los tres tipos") +
  theme_void(base_family = FF) +
  theme(plot.title = element_text(face = "bold", size = 14, color = NEG),
        plot.subtitle = element_text(size = 10, color = GR, margin = margin(t = 2, b = 8)),
        plot.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(6, 26, 18, 26))

final <- guia / cvd + plot_layout(heights = c(2.5, 1.6)) &
  theme(plot.background = element_rect(fill = "white", color = NA))
ggsave(file.path(ROOT, "paleta_guia.png"), final, width = 1080/150, height = 1320/150,
       dpi = 150, device = ragg::agg_png, bg = "white")
cat("✔ paleta_guia.png\n")
