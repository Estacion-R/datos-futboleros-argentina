# ==========================================================================
# 08_valor_packing.R — Circular packing del valor de mercado del plantel.
# Alternativa a la card de barras (05_valor): cada jugador es una burbuja
# (área ∝ valor de mercado), agrupada por posición. Inspirado en el packing
# del presupuesto de Obama (d3.js) visto en dataviz-inspiration.com, en R.
#
# Expone:
#   build_packing(interactive = FALSE)  -> ggplot (interactivo con ggiraph)
#   build_packing_girafe()              -> objeto girafe para el HTML/Quarto
# El bloque standalone (sys.nframe()==0) regenera la card PNG estática.
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

suppressMessages({ library(packcircles); library(dplyr); library(ggplot2)
  library(ggtext); library(ragg); library(farver); library(ggiraph) })

# --- Marca Estación R -------------------------------------------------------
ER_AZUL <- "#405BFF"; ER_NEGRO <- "#191919"; ER_BLANCO <- "#FFFFFF"
GRIS_TXT <- "#6F6F6F"
ok_font <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu", "ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
FF <- if (ok_font) "ubuntu" else "sans"

# Misma paleta por posición que la card de barras (05_valor)
POS_NIV <- c("Arquero", "Defensor", "Mediocampista", "Delantero")
POS_COL <- c(Arquero = "#E6A100", Defensor = ER_AZUL,
             Mediocampista = "#2CA6C4", Delantero = "#B3294E")
POS_PL  <- c(Arquero = "Arqueros", Defensor = "Defensores",
             Mediocampista = "Mediocampistas", Delantero = "Delanteros")
eur <- function(x) paste0("€", formatC(x, format = "f", digits = 0, big.mark = ""), " M")

