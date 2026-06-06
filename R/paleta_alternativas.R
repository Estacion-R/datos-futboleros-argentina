# ==========================================================================
# 06_paleta_alternativas.R — Lámina comparativa de alternativas de paleta
# ==========================================================================
ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"
source(file.path(ROOT, "R/paleta_estacion_r.R"))   # trae ER_SEQ, ER_DIV (opción A)
suppressMessages({ library(ggplot2); library(grDevices); library(ragg) })
ok <- tryCatch({ library(showtext); sysfonts::font_add_google("Ubuntu","ubuntu")
  showtext_auto(); showtext_opts(dpi = 150); TRUE }, error = function(e) FALSE)
FF <- if (ok) "ubuntu" else "sans"; NEG <- "#191919"; GR <- "#6F6F6F"
lab <- function(cols, n = 9) colorRampPalette(cols, space = "Lab")(n)

# Opción A (la propuesta original)
A_seq <- lab(ER_SEQ); A_div <- lab(ER_DIV)
# Opción B — bitono de marca (azul + amarillo)
B_seq <- lab(c("#0E1A52","#405BFF","#1FA8B8","#A8E05A","#EAFF38"))
B_div <- lab(c("#1B2E9E","#5E78FF","#C9D2FF","#F2F2EF","#E8EE9E","#C9D400","#7E8400"))
# Opción C — editorial sobria (desaturada)
C_seq <- lab(c("#ECEEF2","#7C8DB0","#2E4372"))
C_div <- lab(c("#34507A","#7C92B4","#CFD6DF","#EFEDEA","#E2C6A3","#C08A55","#7A4E24"))

strip <- function(cols, y, x0 = 0.30, x1 = 1, h = 0.30) {
  n <- length(cols)
  data.frame(xmin = x0 + (x1 - x0) * (0:(n-1))/n, xmax = x0 + (x1 - x0) * (1:n)/n,
             ymin = y - h, ymax = y + h, fill = cols)
}
rows <- list(
  list(y = 7.0, p = A_seq, t = "A · un tono"),
  list(y = 6.2, p = B_seq, t = "B · azul a amarillo"),
  list(y = 5.4, p = C_seq, t = "C · sobria"),
  list(y = 3.6, p = A_div, t = "A · azul y ámbar"),
  list(y = 2.8, p = B_div, t = "B · azul y amarillo"),
  list(y = 2.0, p = C_div, t = "C · sobria")
)
tiles <- do.call(rbind, lapply(rows, function(r) strip(r$p, r$y)))
labs_df <- data.frame(x = 0.27, y = sapply(rows, `[[`, "y"),
                      t = sapply(rows, `[[`, "t"))

ggplot() +
  geom_rect(data = tiles, aes(xmin, ymin = ymin, xmax = xmax, ymax = ymax, fill = fill),
            color = "white", linewidth = 0.4) +
  scale_fill_identity() +
  geom_text(data = labs_df, aes(x, y, label = t), family = FF, size = 3.7,
            color = NEG, hjust = 1) +
  annotate("text", x = 0, y = 7.75, label = "SECUENCIAL", family = FF,
           fontface = "bold", size = 5.5, color = NEG, hjust = 0) +
  annotate("text", x = 0, y = 4.35, label = "DIVERGENTE", family = FF,
           fontface = "bold", size = 5.5, color = NEG, hjust = 0) +
  annotate("text", x = 0, y = 1.15, hjust = 0, family = FF, size = 3.5, color = GR,
           label = "A: la propuesta (ancla en azul + ámbar).") +
  annotate("text", x = 0, y = 0.80, hjust = 0, family = FF, size = 3.5, color = GR,
           label = "B: usa los DOS colores de marca (azul + amarillo). Tipo cividis, muy segura para daltonismo.") +
  annotate("text", x = 0, y = 0.45, hjust = 0, family = FF, size = 3.5, color = GR,
           label = "C: sobria/desaturada, look editorial. La cualitativa puede ser la misma en las tres.") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0.3, 8.0), clip = "off") +
  labs(title = "Alternativas de paleta · Estación R",
       subtitle = "Tres direcciones para secuencial y divergente (mismos criterios: Lab + daltonismo)") +
  theme_void(base_family = FF) +
  theme(plot.title = element_text(face = "bold", size = 18, color = NEG),
        plot.subtitle = element_text(size = 11, color = GR, margin = margin(t = 3, b = 12)),
        plot.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(22, 26, 16, 26)) -> g
ggsave(file.path(ROOT, "paleta_alternativas.png"), g, width = 1080/150, height = 1180/150,
       dpi = 150, device = ragg::agg_png, bg = "white")
cat("✔ paleta_alternativas.png\n")
