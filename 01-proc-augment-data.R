library(tidyverse, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)
library(cli)

vac_raw <- open_dataset("tmp/arrow_data/")

cli_progress_step("Leyendo los datos de referencia")
eess <- read_parquet("~/devel/local/datos-accessorios-vacunas/datos/eess.parquet")
vacs <- read_parquet("~/devel/local/datos-accessorios-vacunas/datos/vacunas.parquet")
centros <- read_parquet("~/devel/local/datos-accessorios-vacunas/datos/centro_vacunacion.parquet")
grupos <- read_parquet("~/devel/local/datos-accessorios-vacunas/datos/grupo_riesgo.parquet")
ubigeos <- read_parquet("~/devel/local/datos-accessorios-vacunas/datos/ubigeos.parquet")
personas <- read_parquet(
  "~/devel/local/datos-accessorios-vacunas/datos/personas.parquet",
  col_select = c("id_persona", "sexo", "ubigeo")
) %>%
  rename(ubigeo_persona = ubigeo) %>%
  mutate(
    sexo = factor(sexo),
    ubigeo_persona = factor(ubigeo_persona)
  )

primer_lote_sinopharm <- as.Date("2021-02-07")
primer_lote_pfizer <- as.Date("2021-03-03")
primer_lote_astrazeneca <- as.Date("2021-04-18")

cli_progress_step("Combinando los datos de vacunación con los de referencia")
vacunas <- vac_raw %>%
  collect() %>%
  rename(id_gruporiesgo = id_grupo_riesgo) %>%
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
    # imputar UBIGEO para los casos genéricos
    centro_vacunacion_ubigeo = if_else(
      centro_vacunacion == "MISMO ESTABLECIMIENTO DE SALUD",
      eess_ubigeo,
      centro_vacunacion_ubigeo
    ),
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
    rango_edad_quintiles = fct_explicit_na(rango_edad_quintiles,
                                           "Desconocido"),
    rango_edad_owid = fct_explicit_na(rango_edad_owid, "(Missing)"),
    rango_edad = as.character(rango_edad),
    rango_edad_deciles = as.character(rango_edad_deciles),
    rango_edad_quintiles = as.character(rango_edad_quintiles),
    rango_edad_owid = as.character(rango_edad_owid),
    #epi_week = epiweek(fecha_vacunacion),
    #epi_year = epiyear(fecha_vacunacion),
    flag_vacunacion_general = if_else(
      (fecha_vacunacion > primer_lote_sinopharm &
         fabricante == "SINOPHARM") |
        (fecha_vacunacion > primer_lote_pfizer &
           fabricante == "PFIZER") |
        (fecha_vacunacion > primer_lote_astrazeneca &
           fabricante == "ASTRAZENECA"),
      TRUE,
      FALSE
    )
  ) %>%
  relocate(id_vacunados_covid19, .before = 1) %>%
  relocate(id_vacuna, .before = fabricante) %>%
  relocate(id_gruporiesgo, .before = grupo_riesgo) %>%
  relocate(id_eess, .before = eess) %>%
  relocate(id_centro_vacunacion, .before = centro_vacunacion)

cli_progress_step("Guardando datos aumentados, por epi_year y epi_week como parquet files")
write_dataset(
  vacunas,
  path = "tmp/arrow_augmented_data/",
  partitioning = c("epi_year", "epi_week")
)
cli_alert_success("Proceso de datos, finalizado")