# ==========================================================================
# 00_scrape.R — Baja el plantel actual de Argentina desde Transfermarkt y
# genera data/plantel_argentina.csv con el esquema que espera 00_prep.R:
#   shirt, name, pos, dob, age, club, mv, caps, goals_nt, pob
# Usa rvest + httr con User-Agent realista, sleep entre requests (polite).
# Reusable: cambiar SQUAD_URL si más adelante mira otro equipo / ventana.
# ==========================================================================
suppressMessages({
  library(rvest); library(httr); library(dplyr); library(stringr);
  library(purrr); library(readr); library(tibble)
})

ROOT <- if (file.exists("R/00_prep.R")) "." else
  "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"

SQUAD_URL <- "https://www.transfermarkt.com/argentinien/startseite/verein/3437"
TM_BASE   <- "https://www.transfermarkt.com"
UA <- paste0("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ",
             "(KHTML, like Gecko) Chrome/126.0 Safari/537.36")
SLEEP <- 1.2  # segundos entre requests, para no martillar TM

fetch_html <- function(url) {
  res <- httr::GET(url, httr::user_agent(UA))
  if (httr::status_code(res) != 200)
    stop("HTTP ", httr::status_code(res), " en ", url)
  read_html(httr::content(res, as = "text", encoding = "UTF-8"))
}

# --- 1) Tabla del plantel --------------------------------------------------
parse_squad_row <- function(tr) {
  shirt   <- suppressWarnings(as.integer(html_text(html_element(tr, ".rueckennummer"), trim = TRUE)))
  name_a  <- html_element(tr, "td.hauptlink a")
  name    <- str_squish(html_text(name_a))
  href    <- html_attr(name_a, "href")
  inline  <- html_elements(tr, "table.inline-table td")
  pos     <- str_squish(html_text(inline[length(inline)]))
  tds     <- html_elements(tr, "td"); txt <- map_chr(tds, ~ str_squish(html_text(.x)))
  m       <- str_match(txt[which(str_detect(txt, "^\\d{2}/\\d{2}/\\d{4}\\s*\\(\\d+\\)$"))[1]],
                       "^(\\d{2})/(\\d{2})/(\\d{4})\\s*\\((\\d+)\\)$")
  dob     <- paste(m[1, 4], m[1, 3], m[1, 2], sep = "-")
  age     <- as.integer(m[1, 5])
  clubs   <- html_attr(html_elements(tr, "a[href*='/verein/']"), "title")
  clubs   <- clubs[!is.na(clubs) & !clubs %in% c("", "Argentina", "Argentina U23", "Argentina U20")]
  club    <- clubs[1]
  mv_txt  <- txt[str_detect(txt, "^€[\\d.,]+(m|k|Th\\.)?$")]
  mv      <- if (length(mv_txt) > 0) mv_txt[1] else NA_character_
  tibble(shirt, name, pos, dob, age, club, mv,
         profile_url = paste0(TM_BASE, href))
}

# --- 2) Perfil del jugador: pob, caps con la Selección, goles_nt ----------
parse_profile <- function(url) {
  h <- fetch_html(url)
  # "Place of birth" -> el siguiente span con texto
  labels <- html_elements(h, "span.info-table__content--regular")
  values <- html_elements(h, "span.info-table__content--bold")
  pob <- NA_character_
  if (length(labels) > 0 && length(values) > 0) {
    idx <- which(str_detect(html_text(labels, trim = TRUE),
                            regex("Place of birth|Lugar de nacimiento", ignore_case = TRUE)))[1]
    if (!is.na(idx)) pob <- str_squish(html_text(values[idx]))
  }
  # "Caps/Goals: 198 / 116" en <li class="data-header__label"> con dos <a>
  caps <- NA_integer_; goals <- NA_integer_
  lis  <- html_elements(h, "li.data-header__label")
  idx  <- which(str_detect(str_squish(html_text(lis)), "^Caps/Goals"))[1]
  if (!is.na(idx)) {
    vals <- str_squish(html_text(html_elements(lis[idx], "a.data-header__content")))
    caps  <- suppressWarnings(as.integer(vals[1]))
    goals <- suppressWarnings(as.integer(vals[2]))
  }
  tibble(pob = pob, caps = caps, goals_nt = goals)
}

