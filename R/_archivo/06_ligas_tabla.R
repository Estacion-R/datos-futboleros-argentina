# ==========================================================================
# 06_ligas_tabla.R — Tabla de ligas con las CARAS de los jugadores
# (pedido de Pablo: "transformá la de liga en tabla, con las imágenes de los
# jugadores, para saber quiénes y cuántos"). gt source-able desde el .qmd +
# standalone HTML. Una fila por liga: logo+nombre+país · N · caras+apellidos.
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

suppressMessages({
  library(dplyr); library(stringr); library(gt); library(purrr); library(tibble)
})
source(file.path(ROOT, "R/_caras.R"))

# Plan B legal: SIN_FOTOS=1 reemplaza la cara del jugador por un círculo con su
# número de camiseta coloreado por posición (sin fotos de agencia). Se mantiene
# el escudo del club como badge. Default = con caras.
SIN_FOTOS <- Sys.getenv("SIN_FOTOS", "0") == "1"

ER_AZUL <- "#405BFF"; ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7"
ER_BLANCO <- "#FFFFFF"; GRIS_TXT <- "#6F6F6F"
POS_COL <- c(Arquero = "#E6A100", Defensor = "#405BFF",
             Mediocampista = "#2CA6C4", Delantero = "#B3294E")

img_l <- readRDS(file.path(ROOT, "data/img_urls.rds")) |>
  select(name, foto_file, slug, escudo_file)

# Apellido corto. Por defecto deja el apellido (incl. compuestos: Mac Allister,
# Lo Celso, De Paul). Casos especiales: desambiguar los 3 "Martínez" y, cuando
# el nombre es largo, usar iniciales (José Manuel López -> J. M. López).
apellido <- function(x) {
  out <- str_replace(x, "^(\\S)\\S+\\s+(.+)$", "\\2")
  dplyr::case_when(
    x == "Lionel Messi"      ~ "Messi",
    x == "Emiliano Martínez" ~ "Dibu",
    x == "Lautaro Martínez"  ~ "Lautaro",
    x == "Lisandro Martínez" ~ "Lisandro",
    x == "José Manuel López" ~ "J. M. López",
    TRUE ~ out
  )
}

# Caritas circulares (cache compartida en assets/caras) + apellido corto.
# Con SIN_FOTOS no se generan/leen las caras (se usa el número de camiseta).
pf <- plantel |>
  left_join(img_l, by = "name") |>
  mutate(
    cara  = if (SIN_FOTOS) NA_character_ else
            mapply(function(f, s) make_circle(file.path(ROOT, f),
                     file.path(ROOT, "assets/caras", paste0(s, ".png"))), foto_file, slug),
    escudo = file.path(ROOT, escudo_file),
    poscol = unname(POS_COL[pos_grupo]),
    sname = apellido(name))

# Celda "jugador": cara con el escudo del club como badge abajo-derecha +
# apellido debajo, como mini-ficha inline.
ficha <- function(cara, sname, escudo) paste0(
  "<span style='display:inline-block;text-align:center;width:64px;",
  "margin:3px 4px;vertical-align:top;'>",
  "<span style='position:relative;display:inline-block;line-height:0;'>",
  as.character(gt::local_image(cara, height = 46)),
  "<span style='position:absolute;right:-2px;bottom:-2px;background:#fff;",
  "border-radius:50%;padding:1px;box-shadow:0 0 2px rgba(0,0,0,.35);line-height:0;'>",
  as.character(gt::local_image(escudo, height = 17)),
  "</span></span>",
  "<span style='display:block;margin-top:6px;font-size:10px;color:#191919;",
  "line-height:1.05;'>", sname, "</span></span>")

