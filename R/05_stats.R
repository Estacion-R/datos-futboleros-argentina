# ==========================================================================
# 03_stats.R — Estadísticas nuevas: valor de mercado, ligas, campeones 2022
# Cards 1080x1350 con la identidad de Estación R. Source-able desde el .qmd.
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

suppressMessages({ library(ggplot2); library(dplyr); library(stringr); library(ragg)
  library(ggtext); library(tibble) })

# --- Marca Estación R -------------------------------------------------------
ER_AZUL <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7"; ER_BLANCO <- "#FFFFFF"; GRIS_TXT <- "#6F6F6F"
ok_font <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu", "ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
FF <- if (ok_font) "ubuntu" else "sans"

# Plan B legal: SIN_FOTOS=1 arma la card de campeones con círculos numerados
# (número de camiseta) en vez de caras. Las cards de valor (05) y ligas (06) no
# llevan fotos → no se regeneran en modo SIN_FOTOS para no pisar las confirmadas.
SIN_FOTOS <- Sys.getenv("SIN_FOTOS", "0") == "1"

theme_er <- function() {
  theme_minimal(base_family = FF) +
    theme(plot.background = element_rect(fill = ER_BLANCO, color = NA),
          panel.background = element_rect(fill = ER_BLANCO, color = NA),
          plot.title = element_text(family = FF, face = "bold", size = 27, color = ER_NEGRO),
          plot.subtitle = element_text(family = FF, size = 14, color = GRIS_TXT,
                                       margin = margin(t = 4, b = 12)),
          plot.caption = element_text(family = FF, size = 11, color = GRIS_TXT,
                                      hjust = 0, lineheight = 1.05, margin = margin(t = 14)),
          plot.margin = margin(34, 34, 26, 34), axis.title = element_blank(),
          panel.grid.minor = element_blank())
}
save_card <- function(p, file, h = 1350) {
  ggsave(file.path(ROOT, "cards", file), p, width = 1080/150, height = h/150,
         dpi = 150, device = ragg::agg_png, bg = ER_BLANCO)
  cat("✔", file, "\n")
}
eur <- function(x) paste0("€", formatC(x, format = "f", digits = 0, big.mark = "."))

# --- Enriquecer: campeón 2022 (liga + liga_meta vienen de 00_prep.R) --------
# Plantel campeón Qatar 2022 (26 oficial). Nico González fue citado pero se
# lesionó y fue reemplazado ANTES del torneo -> no cuenta. Almada sí (reemplazó
# a J. Correa). Verificado con Wikipedia / squads 2022.
campeones_2022 <- c("Emiliano Martínez", "Gerónimo Rulli", "Cristian Romero",
  "Lisandro Martínez", "Nicolás Otamendi", "Nicolás Tagliafico", "Gonzalo Montiel",
  "Nahuel Molina", "Rodrigo De Paul", "Leandro Paredes", "Alexis Mac Allister",
  "Enzo Fernández", "Exequiel Palacios", "Lionel Messi", "Julián Álvarez",
  "Thiago Almada", "Lautaro Martínez")
# Notas: Acuña salió (no en 26); Lautaro, Lisandro M. y Montiel ya estaban en el
# plantel campeón 2022. Lo Celso y Nico González estaban convocados 2022 pero
# lesionados antes del torneo → NO cuentan como campeones.

plantel <- plantel |>
  mutate(campeon22 = name %in% campeones_2022)

# Chequeo: ninguna liga debería quedar NA (club sin mapear en club_liga).
if (any(is.na(plantel$liga))) {
  faltan <- unique(plantel$club[is.na(plantel$liga)])
  warning("Clubes sin liga asignada (caen como NA): ", paste(faltan, collapse = ", "))
}

# ============================ CARD 5 · VALOR ===============================
# Pablo: "Messi no aparece" → antes mostrábamos sólo el top 12 (Messi vale
# €15 M y quedaba afuera). Ahora se grafican los 26, ordenados por valor y
# COLOREADOS POR POSICIÓN. Así Messi aparece y se ve qué línea concentra valor.
total_val <- sum(plantel$mv_eur)
POS_NIV  <- c("Arquero", "Defensor", "Mediocampista", "Delantero")
POS_COL  <- c(Arquero = "#E6A100", Defensor = ER_AZUL,
              Mediocampista = "#2CA6C4", Delantero = "#B3294E")
