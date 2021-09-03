options(tidyverse.quiet = TRUE)
library(tidyverse)
library(vroom)
library(cli)

options(cli.progress_show_after = 0)
options(cli.progress_clear = FALSE)

cli_h1("Aumento de datos")

cli_progress_step("Leyendo los datos de referencia")
eess <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/eess.rds")
vacs <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/vacunas.rds")
centros <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/centro_vacunacion.rds")
grupos <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/grupo_riesgo.rds")
ubigeos <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/ubigeos.rds")
personas <- readRDS("~/devel/local/datos-accessorios-vacunas/datos/personas.rds") %>%
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


cli_progress_step("Leyendo los datos por semana epi")
wk_rds <- fs::dir_ls("tmp", glob = "*.rds")

cli_progress_bar("Procesando por cada semana", total = length(wk_rds))
for (rds_fn in wk_rds) {
  vac_raw <- readRDS(rds_fn) %>%
    select(-grp) %>%
    rename(id_gruporiesgo = id_grupo_riesgo)
  vacunas <- vac_raw %>%
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
  base_fname <- str_replace(rds_fn, "tmp/vacunas_raw_", "datos/vacunas_covid_aumentada_") %>%
    str_remove(fixed(".rds"))
  csvname <- glue::glue("{base_fname}.csv.gz")
  rdsname <- glue::glue("{base_fname}.rds")
  write_csv(vacunas, file = csvname)
  saveRDS(vacunas, file = rdsname)
  cli_progress_update()
}

cli_progress_done()
# cleanup memory
rm(list = ls())
gc()
cli_progress_step("Cargando los archivos parciales para generar el consolidado")
rdslist <- fs::dir_ls("datos/",
                      regexp = "vacunas_covid_aumentada_2021-.+\\.rds")
vacunas <- map_dfr(rdslist, read_rds)
saveRDS(
  vacunas,
  file = "datos/vacunas_covid_aumentada.rds",
  compress = "xz"
)
cli_progress_done()
cli_alert_success("Proceso de datos, finalizado")
