# ==========================================================================
# 01_cards.R — Genera las cards para redes (PNG 1080x1350, formato IG)
# ==========================================================================
source(file.path(if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina",
  "R/00_prep.R"))

suppressMessages({ library(ggplot2); library(ggrepel); library(scales); library(ragg) })

# --- Identidad visual oficial de Estación R ---------------------------------
ER_AZUL  <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7";  ER_BLANCO <- "#FFFFFF"
GRIS_TXT <- "#6F6F6F"; BG <- ER_BLANCO
# Aliases internos -> marca ER (mantienen el resto del código sin tocar)
CELESTE <- ER_AZUL; CELESTE_D <- ER_AZUL_D; CELESTE_XD <- ER_NEGRO
DORADO  <- ER_AZUL_D; TINTA <- ER_NEGRO; GRIS <- GRIS_TXT

# Tipografía de marca: Ubuntu (Array, de títulos, no está disponible libre).
ok_font <- tryCatch({
  library(showtext)
  sysfonts::font_add_google("Ubuntu", "ubuntu")
  showtext_auto(); showtext_opts(dpi = 150)
  TRUE
}, error = function(e) FALSE)
F_TIT <- if (ok_font) "ubuntu" else "sans"
F_TXT <- if (ok_font) "ubuntu" else "sans"

theme_card <- function() {
  theme_minimal(base_family = F_TXT) +
    theme(
      plot.background  = element_rect(fill = BG, color = NA),
      panel.background = element_rect(fill = BG, color = NA),
      plot.title    = element_text(family = F_TIT, face = "bold", size = 27,
                                   color = TINTA, lineheight = 1),
      plot.subtitle = element_text(family = F_TXT, size = 14, color = GRIS,
                                   margin = margin(t = 4, b = 12)),
      plot.caption  = element_text(family = F_TXT, size = 11, color = GRIS,
                                   hjust = 0, lineheight = 1.05, margin = margin(t = 12)),
      plot.margin   = margin(34, 34, 26, 34),
      axis.title    = element_blank(),
      panel.grid.minor = element_blank()
    )
}
TAG <- "Estación R · Datos: Transfermarkt"
save_card <- function(p, file, w = 1080, h = 1350) {
  ggsave(file.path("cards", file), p, width = w/150, height = h/150,
         dpi = 150, device = ragg::agg_png, bg = BG)
  cat("✔", file, "\n")
}
if (!dir.exists("cards")) dir.create("cards")

# ============================ CARD 1 · MAPA ================================
library(patchwork); library(farver)
source(file.path(if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina",
  "R/paleta_estacion_r.R"))   # secuencial oficial (B)
seq256 <- er_pal_seq(256)
max_prov <- max(mapa_data$jugadores)
fill_scale <- scale_fill_gradientn(
  colours = seq256, limits = c(0, max_prov),
  breaks = unique(c(0, seq(4, max_prov, by = 4), max_prov)))
# Texto contrastante según la luminancia del relleno (alto=amarillo->negro)
txt_contraste <- function(v) {
  hex <- seq256[pmax(1, pmin(256, round(v / 16 * 255) + 1))]
  rgb <- farver::decode_colour(hex)
  lum <- 0.299 * rgb[, 1] + 0.587 * rgb[, 2] + 0.114 * rgb[, 3]
  ifelse(lum > 140, ER_NEGRO, "white")
}

caba <- mapa_data[mapa_data$nombre == "Ciudad Autónoma de Buenos Aires", ]
prov_ba <- mapa_data[mapa_data$nombre == "Buenos Aires", ]

# Centroides para etiquetas en el mapa nacional (TODAS las provincias con >=1,
# sin CABA). Pedido de Pablo: etiquetar cada provincia con al menos un jugador.
cents <- sf::st_centroid(mapa_data[mapa_data$jugadores >= 1 &
                                   mapa_data$nombre != "Ciudad Autónoma de Buenos Aires", ])
cents_xy <- cbind(as.data.frame(sf::st_coordinates(cents)),
                  jugadores = cents$jugadores)
caba_pt <- as.data.frame(sf::st_coordinates(sf::st_centroid(caba)))