# ==========================================================================
# 1) Cálculo del layout jerárquico (posición -> jugador) ---------------------
# ==========================================================================
.compute_packing <- function() {
  grp <- plantel |>
    group_by(pos_grupo) |>
    summarise(v = sum(mv_eur), n = dplyr::n(), .groups = "drop") |>
    mutate(pos_grupo = factor(pos_grupo, levels = POS_NIV)) |>
    arrange(desc(v))
  g_lay <- circleProgressiveLayout(grp$v, sizetype = "area")
  grp <- bind_cols(grp, g_lay)            # x, y, radius del círculo del grupo

  players <- plantel |> select(name, pos_grupo, mv_eur, club, caps)
  inner <- lapply(seq_len(nrow(grp)), function(i) {
    gi  <- grp[i, ]
    sub <- players |> filter(pos_grupo == gi$pos_grupo) |> arrange(desc(mv_eur))
    lay <- circleProgressiveLayout(sub$mv_eur, sizetype = "area")
    cx <- (max(lay$x + lay$radius) + min(lay$x - lay$radius)) / 2
    cy <- (max(lay$y + lay$radius) + min(lay$y - lay$radius)) / 2
    lay$x <- lay$x - cx; lay$y <- lay$y - cy
    ext <- max(sqrt(lay$x^2 + lay$y^2) + lay$radius)
    sc  <- (gi$radius * 0.93) / ext
    sub$x <- gi$x + lay$x * sc
    sub$y <- gi$y + lay$y * sc
    sub$radius <- lay$radius * sc
    sub
  })
  players_lay <- bind_rows(inner) |>
    mutate(id = row_number(),
           pos_grupo = factor(pos_grupo, levels = POS_NIV),
           apellido  = sub("^.*\\s", "", name),
           apellido  = dplyr::case_when(
             name == "Emiliano Martínez"   ~ "Dibu",
             name == "Lautaro Martínez"    ~ "Lautaro",
             name == "Lisandro Martínez"   ~ "Licha",
             name == "Alexis Mac Allister" ~ "Mac Allister",
             name == "Nico Paz"            ~ "Nico Paz",
             TRUE ~ apellido),
           col_txt = ifelse(.lum(POS_COL[as.character(pos_grupo)]) > 150, ER_NEGRO, "white"),
           # tooltip HTML para la versión interactiva
           tip = paste0("<b>", name, "</b><br/>",
                        as.character(pos_grupo), " · ", club, "<br/>",
                        "Valor: ", eur(mv_eur), " · ", caps, " caps"))

  grp_verts <- circleLayoutVertices(
    data.frame(x = grp$x, y = grp$y, radius = grp$radius, id = seq_len(nrow(grp))),
    idcol = "id", npoints = 90) |>
    left_join(mutate(grp, id = row_number()) |> select(id, pos_grupo), by = "id")

  ply_verts <- circleLayoutVertices(
    data.frame(x = players_lay$x, y = players_lay$y,
               radius = players_lay$radius, id = players_lay$id),
    idcol = "id", npoints = 60) |>
    left_join(players_lay |> select(id, pos_grupo, tip), by = "id")

  # Etiquetamos los >= €35 M + Messi + el arquero más valioso (su burbuja es
  # chica y la línea de arqueros quedaba sin ningún nombre).
  top_arq_id <- players_lay |> dplyr::filter(pos_grupo == "Arquero") |>
    dplyr::slice_max(mv_eur, n = 1, with_ties = FALSE) |> dplyr::pull(id)
  lab_players <- players_lay |>
    filter(mv_eur >= 35 | name == "Lionel Messi" | id == top_arq_id) |>
    mutate(txt_sz = scales::rescale(radius, to = c(3.2, 5.6)) *
                    dplyr::case_when(nchar(apellido) > 10 ~ 0.62,
                                     nchar(apellido) > 7  ~ 0.82,
                                     TRUE ~ 1),
           val_lab = paste0("€", mv_eur))

  grp_lab <- grp |>
    mutate(lab = paste0(POS_PL[as.character(pos_grupo)], "\n", eur(v)),
           ytop = y + radius)

  list(grp = grp, players_lay = players_lay, grp_verts = grp_verts,
       ply_verts = ply_verts, lab_players = lab_players, grp_lab = grp_lab,
       total_val = sum(plantel$mv_eur),
       linea_top = as.character(grp$pos_grupo[1]))
}
# Luminancia para decidir color de texto sobre cada relleno
.lum <- function(hex) { rgb <- farver::decode_colour(hex)
  0.299 * rgb[, 1] + 0.587 * rgb[, 2] + 0.114 * rgb[, 3] }

# ==========================================================================
# 2) Constructor del gráfico (estático o interactivo) ------------------------
# ==========================================================================
build_packing <- function(interactive = FALSE, titles = TRUE) {
  d <- .compute_packing()

  # burbujas de jugador: interactivas (tooltip + hover) o estáticas
  capa_jugadores <- if (interactive) {
    ggiraph::geom_polygon_interactive(
      data = d$ply_verts,
      aes(x, y, group = id, fill = pos_grupo, tooltip = tip, data_id = id),
      colour = ER_BLANCO, linewidth = 0.5)
  } else {
    geom_polygon(data = d$ply_verts, aes(x, y, group = id, fill = pos_grupo),
                 colour = ER_BLANCO, linewidth = 0.5)
  }

  ggplot() +
    geom_polygon(data = d$grp_verts, aes(x, y, group = id, fill = pos_grupo),
                 colour = NA, alpha = 0.10) +
    geom_path(data = d$grp_verts, aes(x, y, group = id, colour = pos_grupo),
              linewidth = 0.7, alpha = 0.55) +
    capa_jugadores +
    geom_text(data = d$lab_players,
              aes(x, y + radius * 0.10, label = apellido, size = I(txt_sz),
                  colour = I(col_txt)),
              family = FF, fontface = "bold", lineheight = 0.85) +
    geom_text(data = d$lab_players,
              aes(x, y - radius * 0.36, label = val_lab, colour = I(col_txt)),
              family = FF, size = 2.7, alpha = 0.9) +
    geom_label(data = d$grp_lab,
               aes(x, ytop, label = lab, colour = pos_grupo),
               family = FF, fontface = "bold", size = 4.7, lineheight = 0.95,
               linewidth = 0, label.r = unit(0.12, "lines"),
               fill = ER_BLANCO, alpha = 0.9, vjust = 0.5) +
    scale_fill_manual(values = POS_COL, guide = "none") +
    scale_colour_manual(values = POS_COL, guide = "none") +
    # más aire arriba: las etiquetas de grupo no quedan pegadas al subtítulo
    scale_y_continuous(expand = expansion(mult = c(0.04, 0.16))) +
    coord_fixed(clip = "off") +
    labs(title = if (titles) paste0("Un plantel de ", eur(d$total_val)) else NULL,
         subtitle = if (titles) "Valor de mercado: cada burbuja es un jugador, agrupados por posición" else NULL,
         caption = paste0("El área de cada burbuja es proporcional al valor de mercado.\n",
                          "Los ", tolower(d$linea_top), "s son la línea más cara.\n",
                          "Messi, a los 38, figura con €15 M. · Datos: Transfermarkt · Estación R")) +
    theme_void(base_family = FF) +
    theme(plot.background = element_rect(fill = ER_BLANCO, color = NA),
          plot.title    = element_text(family = FF, face = "bold", size = 27,
                                       color = ER_NEGRO, hjust = 0),
          plot.subtitle = element_text(family = FF, size = 14, color = GRIS_TXT,
                                       hjust = 0, margin = margin(t = 4, b = 6)),
          plot.caption  = element_text(family = FF, size = 11, color = GRIS_TXT,
                                       hjust = 0, lineheight = 1.1, margin = margin(t = 10)),
          plot.margin   = margin(34, 28, 26, 34))
}

