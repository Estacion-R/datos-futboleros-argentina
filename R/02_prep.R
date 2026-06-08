# ==========================================================================
# Datos Futboleros: el plantel de la Selección Argentina
# 00_prep.R — carga, limpieza y agregados. Source-able desde el .qmd
# ==========================================================================
suppressMessages({
  library(dplyr); library(stringr); library(readr); library(sf); library(tidyr)
})

ROOT <- if (file.exists("data/plantel_argentina.csv")) "." else
        "/home/pablote/.openclaw/workspace-proyectos/proyectos/datos-futboleros-argentina"

plantel <- read_csv(file.path(ROOT, "data/plantel_argentina.csv"), show_col_types = FALSE) |>
  mutate(
    name = str_squish(name),
    mv_eur = as.numeric(str_remove_all(str_extract(mv, "[0-9.]+"), " ")) *
             ifelse(str_detect(mv, "m"), 1, 0.001),  # millones de €
    pos_grupo = case_when(
      str_detect(pos, "Goalkeeper")        ~ "Arquero",
      # "Midfield" ANTES que "Defen": si no, "Defensive Midfield" (Paredes) cae
      # como Defensor. Un mediocampista defensivo es mediocampista.
      str_detect(pos, "Midfield")          ~ "Mediocampista",
      str_detect(pos, "Back|Defen")        ~ "Defensor",
      str_detect(pos, "Winger|Forward|Striker|Attack") ~ "Delantero",
      TRUE ~ "Otro"
    )
  )

# --- Ciudad de nacimiento -> provincia (asignación manual, verificada) -------
ciudad_prov <- tribble(
  ~pob,                       ~provincia,         ~pais,
  "Mar del Plata",            "Buenos Aires",     "Argentina",
  "La Plata",                 "Buenos Aires",     "Argentina",
  "San Nicolás de los Arroyos","Buenos Aires",    "Argentina",
  "Córdoba",                  "Córdoba",          "Argentina",
  "Concordia",                "Entre Ríos",       "Argentina",
  "Gualeguay",                "Entre Ríos",       "Argentina",   # Lisandro Martínez
  "General Pico",             "La Pampa",         "Argentina",
  "El Talar",                 "Buenos Aires",     "Argentina",
  "Rafael Calzada",           "Buenos Aires",     "Argentina",
  "Villa Mercedes",           "San Luis",         "Argentina",   # Balerdi
  "Villa Fiorito",            "Buenos Aires",     "Argentina",   # Facundo Medina
  "González Catán",           "Buenos Aires",     "Argentina",   # Montiel
  "Bahía Blanca",             "Buenos Aires",     "Argentina",   # Lautaro Martínez
  "Zapala",                   "Neuquén",          "Argentina",
  "Embalse",                  "Córdoba",          "Argentina",
  "San Carlos Centro",        "Santa Fe",         "Argentina",
  "Haedo",                    "Buenos Aires",     "Argentina",
  "San Justo",                "Buenos Aires",     "Argentina",
  "San Martín",               "Buenos Aires",     "Argentina",
  "Santa Rosa",               "La Pampa",         "Argentina",
  "25 de Mayo",               "Buenos Aires",     "Argentina",
  "Famaillá",                 "Tucumán",          "Argentina",
  "Sarandí",                  "Buenos Aires",     "Argentina",
  "Santa Cruz de Tenerife",   NA_character_,      "España",     # Nico Paz
  "Belén de Escobar",         "Buenos Aires",     "Argentina",
  "Ciudadela",                "Buenos Aires",     "Argentina",
  "Azul",                     "Buenos Aires",     "Argentina",
  "Roma",                     NA_character_,      "Italia",     # G. Simeone
  "Rosario",                  "Santa Fe",         "Argentina",
  "Calchín",                  "Córdoba",          "Argentina",
  "San Lorenzo",              "Santa Fe",         "Argentina"
)

plantel <- plantel |> left_join(ciudad_prov, by = "pob")

# --- Club local vs exterior --------------------------------------------------
clubes_ar <- c("CA River Plate", "CA Boca Juniors", "Racing Club",
               "Club Estudiantes de La Plata", "Club Atlético Independiente",
               "San Lorenzo de Almagro", "CA Vélez Sarsfield")
plantel <- plantel |>
  mutate(milita = ifelse(club %in% clubes_ar, "Liga local", "Exterior"))

