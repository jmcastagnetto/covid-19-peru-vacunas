options(tidyverse.quiet = TRUE)
library(tidyverse)
library(vroom)
library(cli)

options(cli.progress_show_after = 0)
options(cli.progress_clear = FALSE)

cli_h1("Proceso inicial de datos")

# separar datos cada millón de registros,
# para evitar problemas de tamaño con github
# y el uso de mucha memoria
n_limit <- 1e6  # de millón en millón
cli_alert("Estimando número de bloques")

ids <- vroom(
  "datos/orig/vacunas_covid.csv",
  col_types = cols(
    .default = col_skip(),
    id_persona = col_integer()
  )
)
n_rows <- nrow(ids)
unique_ids <- unique(ids$id_persona)
rm("ids")
gc()
seq_nums <- 1:ceiling(n_rows/n_limit)
cli_alert("Separando por cada millón de registros en {max(seq_nums)} bloques")

eess <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/eess.rds")
vacs <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/vacunas.rds")
centros <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/centro_vacunacion.rds")
grupos <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/grupo_riesgo.rds")
ubigeos <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/ubigeos.rds")
personas <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/personas.rds") %>%
  filter(id_persona %in% unique_ids) %>%
  mutate(
    edad = as.integer(format(Sys.Date(), "%Y")) - anho_nac
  ) %>%
  select(
    id_persona,
    edad,
    sexo,
    ubigeo_persona = ubigeo
  ) %>%
  mutate(
    sexo = factor(sexo),
    ubigeo_persona = factor(ubigeo_persona)
  )


cli_progress_bar("Procesando por bloques", total = max(seq_nums))
for (part in seq_nums) {
  skip <- (part - 1) * n_limit + 1
  orig <- vroom(
    "datos/orig/vacunas_covid.csv",
    col_names = c(
      "id_persona",
      "id_vacunados_covid19",
      "fecha_vacunacion",
      "id_eess",
      "id_centro_vacunacion",
      "id_vacuna",
      "id_grupo_riesgo",
      "dosis"
    ),
    col_types = cols(
      .default = col_integer(),
      fecha_vacunacion = col_date(format = "%d/%m/%Y")
    ),
    skip = skip,
    n_max = n_limit
  ) %>%
    rename(id_gruporiesgo = id_grupo_riesgo)
  vacunas <- orig %>%
    left_join(personas, by = "id_persona") %>%
    left_join(grupos %>%
                rename(grupo_riesgo = desc_gruporiesgo),
              by = "id_gruporiesgo")  %>%
    left_join(vacs %>% rename(fabricante_pais = pais), by = "id_vacuna") %>%
    left_join(
      eess %>%
        select(
          id_eess,
          eess = nombre,
          eess_diresa = diresa,
          eess_categoria = categoria,
          eess_ubigeo = ubigeo
        ),
      by = "id_eess"
    ) %>%
    left_join(
      centros %>%
        select(
          id_centro_vacunacion,
          centro_vacunacion = nombre,
          centro_vacunacion_entidad_admin = entidad_administra,
          centro_vacunacion_ubigeo = ubigeo
        ),
      by = "id_centro_vacunacion"
    ) %>%
    mutate(
      rango_edad = cut(
        edad,
        c(seq(0, 80, 20), 130),
        include.lowest = TRUE,
        right = FALSE,
        labels = c("0-19",
                   "20-39",
                   "40-59",
                   "60-79",
                   "80+")
      ),
      rango_edad_deciles = cut(
        edad,
        c(seq(0, 80, 10), 130),
        include.lowest = TRUE,
        right = FALSE,
        labels = c(
          "0-9",
          "10-19",
          "20-29",
          "30-39",
          "40-49",
          "50-59",
          "60-69",
          "70-79",
          "80+"
        )
      ),
      rango_edad_quintiles = cut(
        edad,
        c(seq(0, 80, 5), 130),
        include.lowest = TRUE,
        right = FALSE,
        labels = c(
          "0-4",
          "5-9",
          "10-14",
          "15-19",
          "20-24",
          "25-29",
          "30-34",
          "35-39",
          "40-44",
          "45-49",
          "50-54",
          "55-59",
          "60-64",
          "65-69",
          "70-74",
          "75-79",
          "80+"
        )
      ),
      rango_edad_owid = cut(
        edad,
        c(0, 18, 25, 50, 60, 70, 80, 130),
        include.lowest = TRUE,
        right = FALSE,
        labels = c("0-17",
                   "18-24",
                   "25-49",
                   "50-59",
                   "60-69",
                   "70-79",
                   "80+")
      ),
      rango_edad = fct_explicit_na(rango_edad, "Desconocido"),
      rango_edad_deciles = fct_explicit_na(rango_edad_deciles, "Desconocido"),
      rango_edad_quintiles = fct_explicit_na(rango_edad_quintiles, "Desconocido"),
      rango_edad_owid = fct_explicit_na(rango_edad_owid, "(Missing)"),
      rango_edad = as.character(rango_edad),
      rango_edad_deciles = as.character(rango_edad_deciles),
      rango_edad_quintiles = as.character(rango_edad_quintiles),
      rango_edad_owid = as.character(rango_edad_owid),
      epi_week = lubridate::epiweek(fecha_vacunacion),
      epi_year = lubridate::epiyear(fecha_vacunacion)
    ) %>%
    relocate(id_vacunados_covid19, .before = 1) %>%
    relocate(id_vacuna, .before = fabricante) %>%
    relocate(id_gruporiesgo, .before = grupo_riesgo) %>%
    relocate(id_eess, .before = eess) %>%
    relocate(id_centro_vacunacion, .before = centro_vacunacion)
  # origname <- glue::glue("datos/orig/vacunas_covid_{sprintf('%03d', part)}.csv.gz")
  csvname <- glue::glue("datos/vacunas_covid_aumentada_{sprintf('%03d', part)}.csv.gz")
  rdsname <-
    glue::glue("datos/vacunas_covid_aumentada_{sprintf('%03d', part)}.rds")
  # write_csv(orig, file = origname)
  write_csv(vacunas, file = csvname)
  saveRDS(vacunas, file = rdsname)
  cli_progress_update()
}

cli_progress_done()
# cleanup memory
rm(list = ls())
gc()
cli_alert("Cargando los archivos parciales para generar el consolidado")
rdslist <- fs::dir_ls("datos/",
                      regexp = "vacunas_covid_aumentada_[0-9]{3}\\.rds")
vacunas <- map_dfr(rdslist, read_rds)
saveRDS(
  vacunas,
  file = "datos/vacunas_covid_aumentada.rds",
  compress = "xz"
)

cli_alert_success("Proceso de datos, finalizado")