# --- 3) Pipeline -----------------------------------------------------------
cat("• Bajando squad page...\n")
h_squad <- fetch_html(SQUAD_URL)
rows    <- html_elements(h_squad, "table.items > tbody > tr")
squad   <- map_dfr(rows, parse_squad_row)
cat("  jugadores en la tabla:", nrow(squad), "\n")

cat("• Visitando", nrow(squad), "perfiles (sleep", SLEEP, "s entre cada uno)...\n")
prof <- vector("list", nrow(squad))
for (i in seq_len(nrow(squad))) {
  Sys.sleep(SLEEP)
  prof[[i]] <- tryCatch(parse_profile(squad$profile_url[i]),
                        error = function(e) { cat("   ! error", squad$name[i], ":", e$message, "\n"); tibble(pob=NA, caps=NA_integer_, goals_nt=NA_integer_) })
  cat("  ", i, "/", nrow(squad), squad$name[i],
      "· pob:", prof[[i]]$pob, "· caps:", prof[[i]]$caps, "· goles:", prof[[i]]$goals_nt, "\n")
}
profiles <- bind_rows(prof)

plantel <- bind_cols(squad |> select(-profile_url), profiles) |>
  select(shirt, name, pos, dob, age, club, mv, caps, goals_nt, pob)

cat("\n--- preview ---\n")
print(head(as.data.frame(plantel), 5))
cat("\n• NA por columna:\n"); print(colSums(is.na(plantel)))

out <- file.path(ROOT, "data/plantel_argentina.csv")
backup <- paste0(out, ".bak_", format(Sys.time(), "%Y%m%d_%H%M%S"))
if (file.exists(out)) file.copy(out, backup, overwrite = FALSE)
write_csv(plantel, out, na = "")
cat("\n✔ Guardado", out, "(backup:", backup, ")\n")
cat("✔ Total jugadores:", nrow(plantel), "\n")

# --- 4) Imágenes: portraits + escudos (cache en assets/) ------------------
slugify <- function(s) {
  s <- iconv(s, to = "ASCII//TRANSLIT")
  s <- str_replace_all(str_to_lower(s), "[^a-z]+", "_")
  str_replace_all(s, "^_|_$", "")
}

cat("• Extrayendo URLs de portrait + escudo de la squad page...\n")
img_data <- map_dfr(rows, function(tr) {
  name_a   <- html_element(tr, "td.hauptlink a")
  name     <- str_squish(html_text(name_a))
  portrait <- html_attr(html_element(tr, "img.bilderrahmen-fixed"), "data-src")
  club_a   <- html_element(tr, "a[href*='/verein/']")
  club_id  <- str_match(html_attr(club_a, "href"), "/verein/(\\d+)")[1, 2]
  crest    <- paste0("https://tmssl.akamaized.net/images/wappen/medium/", club_id, ".png")
  tibble(name, foto_url = portrait, escudo_url = crest)
}) |>
  mutate(slug = vapply(name, slugify, character(1)),
         foto_file   = file.path("assets/fotos",   paste0(slug, ".jpg")),
         escudo_file = file.path("assets/escudos", paste0(slug, ".png")))

dir.create(file.path(ROOT, "assets/fotos"),   showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(ROOT, "assets/escudos"), showWarnings = FALSE, recursive = TRUE)

# Invalidar caché de caras circulares (las regenera 07_goleadores / 01_cards al correr)
unlink(file.path(ROOT, "assets/caras"), recursive = TRUE)

dl <- function(url, dest) {
  Sys.sleep(0.4)
  res <- tryCatch(httr::GET(url, httr::user_agent(UA), httr::write_disk(dest, overwrite = TRUE)),
                  error = function(e) NULL)
  !is.null(res) && httr::status_code(res) == 200
}

n_foto <- 0; n_esc <- 0
for (i in seq_len(nrow(img_data))) {
  if (dl(img_data$foto_url[i],   file.path(ROOT, img_data$foto_file[i])))   n_foto <- n_foto + 1
  if (dl(img_data$escudo_url[i], file.path(ROOT, img_data$escudo_file[i]))) n_esc  <- n_esc  + 1
}
cat("  fotos descargadas:", n_foto, "/", nrow(img_data),
    "· escudos:", n_esc, "/", nrow(img_data), "\n")

saveRDS(img_data |> select(name, foto_url, escudo_url, slug, foto_file, escudo_file),
        file.path(ROOT, "data/img_urls.rds"))
cat("✔ data/img_urls.rds reescrito (", nrow(img_data), "jugadores)\n")