# Variante SIN fotos: círculo con número de camiseta (color por posición) +
# escudo del club como badge + apellido debajo.
ficha_sf <- function(shirt, sname, escudo, poscol) paste0(
  "<span style='display:inline-block;text-align:center;width:64px;",
  "margin:3px 4px;vertical-align:top;'>",
  "<span style='position:relative;display:inline-block;line-height:0;'>",
  "<span style='display:inline-block;width:46px;height:46px;border-radius:50%;",
  "background:", poscol, ";color:#fff;font-weight:700;font-size:18px;",
  "line-height:46px;text-align:center;'>", shirt, "</span>",
  "<span style='position:absolute;right:-2px;bottom:-2px;background:#fff;",
  "border-radius:50%;padding:1px;box-shadow:0 0 2px rgba(0,0,0,.35);line-height:0;'>",
  as.character(gt::local_image(escudo, height = 17)),
  "</span></span>",
  "<span style='display:block;margin-top:6px;font-size:10px;color:#191919;",
  "line-height:1.05;'>", sname, "</span></span>")

ligas_tab <- pf |>
  arrange(liga, desc(caps)) |>
  group_by(liga) |>
  summarise(n = n(),
            Jugadores = paste0(if (SIN_FOTOS) ficha_sf(shirt, sname, escudo, poscol)
                               else ficha(cara, sname, escudo), collapse = ""),
            .groups = "drop") |>
  left_join(liga_meta, by = "liga") |>
  arrange(desc(n), liga) |>
  mutate(Liga = paste0(
    as.character(gt::local_image(file.path(ROOT, logo), height = 30)),
    " &nbsp;<strong style='font-size:16px'>", liga, "</strong>",
    "<br><span style='font-size:11px;color:#6F6F6F;margin-left:38px'>", pais, "</span>")) |>
  select(Liga, n, Jugadores)

# Bajada: la concentración del Atlético dentro de LaLiga (dinámica).
n_atm    <- sum(plantel$club == "Atlético de Madrid")
n_laliga <- sum(plantel$liga == "LaLiga")
nota_atm <- paste0("De los ", n_laliga, " jugadores en LaLiga, ", n_atm,
                   " militan en el Atlético de Madrid.")

build_ligas_tabla <- function(df = ligas_tab) {
  df |>
    gt() |>
    fmt_markdown(columns = c(Liga, Jugadores)) |>
    cols_label(n = md("**Cuántos**"), Liga = md("**Liga**"),
               Jugadores = md("**Quiénes**")) |>
    cols_align("center", columns = n) |>
    cols_align("left", columns = c(Liga, Jugadores)) |>
    tab_header(title = md("**¿En qué ligas juegan?**"),
               subtitle = "Jugadores del plantel por liga: quiénes y cuántos") |>
    tab_source_note(md(paste0("**", nota_atm, "**"))) |>
    tab_source_note(md(if (SIN_FOTOS)
      "*Datos: Transfermarkt · Escudos y logos: clubes y ligas · Estación R*"
      else "*Datos e imágenes: Transfermarkt · Estación R*")) |>
    # Nombre de fuente como string (NO google_font): evita embeber el TTF de
    # Ubuntu por tabla (causa del OOM del render); la página ya la carga del header.
    opt_table_font(font = c("Ubuntu", "sans-serif")) |>
    tab_style(style = cell_text(size = px(30), weight = "bold", color = ER_AZUL),
              locations = cells_body(columns = n)) |>
    tab_options(
      heading.title.font.size = px(26),
      heading.subtitle.font.size = px(14),
      heading.title.font.weight = "bold",
      column_labels.background.color = ER_AZUL,
      column_labels.font.weight = "bold",
      column_labels.text_transform = "uppercase",
      table.font.color = ER_NEGRO,
      heading.background.color = ER_BLANCO,
      row.striping.include_table_body = TRUE,
      row.striping.background_color = ER_GRIS,
      table_body.hlines.color = "#ECECEC",
      data_row.padding = px(10),
      table.border.top.color = ER_AZUL,
      table.border.top.width = px(3),
      table.width = px(820))
}

ligas_tabla_gt <- build_ligas_tabla()

# Standalone sólo al correr con Rscript (no cuando lo sourcea knitr).
if (sys.nframe() == 0) {
  dir.create(file.path(ROOT, "output"), showWarnings = FALSE)
  gtsave(ligas_tabla_gt, file.path(ROOT, "output", "ligas_tabla.html"))
  cat("✔ output/ligas_tabla.html · ligas:", nrow(ligas_tab),
      "· jugadores:", sum(ligas_tab$n), "\n")
}