# --- Mapa nacional ----------------------------------------------------------
# El número va DENTRO del polígono, sólo si la provincia tiene jugadores (>0).
lab_nac <- cents_xy[cents_xy$jugadores > 0, ]
lab_nac$col_txt <- txt_contraste(lab_nac$jugadores)

# Marca de ubicación de CABA: capa aparte, para mostrarla SÓLO cuando aparece
# el zoom (en el HTML el mapa "solo" va sin marca; el "zoom" la trae).
mark_caba <- annotate("point", x = caba_pt$X, y = caba_pt$Y, shape = 21, size = 5,
                      stroke = 1.1, color = ER_NEGRO, fill = NA)

p_main_base <- ggplot(mapa_data) +
  geom_sf(aes(fill = jugadores), color = "white", linewidth = 0.25) +
  geom_text(data = lab_nac, aes(X, Y, label = jugadores, color = col_txt),
            family = F_TIT, fontface = "bold", size = 6) +
  scale_color_identity() +
  # Islas Malvinas (geoAr las incluye; las señalamos siempre)
  annotate("text", x = -57.4, y = -51.7, label = "Islas\nMalvinas",
           family = F_TXT, size = 3, color = GRIS_TXT, hjust = 0, lineheight = 0.85) +
  fill_scale +
  guides(fill = guide_colorbar(title = NULL, barheight = 0.6, barwidth = 11,
                               ticks = FALSE)) +
  theme_card() +
  theme(axis.text = element_blank(), panel.grid = element_blank(),
        legend.position = "top", legend.justification = "left",
        legend.text = element_text(size = 11, color = GRIS_TXT))

p_main <- p_main_base + mark_caba   # con la marca de CABA (para la card de redes)

# --- Panel derecho: zoom a CABA (capital vs provincia) ----------------------
# Mismo coloreo que el mapa nacional: CABA = 0 -> claro (sin número), provincia
# = 16 -> azul fuerte. La distinción capital/provincia queda a la vista.
ins_box <- list(xmin = -58.78, xmax = -58.12, ymin = -34.95, ymax = -34.42)
metro <- sf::st_crop(mapa_data, xmin = ins_box$xmin, xmax = ins_box$xmax,
                     ymin = ins_box$ymin, ymax = ins_box$ymax)
p_zoom <- ggplot(metro) +
  geom_sf(aes(fill = jugadores), color = "white", linewidth = 0.4) +
  geom_sf(data = caba, fill = NA, color = ER_NEGRO, linewidth = 0.9) +
  annotate("segment", x = -58.74, xend = -58.47, y = -34.49, yend = -34.59,
           color = ER_NEGRO, linewidth = 0.5) +
  annotate("text", x = -58.76, y = -34.46, label = "CABA (capital)",
           family = F_TIT, fontface = "bold", size = 4.4, color = ER_NEGRO, hjust = 0) +
  annotate("text", x = -58.40, y = -34.90, label = "Prov. de Bs. As.",
           family = F_TXT, fontface = "bold", size = 3.7, color = ER_NEGRO, hjust = 0.5) +
  fill_scale +
  coord_sf(xlim = c(ins_box$xmin, ins_box$xmax),
           ylim = c(ins_box$ymin, ins_box$ymax), expand = FALSE) +
  labs(title = "Zoom: la Capital") +
  theme_void(base_family = F_TXT) +
  theme(legend.position = "none",
        plot.title = element_text(family = F_TXT, face = "bold", size = 13,
                                  color = ER_NEGRO, hjust = 0.5, margin = margin(b = 4)),
        plot.background = element_rect(fill = ER_BLANCO, color = "#D9D9D9"),
        plot.margin = margin(7, 7, 7, 7))

