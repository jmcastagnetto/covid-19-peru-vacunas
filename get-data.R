library(tidyverse)
library(vroom)

download.file(
  url = "https://cloud.minsa.gob.pe/s/ZgXoXqK2KLjRLxD/download",
  destfile = "datos/vacunas_covid.csv"
)


vacunas <- vroom(
  "datos/vacunas_covid.csv",
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
                     )
                 ),
    SEXO = replace_na(SEXO, "No registrado")
  )

saveRDS(
  vacunas,
  file = "datos/vacunas_covid.rds"
)