# ==========================================================================
# 3) Versión interactiva (girafe) para el HTML -------------------------------
# ==========================================================================
build_packing_girafe <- function(width_svg = 7.4, height_svg = 7.8, titles = FALSE) {
  # showtext convierte el texto del SVG en paths -> infla el widget a decenas de MB.
  # Lo apagamos solo para construir el girafe (el texto sale como <text> liviano,
  # con font-family Ubuntu vía CSS) y lo reactivamos al salir para no afectar el
  # resto de los chunks del render.
  if (ok_font) { showtext::showtext_auto(FALSE); on.exit(showtext::showtext_auto(TRUE), add = TRUE) }
  p <- build_packing(interactive = TRUE, titles = titles)
  # ggiraph por defecto EMBEBE las fuentes Liberation (~8 MB) en el SVG. Usamos un
  # font_set sin dependencias: el SVG referencia las familias por nombre (Ubuntu la
  # provee el sitio vía CSS) y el widget pasa de ~8.8 MB a ~0.3 MB.
  fs <- gdtools::font_set_auto(); fs$dependencies <- list()
  ggiraph::girafe(
    ggobj = p, width_svg = width_svg, height_svg = height_svg,
    font_set = fs,
    options = list(
      ggiraph::opts_hover(css = "fill-opacity:1;stroke:#191919;stroke-width:1.6px;"),
      ggiraph::opts_hover_inv(css = "fill-opacity:0.28;"),
      ggiraph::opts_tooltip(
        css = paste0("background:#191919;color:#fff;padding:7px 10px;",
                     "border-radius:8px;font-family:Ubuntu,sans-serif;font-size:13px;",
                     "box-shadow:0 4px 14px rgba(0,0,0,.25);")),
      ggiraph::opts_toolbar(saveaspng = FALSE),
      ggiraph::opts_sizing(rescale = TRUE)))
}

# ==========================================================================
# 4) Standalone: regenerar la card PNG estática ------------------------------
# ==========================================================================
if (sys.nframe() == 0) {
  if (!dir.exists(file.path(ROOT, "cards"))) dir.create(file.path(ROOT, "cards"))
  p <- build_packing(interactive = FALSE)
  ggsave(file.path(ROOT, "cards", "05_valor_packing.png"), p,
         width = 1080/150, height = 1350/150, dpi = 150,
         device = ragg::agg_png, bg = ER_BLANCO)
  cat("✔ 05_valor_packing.png\n")
}
