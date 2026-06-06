# ==========================================================================
# 10_cancha.R — Cancha de fondo con fotos del plantel Argentina
# Genera 5 imágenes: arq / def / mid / fwd / ct (cuerpo técnico)
# ==========================================================================
ROOT <- if (file.exists("data/plantel_argentina.csv")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"

suppressMessages({ library(magick); library(dplyr) })
source(file.path(ROOT, "R/_caras.R"))
if (!exists("plantel")) source(file.path(ROOT, "R/00_prep.R"))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
surname_short <- function(nm) {
  dplyr::case_when(
    nm == "Emiliano Martínez"   ~ "E. Martínez",
    nm == "Lisandro Martínez"   ~ "L. Martínez",
    nm == "Lautaro Martínez"    ~ "Lautaro",
    nm == "Lionel Messi"        ~ "Messi",
    nm == "Nico Paz"            ~ "Nico Paz",
    nm == "José Manuel López"   ~ "J.M. López",
    nm == "Alexis Mac Allister" ~ "Mac Allister",
    nm == "Rodrigo De Paul"     ~ "De Paul",
    nm == "Giovani Lo Celso"    ~ "Lo Celso",
    nm == "Giuliano Simeone"    ~ "Simeone",
    nm == "Valentín Barco"      ~ "Barco",
    TRUE ~ sub("^.*\\s(\\S+)$", "\\1", nm)
  )
}

draw_pitch <- function(canvas, W, H, mx, my) {
  canvas <- image_draw(canvas)
  lw <- 2.2
  rect(mx, my, W - mx, H - my, border = "white", lwd = lw + 0.3, col = NA)
  segments(mx, H/2, W - mx, H/2, col = "white", lwd = lw)
  r_cc <- (H - 2*my) * 0.09
  symbols(W/2, H/2, circles = r_cc, inches = FALSE,
          add = TRUE, fg = "white", bg = NA, lwd = lw)
  symbols(W/2, H/2, circles = 5, inches = FALSE,
          add = TRUE, fg = NA, bg = "white")
  pa_w <- (W - 2*mx) * 0.52; pa_d <- (H - 2*my) * 0.13
  ga_w <- (W - 2*mx) * 0.24; ga_d <- (H - 2*my) * 0.045
  # Área superior (delanteros)
  rect(W/2 - pa_w/2, H - my - pa_d, W/2 + pa_w/2, H - my, border="white", lwd=lw, col=NA)
  rect(W/2 - ga_w/2, H - my - ga_d, W/2 + ga_w/2, H - my, border="white", lwd=lw, col=NA)
  # Área inferior (arqueros)
  rect(W/2 - pa_w/2, my, W/2 + pa_w/2, my + pa_d, border="white", lwd=lw, col=NA)
  rect(W/2 - ga_w/2, my, W/2 + ga_w/2, my + ga_d, border="white", lwd=lw, col=NA)
  pspot <- pa_d * 0.70
  symbols(W/2, H - my - pspot, circles = 4, inches = FALSE, add=TRUE, fg=NA, bg="white")
  symbols(W/2, my + pspot,     circles = 4, inches = FALSE, add=TRUE, fg=NA, bg="white")
  dev.off()
  canvas
}

composite_player <- function(canvas, circle_file, cx, py, PR, label = NULL,
                              highlight = TRUE, ER_AMARILLO = "#EAFF38",
                              NM_SZ = 11, W = 960, mx = 55) {
  circle <- image_read(circle_file)
  if (highlight) {
    ring_r <- PR + 4
    ring <- image_blank(ring_r*2, ring_r*2, color = "none")
    ring <- image_draw(ring)
    symbols(ring_r, ring_r, circles = ring_r - 1, inches = FALSE,
            add = TRUE, fg = NA, bg = ER_AMARILLO)
    dev.off()
    canvas <- image_composite(canvas, ring,
                               offset = paste0("+", cx - ring_r, "+", py - ring_r))
  }
  canvas <- image_composite(canvas, circle,
                             offset = paste0("+", cx - PR, "+", py - PR))
  if (!is.null(label) && highlight) {
    nx <- max(mx, min(W - round(nchar(label)*6) - mx,
                      round(cx - nchar(label)*3.0)))
    canvas <- image_annotate(canvas, label,
                              gravity  = "NorthWest",
                              location = paste0("+", nx, "+", py + PR + 5),
                              size = NM_SZ, font = "Ubuntu", color = "white", weight = 700)
  }
  canvas
}

# ---------------------------------------------------------------------------
# build_cancha: genera una imagen del campo resaltando una línea
#   highlight: "arq" | "def" | "mid" | "fwd"
# ---------------------------------------------------------------------------
build_cancha <- function(highlight) {
  W <- 960; H <- 1230; mx <- 55; my <- 65
  PR_HI <- 38; PR_LO <- 24
  ER_AMARILLO <- "#EAFF38"; GRASS <- "#1a5c1a"; STRIPE <- "#1e6820"

  hi_grupos <- switch(highlight,
    "arq" = "Arquero",
    "def" = "Defensor",
    "mid" = "Mediocampista",
    "fwd" = "Delantero"
  )

  imgs <- readRDS(file.path(ROOT, "data/img_urls.rds"))
  df <- left_join(plantel, imgs[, c("name","slug","foto_file")], by = "name") |>
    mutate(
      foto_abs      = file.path(ROOT, foto_file),
      is_hi         = pos_grupo %in% hi_grupos,
      pr            = ifelse(is_hi, PR_HI, PR_LO),
      circle_hi     = file.path(ROOT, "assets/caras",
                                paste0(slug, sprintf("_c%d.png", PR_HI*2))),
      circle_lo     = file.path(ROOT, "assets/caras",
                                paste0(slug, sprintf("_c%d_gray.png", PR_LO*2)))
    )

  for (i in seq_len(nrow(df))) {
    make_circle(df$foto_abs[i], df$circle_hi[i], size = PR_HI * 2)
    make_circle(df$foto_abs[i], df$circle_lo[i], size = PR_LO * 2, gray = TRUE)
  }

  ord_def <- c("Left-Back", "Centre-Back", "Right-Back")
  ord_mid <- c("Defensive Midfield", "Central Midfield", "Attacking Midfield")
  ord_fwd <- c("Left Winger", "Centre-Forward", "Right Winger")

  mk_group <- function(grupo, orden)
    filter(df, pos_grupo == grupo) |>
      mutate(pos_ord = match(pos, orden)) |> arrange(pos_ord, desc(caps))

  gk_df  <- filter(df, pos_grupo == "Arquero")      |> arrange(desc(caps))
  def_df <- mk_group("Defensor",      ord_def)
  mid_df <- mk_group("Mediocampista", ord_mid)
  fwd_df <- mk_group("Delantero",     ord_fwd)

  # Posición vertical (pixel y desde arriba):
  # DEF ahora en 0.72 del campo = más cerca del área propia
  rows <- list(
    list(grp = fwd_df, py = my + 100,                       label = "DELANTEROS"),
    list(grp = mid_df, py = my + round((H-2*my)*0.38),      label = "MEDIOCAMPISTAS"),
    list(grp = def_df, py = my + round((H-2*my)*0.72),      label = "DEFENSORES"),
    list(grp = gk_df,  py = H  - my - 90,                   label = "ARQUEROS")
  )

  canvas <- image_blank(W, H, color = GRASS)
  stripe_w <- round((W - 2*mx) / 7)
  for (s in seq(0, 6, by = 2)) {
    x1 <- mx + s * stripe_w; x2 <- min(x1 + stripe_w, W - mx)
    if (x2 > x1) canvas <- image_composite(canvas,
      image_blank(x2-x1, H-2*my, color=STRIPE),
      offset = paste0("+", x1, "+", my))
  }
  canvas <- draw_pitch(canvas, W, H, mx, my)

  for (row in rows) {
    grp_df <- row$grp; n <- nrow(grp_df); py <- row$py
    span <- W - 2*mx
    xs <- if (n==1) W/2 else
      round(seq(mx + span/(n+1), W - mx - span/(n+1), length.out = n))

    row_is_hi <- any(grp_df$is_hi)
    lbl_col <- if (row_is_hi) ER_AMARILLO else "#3d7a3d"
    lbl_y   <- py - PR_HI - 24
    canvas  <- image_annotate(canvas, row$label,
      gravity="NorthWest",
      location=paste0("+", round(W/2 - nchar(row$label)*3.8), "+", lbl_y),
      size=13, font="Ubuntu", color=lbl_col, weight=700)

    for (i in seq_len(n)) {
      is_hi  <- grp_df$is_hi[i]
      circle <- if (is_hi) grp_df$circle_hi[i] else grp_df$circle_lo[i]
      pr     <- if (is_hi) PR_HI else PR_LO
      label  <- if (is_hi) surname_short(grp_df$name[i]) else NULL
      canvas <- composite_player(canvas, circle, xs[i], py, pr,
                                  label=label, highlight=is_hi,
                                  ER_AMARILLO=ER_AMARILLO, W=W, mx=mx)
    }
  }

  canvas <- image_annotate(canvas,
    "Datos e imágenes: Transfermarkt · Estación R",
    gravity="South", location="+0+8",
    size=10, font="Ubuntu", color="#9ec89e", weight=400)

  out <- file.path(ROOT, sprintf("cards/10_cancha_%s.png", highlight))
  image_write(canvas, out); message("✅ ", out); invisible(out)
}

# ---------------------------------------------------------------------------
# build_cancha_ct: imagen del cuerpo técnico
# ---------------------------------------------------------------------------
build_cancha_ct <- function() {
  W <- 960; H <- 1230; mx <- 55; my <- 65
  PR <- 42; ER_AMARILLO <- "#EAFF38"; GRASS <- "#1a5c1a"; STRIPE <- "#1e6820"

  ct <- tibble::tribble(
    ~name,            ~slug,            ~rol,
    "Lionel Scaloni", "lionel_scaloni", "DT",
    "Pablo Aimar",    "pablo_aimar",    "Ayudante",
    "Walter Samuel",  "walter_samuel",  "Ayudante",
    "Roberto Ayala",  "roberto_ayala",  "Ayudante",
    "Martín Tocalli", "martin_tocalli", "Ent. Arqueros"
  ) |> mutate(
    foto_abs   = file.path(ROOT, "assets/fotos_ct", paste0(slug, ".jpg")),
    circle_abs = file.path(ROOT, "assets/caras",    paste0(slug, sprintf("_ct%d.png", PR*2)))
  )

  for (i in seq_len(nrow(ct)))
    make_circle(ct$foto_abs[i], ct$circle_abs[i], size = PR * 2)

  canvas <- image_blank(W, H, color = GRASS)
  stripe_w <- round((W - 2*mx) / 7)
  for (s in seq(0, 6, by = 2)) {
    x1 <- mx + s * stripe_w; x2 <- min(x1 + stripe_w, W - mx)
    if (x2 > x1) canvas <- image_composite(canvas,
      image_blank(x2-x1, H-2*my, color=STRIPE), offset=paste0("+",x1,"+",my))
  }
  canvas <- draw_pitch(canvas, W, H, mx, my)

  n  <- nrow(ct)
  py <- round(H / 2)   # centro del campo
  span <- W - 2*mx
  xs <- round(seq(mx + span/(n+1), W - mx - span/(n+1), length.out = n))

  # Etiqueta de la línea
  canvas <- image_annotate(canvas, "CUERPO TÉCNICO",
    gravity="NorthWest",
    location=paste0("+", round(W/2 - 7*3.8*2), "+", py - PR - 28),
    size=14, font="Ubuntu", color=ER_AMARILLO, weight=700)

  for (i in seq_len(n)) {
    ring_r <- PR + 5
    ring <- image_blank(ring_r*2, ring_r*2, color="none")
    ring <- image_draw(ring)
    symbols(ring_r, ring_r, circles=ring_r-1, inches=FALSE, add=TRUE, fg=NA, bg=ER_AMARILLO)
    dev.off()
    canvas <- image_composite(canvas, ring,
      offset=paste0("+", xs[i]-ring_r, "+", py-ring_r))
    canvas <- image_composite(canvas, image_read(ct$circle_abs[i]),
      offset=paste0("+", xs[i]-PR, "+", py-PR))

    # Nombre
    nm  <- ct$name[i]
    nx  <- max(mx, min(W - round(nchar(nm)*6) - mx, round(xs[i] - nchar(nm)*3.0)))
    canvas <- image_annotate(canvas, nm, gravity="NorthWest",
      location=paste0("+", nx, "+", py+PR+5),
      size=11, font="Ubuntu", color="white", weight=700)

    # Rol
    rol <- ct$rol[i]
    rx  <- max(mx, min(W - round(nchar(rol)*5) - mx, round(xs[i] - nchar(rol)*2.5)))
    canvas <- image_annotate(canvas, rol, gravity="NorthWest",
      location=paste0("+", rx, "+", py+PR+20),
      size=10, font="Ubuntu", color=ER_AMARILLO, weight=400)
  }

  canvas <- image_annotate(canvas,
    "Datos e imágenes: Transfermarkt · Estación R",
    gravity="South", location="+0+8",
    size=10, font="Ubuntu", color="#9ec89e", weight=400)

  out <- file.path(ROOT, "cards/10_cancha_ct.png")
  image_write(canvas, out); message("✅ ", out); invisible(out)
}

# ---------------------------------------------------------------------------
if (sys.nframe() == 0) {
  build_cancha("arq")
  build_cancha("def")
  build_cancha("mid")
  build_cancha("fwd")
  build_cancha_ct()
  message("✅ Las 5 imágenes de cancha generadas.")
}
