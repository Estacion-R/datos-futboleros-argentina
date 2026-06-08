# ==========================================================================
# 05_paleta_aplicada.R — Las tres paletas aplicadas a datos reales del plantel
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))
source(file.path(ROOT, "R/paleta_estacion_r.R"))
suppressMessages({ library(ggplot2); library(dplyr); library(sf); library(patchwork); library(ragg) })
ok <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu","ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
FF <- if (ok) "ubuntu" else "sans"
NEG <- "#191919"; GR <- "#6F6F6F"
base_t <- theme_minimal(base_family = FF) +
  theme(plot.title = element_text(face = "bold", size = 14, color = NEG),
        plot.subtitle = element_text(size = 10, color = GR, margin = margin(b = 6)),
        axis.title = element_blank(), plot.background = element_rect(fill="white", color=NA),
        panel.grid.minor = element_blank())

# A · SECUENCIAL — choropleth provincias
pA <- ggplot(mapa_data) +
  geom_sf(aes(fill = jugadores), color = "white", linewidth = 0.2) +
  scale_fill_er_c(name = NULL, breaks = c(0, 8, 16)) +
  coord_sf(xlim = c(-74, -53), ylim = c(-55, -21), expand = FALSE) +
  labs(title = "Secuencial", subtitle = "Jugadores por provincia") +
  base_t + theme(axis.text = element_blank(), panel.grid = element_blank(),
                 legend.position = "right", legend.key.width = unit(0.3,"cm"))

# B · DIVERGENTE — edad vs promedio del plantel
pB_df <- plantel |> mutate(dif = age - mean(age)) |> arrange(dif) |>
  mutate(name = factor(name, levels = name))
pB <- ggplot(pB_df, aes(dif, name, fill = dif)) +
  geom_col() +
  scale_fill_er_div(midpoint = 0, name = "Años\nvs prom.") +
  labs(title = "Divergente", subtitle = "Edad respecto del promedio (27,7)") +
  base_t + theme(axis.text.y = element_text(size = 6, color = NEG),
                 axis.text.x = element_text(size = 8, color = GR),
                 legend.position = "right", legend.key.width = unit(0.3,"cm"),
                 legend.title = element_text(size = 8))

# C · CUALITATIVA — composición por puesto
pC_df <- plantel |> count(pos_grupo, name = "n") |> arrange(desc(n)) |>
  mutate(pos_grupo = factor(pos_grupo, levels = rev(pos_grupo)))
pC <- ggplot(pC_df, aes(n, pos_grupo, fill = pos_grupo)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = n), hjust = -0.4, family = FF, fontface = "bold",
            size = 4, color = NEG) +
  scale_fill_er_q(guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Cualitativa", subtitle = "Jugadores por puesto") +
  base_t + theme(panel.grid = element_blank(), axis.text.x = element_blank(),
                 axis.text.y = element_text(size = 11, color = NEG))

final <- (pA | pB | pC) +
  plot_annotation(
    title = "Las paletas de Estación R, aplicadas",
    subtitle = "Mismos datos del plantel, cada paleta para su tipo de variable",
    theme = theme(plot.title = element_text(family = FF, face = "bold", size = 18, color = NEG),
                  plot.subtitle = element_text(family = FF, size = 11, color = GR),
                  plot.background = element_rect(fill = "white", color = NA),
                  plot.margin = margin(18, 18, 14, 18)))
ggsave(file.path(ROOT, "paleta_aplicada.png"), final, width = 1500/150, height = 720/150,
       dpi = 150, device = ragg::agg_png, bg = "white")
cat("✔ paleta_aplicada.png\n")