p_mapa <- (p_main | p_zoom) + plot_layout(widths = c(1.5, 1)) +
  plot_annotation(
    title = paste0("¿De dónde salen los ", nrow(plantel), "?"),
    subtitle = "Jugadores del plantel según provincia de nacimiento",
    caption = paste0(
      "Los ", por_provincia$jugadores[por_provincia$provincia == "Buenos Aires"],
      " son de la PROVINCIA de Buenos Aires; de la Ciudad (CABA), ninguno.\n",
      sum(plantel$pais != "Argentina"), " nacieron en el exterior: Nico Paz (España) y G. Simeone (Italia)."),
    theme = theme(
      plot.title    = element_text(family = F_TIT, face = "bold", size = 27, color = TINTA),
      plot.subtitle = element_text(family = F_TXT, size = 14, color = GRIS,
                                   margin = margin(t = 4, b = 8)),
      plot.caption  = element_text(family = F_TXT, size = 11, color = GRIS,
                                   hjust = 0, lineheight = 1.05, margin = margin(t = 12)),
      plot.background = element_rect(fill = BG, color = NA),
      plot.margin = margin(34, 34, 26, 34)))
save_card(p_mapa, "01_mapa_origenes.png")

# --- Versiones para el HTML (closeread): mapa solo -> zoom al scrollear ------
# Pablo: primero el mapa de Argentina SIN el zoom; al scrollear aparece el zoom
# con el comentario. Para que el mapa nacional NO se mueva al revelar el panel,
# la versión "solo" reserva el mismo ancho con un plot_spacer().
ann_mapa <- function(sub) plot_annotation(
  title = paste0("¿De dónde salen los ", nrow(plantel), "?"),
  subtitle = sub,
  theme = theme(
    plot.title    = element_text(family = F_TIT, face = "bold", size = 27, color = TINTA),
    plot.subtitle = element_text(family = F_TXT, size = 14, color = GRIS,
                                 margin = margin(t = 4, b = 8)),
    plot.background = element_rect(fill = BG, color = NA),
    plot.margin = margin(34, 34, 26, 34)))

# 1) Mapa SOLO (sin marca de CABA, sin panel): el espacio del zoom queda vacío.
p_mapa_solo <- (p_main_base | patchwork::plot_spacer()) +
  plot_layout(widths = c(1.5, 1)) +
  ann_mapa("Jugadores del plantel según provincia de nacimiento")
save_card(p_mapa_solo, "01_mapa_solo.png", h = 1080)

# 2) Mapa CON zoom (marca de CABA + panel ampliado a la derecha).
p_mapa_zoom <- (p_main | p_zoom) + plot_layout(widths = c(1.5, 1)) +
  ann_mapa("Capital y provincia no son lo mismo")
save_card(p_mapa_zoom, "01_mapa_zoom.png", h = 1080)

# === Mapas para scrolling progresivo en el HTML ==============================
# 5 pasos: base (sin choropleth) → BA amarillo → Cba/SF → resto → choropleth final
MAPA_CON <- "#C8D6FF"   # azul muy claro: provincia con ≥1 jugador
MAPA_SIN <- "#E8E8E8"   # gris neutro: sin jugadores
MAPA_HL  <- "#EAFF38"   # amarillo: provincia destacada en el beat actual

build_mapa_highlight <- function(provincias_hl = character(0), subtitulo = "") {
  d <- mapa_data |>
    dplyr::mutate(
      fill_c  = dplyr::case_when(
        nombre %in% provincias_hl ~ MAPA_HL,
        jugadores > 0             ~ MAPA_CON,
        TRUE                      ~ MAPA_SIN),
      borde_c = ifelse(nombre %in% provincias_hl, ER_NEGRO, "white"),
      borde_w = ifelse(nombre %in% provincias_hl, 1.2, 0.25))
  con_jug <- d[d$jugadores >= 1 & d$nombre != "Ciudad Autónoma de Buenos Aires", ]
  ctrs <- cbind(
    as.data.frame(sf::st_coordinates(sf::st_centroid(con_jug))),
    jugadores = con_jug$jugadores)
  ggplot(d) +
    geom_sf(aes(fill = fill_c, color = borde_c, linewidth = borde_w)) +
    geom_text(data = ctrs, aes(X, Y, label = jugadores),
              color = ER_NEGRO, family = F_TIT, fontface = "bold", size = 6) +
    scale_fill_identity() + scale_color_identity() + scale_linewidth_identity() +
    annotate("text", x = -57.4, y = -51.7, label = "Islas\nMalvinas",
             family = F_TXT, size = 3, color = GRIS_TXT, hjust = 0, lineheight = 0.85) +
    theme_card() +
    theme(axis.text = element_blank(), panel.grid = element_blank(),
          legend.position = "none") +
    labs(title = paste0("¿De dónde salen los ", nrow(plantel), "?"),
         subtitle = subtitulo, caption = NULL)
}