# --- Club -> liga (fuente única; la usan card 06, la tabla de ligas y el HTML) -
club_liga <- c(
  "Aston Villa" = "Premier League", "Tottenham Hotspur" = "Premier League",
  "AFC Bournemouth" = "Premier League", "Chelsea FC" = "Premier League",
  "Liverpool FC" = "Premier League", "Manchester United" = "Premier League",
  "Atlético de Madrid" = "LaLiga", "Real Madrid" = "LaLiga",
  "Real Betis Balompié" = "LaLiga",
  "Olympique Marseille" = "Ligue 1", "Olympique Lyon" = "Ligue 1",
  "RC Strasbourg Alsace" = "Ligue 1",
  "Como 1907" = "Serie A", "Inter Milan" = "Serie A", "Inter Miami CF" = "MLS",
  "Bayer 04 Leverkusen" = "Bundesliga", "SL Benfica" = "Primeira",
  "Sociedade Esportiva Palmeiras" = "Brasileirão",
  "CA River Plate" = "Liga Argentina", "CA Boca Juniors" = "Liga Argentina",
  "Racing Club" = "Liga Argentina", "Club Estudiantes de La Plata" = "Liga Argentina")
plantel <- plantel |> mutate(liga = unname(club_liga[club]))
if (any(is.na(plantel$liga)))
  warning("Clubes sin liga (caen como NA): ",
          paste(unique(plantel$club[is.na(plantel$liga)]), collapse = ", "))

# Metadatos de cada liga: país (subtítulo) + logo (Transfermarkt, en assets/ligas).
liga_meta <- tibble::tribble(
  ~liga,            ~pais,            ~logo,
  "LaLiga",         "España",         "assets/ligas/laliga.png",
  "Premier League", "Inglaterra",     "assets/ligas/premier.png",
  "Ligue 1",        "Francia",        "assets/ligas/ligue1.png",
  "Serie A",        "Italia",         "assets/ligas/seriea.png",
  "Bundesliga",     "Alemania",       "assets/ligas/bundesliga.png",
  "MLS",            "Estados Unidos", "assets/ligas/mls.png",
  "Primeira",       "Portugal",       "assets/ligas/primeira.png",
  "Brasileirão",    "Brasil",         "assets/ligas/brasileirao.png",
  "Liga Argentina", "Argentina",      "assets/ligas/liga_argentina.png")

# ---------------------------------------------------------------------------
# AGREGADOS / DATOS CLAVE
# ---------------------------------------------------------------------------
.sn_edad <- function(nm) {
  dplyr::case_when(nm == "Nico Paz"    ~ "Nico Paz",
                   nm == "Lionel Messi" ~ "Messi",
                   TRUE ~ sub("^.*\\s", "", nm))
}
dato_edad <- list(
  prom      = round(mean(plantel$age), 1),
  joven     = plantel |> slice_min(age, n = 1, with_ties = FALSE),
  veterano  = plantel |> slice_max(age, n = 1, with_ties = FALSE),
  jovenes   = .sn_edad(plantel$name[plantel$age == min(plantel$age)]),
  veteranos = .sn_edad(plantel$name[plantel$age == max(plantel$age)])
)

por_provincia <- plantel |>
  filter(!is.na(provincia)) |>
  count(provincia, name = "jugadores")

nacidos_exterior <- plantel |> filter(pais != "Argentina")

por_milita <- plantel |> count(milita, name = "n")

top_caps <- plantel |> arrange(desc(caps))

total_caps <- sum(plantel$caps)
total_goles_nt <- sum(plantel$goals_nt)

# Mapa de provincias — fuente: paquete geoAr (incluye Malvinas, sin Antártida).
# Regla del proyecto: mapas de Argentina con geoAr + Malvinas siempre.
geoar_cache <- file.path(ROOT, "data/provincias_geoar.rds")
provincias_sf <- if (file.exists(geoar_cache)) {
  readRDS(geoar_cache)
} else {
  suppressMessages(library(geoAr))
  geoAr::add_geo_codes(geoAr::get_geo("ARGENTINA", level = "provincia")) |>
    st_as_sf() |> st_make_valid() |> rename(nombre = name_iso)
}

mapa_data <- provincias_sf |>
  left_join(por_provincia, by = join_by(nombre == provincia)) |>
  mutate(jugadores = replace_na(jugadores, 0))

invisible(TRUE)