val_pos <- plantel |> group_by(pos_grupo) |> summarise(v = sum(mv_eur)) |>
  arrange(desc(v))
linea_top <- val_pos$pos_grupo[1]

val_all <- plantel |> arrange(desc(mv_eur), desc(caps)) |>
  mutate(name = factor(name, levels = rev(name)),
         pos_grupo = factor(pos_grupo, levels = POS_NIV))

p_val <- ggplot(val_all, aes(mv_eur, name, fill = pos_grupo)) +
  geom_col(width = 0.78) +
  geom_text(aes(label = eur(mv_eur)), hjust = -0.18, family = FF,
            fontface = "bold", size = 3.4, color = ER_NEGRO) +
  scale_fill_manual(values = POS_COL, name = NULL, drop = FALSE) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.16))) +
  guides(fill = guide_legend(nrow = 1, override.aes = list(size = 5))) +
  labs(title = paste0("Un plantel de ", eur(total_val), " M"),
       subtitle = "Valor de mercado por jugador, según posición",
       caption = paste0("Messi, a los 38, figura con €15 M: lejos del top, pero ahí está.\n",
                        "Los ", tolower(linea_top), "s concentran el mayor valor.\n",
                        "Datos: Transfermarkt · Estación R")) +
  theme_er() +
  theme(panel.grid = element_blank(), axis.text.x = element_blank(),
        axis.text.y = element_text(size = 10.5, color = ER_NEGRO),
        legend.position = "top", legend.justification = "left",
        legend.text = element_text(size = 12, color = ER_NEGRO))
if (!SIN_FOTOS) save_card(p_val, "05_valor.png", h = 1500)

# ============================ CARD 6 · LIGAS ===============================
# Pablo: escudo de la liga junto a la etiqueta + país en gris como subtítulo
# debajo del nombre. OJO: element_markdown en el eje NO renderiza con showtext
# (sale el HTML crudo); en cambio geom_richtext SÍ. Por eso la etiqueta (logo +
# nombre + país) se dibuja con geom_richtext en un canalón a la izquierda.
por_liga <- plantel |> count(liga, name = "n") |>
  left_join(liga_meta, by = "liga") |>
  arrange(n) |>
  mutate(
    top = n == max(n),
    yy  = row_number(),
    etq = paste0(
      "<img src='", logo, "' height='26'/> ",
      "<span style='font-size:15pt'>**", liga, "**</span>",
      "<br><span style='font-size:10pt;color:#6F6F6F'>", pais, "</span>"))

maxn <- max(por_liga$n)
# OJO: con y numérico, geom_col NO autodetecta orientación → dibuja barras
# verticales. Hay que forzar orientation = "y" para que sean horizontales.
p_liga <- ggplot(por_liga, aes(x = n, y = yy)) +
  geom_col(aes(fill = top), width = 0.62, orientation = "y") +
  # número al final de la barra
  geom_text(aes(x = n, y = yy, label = n), hjust = -0.5, family = FF,
            fontface = "bold", size = 5.4, color = ER_NEGRO) +
  # etiqueta rica (logo + nombre + país) en el canalón izquierdo
  ggtext::geom_richtext(aes(x = 0, y = yy, label = etq), hjust = 1, vjust = 0.5,
                        nudge_x = -maxn * 0.04, fill = NA, label.color = NA,
                        label.padding = unit(c(0, 0, 0, 0), "pt"), lineheight = 1.05) +
  scale_fill_manual(values = c(`FALSE` = ER_AZUL, `TRUE` = ER_NEGRO), guide = "none") +
  scale_x_continuous(limits = c(-maxn * 1.15, maxn * 1.12), expand = c(0, 0)) +
  scale_y_continuous(expand = expansion(add = 0.65)) +
  labs(title = "¿En qué ligas juegan?",
       subtitle = "Jugadores del plantel por liga",
       caption = "LaLiga lidera, sobre todo por el Atlético de Madrid (6 jugadores).") +
  theme_er() +
  theme(panel.grid = element_blank(), axis.text = element_blank(),
        axis.ticks = element_blank())
if (!SIN_FOTOS) save_card(p_liga, "06_ligas.png", h = 1250)