save_card(
  build_mapa_highlight(subtitulo = "Las provincias en azul tienen al menos un jugador"),
  "01_mapa_base.png", h = 1080)
save_card(
  build_mapa_highlight("Buenos Aires",
    paste0("Buenos Aires aporta ",
           mapa_data$jugadores[mapa_data$nombre == "Buenos Aires"],
           " de los ", nrow(plantel), " convocados")),
  "01_mapa_hl_ba.png", h = 1080)
save_card(
  build_mapa_highlight(c("Córdoba", "Santa Fe"),
    "Córdoba y Santa Fe suman 3 jugadores cada una"),
  "01_mapa_hl_cbsf.png", h = 1080)
save_card(
  build_mapa_highlight(c("La Pampa", "Entre Ríos", "San Luis", "Tucumán"),
    "La Pampa, Entre Ríos, San Luis y Tucumán: 1 cada una"),
  "01_mapa_hl_resto.png", h = 1080)

# ============================ CARD 2 · EDAD ================================
# Versión "annotator": jitter + línea de promedio + FLECHAS CURVAS a los casos
# destacados (más joven / los más grandes). Definida en R/_edad_plot.R, que el
# HTML reutiliza para mostrarla grande (un solo origen de verdad).
source(file.path(if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina",
  "R/_edad_plot.R"))
p_edad <- build_edad_plot(plantel, prom = dato_edad$prom, FF = F_TXT, scale = 1.5) +
  labs(caption = TAG) +
  theme(plot.title    = element_text(family = F_TIT, face = "bold", size = 27, color = TINTA),
        plot.subtitle = element_text(family = F_TXT, size = 14, color = GRIS,
                                     margin = margin(t = 4, b = 12)),
        plot.caption  = element_text(family = F_TXT, size = 11, color = GRIS,
                                     hjust = 0, margin = margin(t = 14)),
        plot.margin   = margin(34, 34, 26, 34))
save_card(p_edad, "02_edad.png")

# ============================ CARD 3 · CAPS ================================
# Caras en barras largas tapan el dato; se deja limpia, con Messi resaltado.
pl_caps <- top_caps |> dplyr::mutate(
  name = factor(name, levels = rev(name)),
  es_messi = caps == max(caps))

p_caps <- ggplot(pl_caps, aes(caps, name, fill = es_messi)) +
  geom_col(width = 0.72) +
  geom_text(aes(label = caps), hjust = -0.25, family = F_TIT,
            fontface = "bold", size = 4, color = TINTA) +
  scale_fill_manual(values = c(`FALSE` = ER_AZUL, `TRUE` = ER_NEGRO), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "La mochila de la experiencia",
       subtitle = "Partidos jugados con la Selección mayor (caps)",
       caption = paste0("Messi acumula ", max(plantel$caps),
                        " caps: casi 4 veces el promedio del plantel.\n",
                        "Entre los ", nrow(plantel), " suman ", total_caps,
                        " partidos con la celeste.")) +
  theme_card() +
  theme(panel.grid = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_text(size = 11.5, color = TINTA))
save_card(p_caps, "03_caps.png", h = 1500)

# ========================= CARD 4 · EXTERIOR ==============================
# Aislada en R/_exterior_plot.R (rediseño B: el "2" en AMARILLO sobre el bloque
# negro + nota con annotate saliendo del "24" con la liga más elegida). Fuente
# única; al tocar este "en bloque" se refactorizó a función propia.
source(file.path(if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina",
  "R/_exterior_plot.R"))
save_card(build_exterior_plot(), "04_exterior.png", h = 1080)

cat("\nCards generadas en cards/\n")
