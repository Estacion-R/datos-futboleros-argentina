# ==========================================================================
# paleta_estacion_r.R — Paletas de visualización de Estación R
# Tres familias: SECUENCIAL, DIVERGENTE, CUALITATIVA.
# Ancladas en la marca (#405BFF) e interpoladas en espacio Lab.
# CVD-chequeadas con colorblindcheck. Reutilizable en cualquier proyecto.
# ==========================================================================
suppressMessages({ library(ggplot2); library(grDevices); library(scales) })

# --- Colores de marca (referencia) ------------------------------------------
ER_AZUL <- "#405BFF"; ER_AZUL_D <- "#1839F4"; ER_AMARILLO <- "#EAFF38"
ER_NEGRO <- "#191919"; ER_GRIS <- "#F7F7F7"; ER_BLANCO <- "#FFFFFF"

# --- Anclas de cada paleta (DIRECCIÓN B · bitono de marca, elegida 2026-05-26) -
# SECUENCIAL: bitono azul -> amarillo (los dos colores de marca), estilo cividis.
# Low = navy oscuro, High = amarillo. Luminosidad monótona, óptima para CVD.
ER_SEQ <- c("#0E1A52", "#405BFF", "#1FA8B8", "#A8E05A", "#EAFF38")
# DIVERGENTE: azul <-> amarillo (par muy seguro para daltonismo), centro neutro.
ER_DIV <- c("#1B2E9E", "#5E78FF", "#C9D2FF", "#F2F2EF", "#E8EE9E", "#C9D400", "#7E8400")
# CUALITATIVA: 6 tonos distinguibles (CVD min_dist >= 8.5). Arranca en azul marca.
# A partir de 6 categorías la separación cae: agrupar o etiquetar directo.
ER_QUAL <- c("#405BFF", "#E6A100", "#2CA6C4", "#B3294E", "#6A4C93", "#D4499B")

# --- Generadores de paleta --------------------------------------------------
er_pal_seq  <- function(n = 256) colorRampPalette(ER_SEQ, space = "Lab")(n)
er_pal_div  <- function(n = 256) colorRampPalette(ER_DIV, space = "Lab")(n)
er_pal_qual <- function(n = length(ER_QUAL)) {
  if (n > length(ER_QUAL))
    warning("La cualitativa de ER tiene 6 colores CVD-seguros; pediste ", n,
            ". Considerá agrupar categorías.")
  rep(ER_QUAL, length.out = n)[seq_len(n)]
}

# --- Escalas ggplot2 ---------------------------------------------------------
# Secuencial (continua)
scale_fill_er_c  <- function(...) scale_fill_gradientn(colours = er_pal_seq(), ...)
scale_colour_er_c <- function(...) scale_colour_gradientn(colours = er_pal_seq(), ...)

# Divergente (continua, centrada en 'midpoint')
scale_fill_er_div <- function(midpoint = 0, ...)
  scale_fill_gradientn(colours = er_pal_div(),
                       rescaler = function(x, to = c(0, 1), from = range(x, na.rm = TRUE))
                         scales::rescale_mid(x, to, from, mid = midpoint), ...)
scale_colour_er_div <- function(midpoint = 0, ...)
  scale_colour_gradientn(colours = er_pal_div(),
                         rescaler = function(x, to = c(0, 1), from = range(x, na.rm = TRUE))
                           scales::rescale_mid(x, to, from, mid = midpoint), ...)

# Cualitativa (discreta)
scale_fill_er_q   <- function(...) scale_fill_manual(values = ER_QUAL, ...)
scale_colour_er_q <- function(...) scale_colour_manual(values = ER_QUAL, ...)

invisible(TRUE)
