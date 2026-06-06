# ==========================================================================
# _caras.R — Helper compartido: recorta una foto a círculo (cache en assets/caras).
# Lo usan R/07_goleadores.R y R/01_cards.R (card de edades, caps).
# ==========================================================================
suppressMessages(library(magick))

make_circle <- function(infile, outfile, size = 240, gray = FALSE) {
  if (file.exists(outfile)) return(outfile)
  dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
  im  <- image_read(infile)
  inf <- image_info(im); s <- min(inf$width, inf$height)
  im  <- image_crop(im, geometry_area(s, s, (inf$width - s) %/% 2, 0))  # cuadrado desde arriba (cabeza)
  im  <- image_resize(im, paste0(size, "x", size, "!"))
  if (gray) im <- image_modulate(im, brightness = 108, saturation = 0)  # desaturado
  mask <- image_draw(image_blank(size, size, color = "none"))
  symbols(size/2, size/2, circles = size/2 - 2, inches = FALSE, add = TRUE, bg = "black", fg = NA)
  dev.off()
  image_write(image_composite(im, mask, operator = "CopyOpacity"), outfile, format = "png")
  outfile
}

# Variante en gris (para "no destacados"): cache aparte con sufijo _gray.
make_circle_gray <- function(infile, outfile, size = 240)
  make_circle(infile, outfile, size = size, gray = TRUE)
