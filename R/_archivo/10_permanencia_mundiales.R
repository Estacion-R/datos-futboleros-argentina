# 10_permanencia_mundiales.R
# Tasa de permanencia de Argentina entre Mundiales consecutivos
# Fuente: Fjelstul World Cup Database (paquete worldcup)

library(worldcup)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggtext)
library(forcats)
library(showtext)

# Fuente
font_add_google("Inter", "inter")
font_add_google("Bebas Neue", "bebas")
showtext_auto()

# ─── Paleta Estación R ───
source(here::here("R/paleta_estacion_r.R"))

# ─── Datos ───
torneos_masc <- tournaments |>
  filter(grepl("Men's", tournament_name)) |>
  pull(tournament_id)

arg <- squads |>
  filter(team_name == "Argentina", tournament_id %in% torneos_masc) |>
  select(tournament_id, player_id, family_name, given_name, position_code) |>
  arrange(tournament_id)

torneos_arg <- arg |> distinct(tournament_id) |> arrange(tournament_id) |> pull()
todos_masc  <- sort(torneos_masc)
idx_arg     <- which(todos_masc %in% torneos_arg)

pares_conseq <- tibble(
  idx1 = idx_arg[-length(idx_arg)],
  idx2 = idx_arg[-1]
) |>
  mutate(
    t1 = todos_masc[idx1],
    t2 = todos_masc[idx2],
    consecutivos = idx2 - idx1 == 1
  ) |>
  filter(consecutivos)

permanencia <- pares_conseq |>
  rowwise() |>
  mutate(
    plantel_t1    = list(arg |> filter(tournament_id == t1) |> pull(player_id)),
    plantel_t2    = list(arg |> filter(tournament_id == t2) |> pull(player_id)),
    n_t1          = length(plantel_t1),
    n_t2          = length(plantel_t2),
    n_repiten     = length(intersect(plantel_t1, plantel_t2)),
    pct           = round(n_repiten / n_t1 * 100, 1),
    anio_t1       = as.integer(substr(t1, 4, 7)),
    anio_t2       = as.integer(substr(t2, 4, 7))
  ) |>
  ungroup()

# Mundiales donde Argentina fue campeón saliente (para anotar)
campeon_previo <- c(1978, 1986, 2022)

# ─── Guardar dataset ───
saveRDS(permanencia, here::here("data/permanencia_arg.rds"))
write.csv(
  permanencia |> select(anio_t1, anio_t2, n_t1, n_t2, n_repiten, pct),
  here::here("data/permanencia_arg.csv"),
  row.names = FALSE
)

# ─── Visualización: año a año con línea + puntos ───
df_plot <- permanencia |>
  mutate(
    # El punto se ubica en el año del segundo mundial (el que "entra")
    campeon_previo = anio_t1 %in% campeon_previo,
    label_punto    = paste0(pct, "%\n(", n_repiten, "/", n_t1, ")")
  )

# media histórica
media_pct <- mean(df_plot$pct)

p <- df_plot |>
  ggplot(aes(x = anio_t2, y = pct)) +
  # línea de media
  geom_hline(
    yintercept = media_pct,
    linetype = "dashed",
    color = "grey70",
    linewidth = 0.5
  ) +
  annotate(
    "text",
    x = min(df_plot$anio_t2) - 0.5,
    y = media_pct + 1.5,
    label = paste0("Media: ", round(media_pct, 1), "%"),
    hjust = 0,
    family = "inter",
    size = 3,
    color = "grey50"
  ) +
  # línea conectora
  geom_line(
    color = ER_AZUL,
    linewidth = 0.8,
    alpha = 0.6
  ) +
  # puntos: campeón saliente vs normal
  geom_point(
    aes(
      fill  = campeon_previo,
      size  = campeon_previo
    ),
    shape = 21,
    color = "white",
    stroke = 1.5
  ) +
  scale_fill_manual(
    values = c("FALSE" = ER_AZUL, "TRUE" = ER_AMARILLO),
    guide  = "none"
  ) +
  scale_size_manual(
    values = c("FALSE" = 3.5, "TRUE" = 5.5),
    guide  = "none"
  ) +
  # etiquetas sobre cada punto
  geom_text(
    aes(label = label_punto),
    vjust     = -0.6,
    family    = "inter",
    size      = 3,
    lineheight = 0.85,
    color     = "grey25"
  ) +
  # eje x: solo los años de interés
  scale_x_continuous(
    breaks = df_plot$anio_t2,
    labels = df_plot$anio_t2
  ) +
  scale_y_continuous(
    limits = c(0, 85),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.05))
  ) +
  # nota de leyenda de color
  annotate(
    "point",
    x = min(df_plot$anio_t2),
    y = 78,
    size = 5, shape = 21,
    fill = ER_AMARILLO, color = "white", stroke = 1.5
  ) +
  annotate(
    "text",
    x = min(df_plot$anio_t2) + 1.5,
    y = 78,
    label = "Argentina era campeón vigente al entrar a ese Mundial",
    hjust = 0, family = "inter", size = 3, color = "grey40"
  ) +
  labs(
    title    = "¿Cuántos jugadores repitió Argentina de un Mundial al siguiente?",
    subtitle = "Permanencia del plantel año a año • % del plantel anterior que volvió al siguiente Mundial",
    x        = "Año del Mundial (destino)",
    y        = "% del plantel anterior que repitió",
    caption  = "Solo se computan pares de Mundiales consecutivos donde Argentina clasificó a ambos.\nFuente: Fjelstul World Cup Database · Elaboración: Estación R"
  ) +
  theme_minimal(base_family = "inter") +
  theme(
    plot.title         = element_text(face = "bold", size = 14, family = "bebas"),
    plot.subtitle      = element_text(size = 9, color = "grey40"),
    plot.caption       = element_text(size = 7.5, color = "grey60", lineheight = 1.2),
    axis.text.x        = element_text(size = 9),
    axis.text.y        = element_text(size = 9),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.background    = element_rect(fill = "white", color = NA),
    plot.margin        = margin(12, 16, 12, 12)
  )

# Guardar
ggsave(
  here::here("previews/10_permanencia_arg.png"),
  plot = p, width = 11, height = 6, dpi = 150, bg = "white"
)

message("✅ 10_permanencia_mundiales.R completado")
