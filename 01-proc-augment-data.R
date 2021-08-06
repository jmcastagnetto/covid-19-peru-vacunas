library(tidyverse)
library(vroom)

message("Proceso inicial de datos, separando por cada millón de registros")

# separar datos cada millón de registros,
# para evitar problemas de tamaño con github
# y el uso de mucha memoria
n_limit <- 1e6  # de millón en millón
tmp <- vroom("datos/orig/vacunas_covid.csv",
             col_types = cols(.default = col_character()))
n_rows <- nrow(tmp)
rm("tmp")
seq_nums <- 1:ceiling(n_rows/n_limit)
for(part in seq_nums) {
  skip <- (part - 1) * n_limit + 1
  print(glue::glue("Parte: {part}, saltando {skip} lineas"))
  orig <- vroom(
    "datos/orig/vacunas_covid.csv",
    col_names = c(
      "FECHA_CORTE",
      "UUID",
      "GRUPO_RIESGO",
      "EDAD",
      "SEXO",
      "FECHA_VACUNACION",
      "DOSIS",
      "FABRICANTE",
      "DIRESA",
      "DEPARTAMENTO",
      "PROVINCIA",
      "DISTRITO"
    ),
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
    ),
    skip = skip,
    n_max = n_limit
  )
  vacunas <- orig %>%
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
                       )
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
                        )
      ),
      rango_edad2 = fct_explicit_na(rango_edad2, "Desconocido"),
      rango_edad = as.character(rango_edad),
      rango_edad2 = as.character(rango_edad2),
      SEXO = replace_na(SEXO, "No registrado"),
      epi_week = lubridate::epiweek(FECHA_VACUNACION),
      epi_year = lubridate::epiyear(FECHA_VACUNACION)
    ) %>%
    janitor::clean_names()
  origname <- glue::glue("datos/orig/vacunas_covid_{sprintf('%03d', part)}.csv.gz")
  csvname <- glue::glue("datos/vacunas_covid_aumentada_{sprintf('%03d', part)}.csv.gz")
  rdsname <- glue::glue("datos/vacunas_covid_aumentada_{sprintf('%03d', part)}.rds")
  write_csv(orig, file = origname)
  write_csv(vacunas, file = csvname)
  saveRDS(vacunas, file = rdsname)
}
