library(tidyverse)
library(vroom)

download.file(
  url = "https://cloud.minsa.gob.pe/s/ZgXoXqK2KLjRLxD/download",
  destfile = "datos/orig/vacunas_covid.csv"
)
R.utils::gzip("datos/orig/vacunas_covid.csv",
              overwrite = TRUE, remove = TRUE)

vacunas <- vroom(
  "datos/orig/vacunas_covid.csv.gz",
  col_types = cols(
    FECHA_CORTE = col_date(format = "%Y%m%d"),
    UUID = col_character(),
    GRUPO_RIESGO = col_character(),
    EDAD = col_double(),
    SEXO = col_character(),
    FECHA_VACUNACION = col_date(format = "%Y%m%d"),
    DOSIS = col_double(),
    FABRICANTE = col_character(),
    DIRESA = col_character(),
    DEPARTAMENTO = col_character(),
    PROVINCIA = col_character(),
    DISTRITO = col_character()
  )
) %>%
  mutate(
    rango_edad = cut(EDAD,
                     c(seq(0, 80, 20), 130),
                     include.lowest = TRUE,
                     right = FALSE,
                     labels = c(
                       "0-19",
                       "20-39",
                       "40-59",
                       "60-79",
                       "80+"
                     ),
                     ordered_result = TRUE
                 ),
    rango_edad = fct_explicit_na(rango_edad, "Desconocido"),
    rango_edad2 = cut(EDAD,
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
                      ),
                      ordered_result = TRUE
    ),
    rango_edad2 = fct_explicit_na(rango_edad2, "Desconocido"),
    SEXO = replace_na(SEXO, "No registrado"),
    epi_week = lubridate::epiweek(FECHA_VACUNACION),
    epi_year = lubridate::epiyear(FECHA_VACUNACION)
  ) %>%
  janitor::clean_names()

saveRDS(
  vacunas,
  file = "datos/vacunas_covid_aumentada.rds"
)

write_csv(
  vacunas,
  file = "datos/vacunas_covid_aumentada.csv.gz"
)

# Resumen -----------------------------------------------------------------

vac_resumen <- vacunas %>%
  select(fecha_corte, fecha_vacunacion,
         uuid, fabricante, dosis) %>%
  distinct() %>%
  group_by(fecha_corte,
           fecha_vacunacion,
           fabricante,
           dosis) %>%
  tally(name = "n_reg") %>%
  # summarise(
  #   n_reg = n()
  #   # n_uuid = n_distinct(uuid) # esto es lo mismo que n_reg
  # ) %>%
  ungroup() %>%
  mutate(
    fabricante = factor(fabricante)
  ) %>%
  arrange(fecha_vacunacion)

saveRDS(
  vac_resumen,
  file = "datos/vacunas_covid_resumen.rds"
)

write_csv(
  vac_resumen,
  file = "datos/vacunas_covid_resumen.csv"
)