# ========================= CARD 7 · CAMPEONES 2022 ========================
# Pablo: caras en vez de círculos + el nombre debajo. Campeones a color,
# el resto en gris. Grilla de los 26, ordenada por línea.
n_total <- nrow(plantel)
n_camp  <- sum(plantel$campeon22)
source(file.path(ROOT, "R/_caras.R"))
img_c <- readRDS(file.path(ROOT, "data/img_urls.rds")) |> select(name, foto_file, slug)

short_camp <- function(x) {
  x <- str_replace(x, "^Lionel Messi$", "Messi")
  x <- str_replace(x, "^Julián Álvarez$", "J. Álvarez")
  x <- str_replace(x, "^Emiliano Martínez$", "Dibu Martínez")
  x <- str_replace(x, "^(\\S)\\S+\\s+(.+)$", "\\1. \\2")
  x
}

NCOL <- 6
camp_df <- plantel |>
  mutate(pos_grupo = factor(pos_grupo, levels = POS_NIV)) |>
  arrange(pos_grupo, desc(campeon22), desc(caps)) |>
  left_join(img_c, by = "name") |>
  mutate(
    idx = row_number() - 1,
    col = idx %% NCOL,
    row = idx %/% NCOL,
    nombre = short_camp(name))

# Caption + subtítulo + tema comunes a las dos variantes.
cap_fuente <- if (SIN_FOTOS) "Datos: Transfermarkt · Estación R" else
              "Datos e imágenes: Transfermarkt · Estación R"
lab_camp <- labs(
  title = "Campeones del mundo",
  subtitle = paste0("**", n_camp, " de los ", n_total,
                    "** ya levantaron la copa en Qatar 2022"),
  caption = paste0("En color, los ", n_camp, " campeones; en gris, los que aún no lo fueron.\n",
                   "Nico González y Lo Celso fueron citados en 2022 pero se lesionaron antes del torneo.\n",
                   cap_fuente))
thm_camp <- theme_er() +
  theme(axis.text = element_blank(), panel.grid = element_blank(),
        plot.subtitle = ggtext::element_markdown(size = 15, color = "#6F6F6F",
                                                 margin = margin(t = 4, b = 16)),
        plot.margin = margin(34, 24, 26, 24))

if (SIN_FOTOS) {
  # Sin caras: círculo con el número de camiseta (azul = campeón, gris = no).
  camp_df <- camp_df |>
    mutate(fill_col = ifelse(campeon22, ER_AZUL, "#DADADA"),
           num_col  = ifelse(campeon22, "white", "#9A9A9A"),
           nom_col  = ifelse(campeon22, ER_NEGRO, "#B0B0B0"))
  p_camp <- ggplot(camp_df, aes(col, -row)) +
    geom_point(aes(fill = fill_col), shape = 21, size = 13, stroke = 1.1, color = "white") +
    geom_text(aes(label = shirt, color = num_col), family = FF, fontface = "bold", size = 4.6) +
    geom_text(aes(label = nombre, color = nom_col), vjust = 1, nudge_y = -0.46,
              family = FF, fontface = "bold", size = 2.7) +
    scale_fill_identity() + scale_color_identity() +
    coord_cartesian(clip = "off") + lab_camp + thm_camp
} else {
  camp_df <- camp_df |>
    mutate(cara = mapply(function(f, s, camp) {
             out <- file.path(ROOT, "assets/caras",
                              paste0(s, if (camp) ".png" else "_gray.png"))
             make_circle(file.path(ROOT, f), out, gray = !camp)
           }, foto_file, slug, campeon22),
           label = sprintf("<img src='%s' width='52'/>", cara))
  p_camp <- ggplot(camp_df, aes(col, -row)) +
    geom_richtext(aes(label = label), fill = NA, label.color = NA,
                  label.padding = unit(0, "pt")) +
    geom_text(aes(label = nombre, color = campeon22), vjust = 1, nudge_y = -0.34,
              family = FF, fontface = "bold", size = 2.7) +
    scale_color_manual(values = c(`TRUE` = ER_NEGRO, `FALSE` = "#B0B0B0"), guide = "none") +
    coord_cartesian(clip = "off") + lab_camp + thm_camp
}
save_card(p_camp, if (SIN_FOTOS) "07_campeones_sf.png" else "07_campeones.png", h = 1150)

cat("\nCards de estadísticas generadas. Campeones 2022:", n_camp,
    "| ligas sin NA:", !any(is.na(plantel$liga)), "\n")
