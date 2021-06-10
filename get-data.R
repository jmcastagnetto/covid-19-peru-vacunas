library(tidyverse)
library(vroom)
library(qs)

#download.file(
#  url = "https://cloud.minsa.gob.pe/s/ZgXoXqK2KLjRLxD/download",
#  destfile = "datos/orig/vacunas_covid.csv"
#)
#R.utils::gzip("datos/orig/vacunas_covid.csv",
#              overwrite = TRUE, remove = TRUE)

orig <- vroom(
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

# local files that will not fit in github because of their size
saveRDS(
  vacunas,
  file = "datos/vacunas_covid_aumentada.rds"
)

qsave(
  vacunas,
  file = "datos/vacunas_covid_aumentada.qs"
)

# separar datos cada millón de registros,
# para evitar problemas de tamaño con github
n_limit <- 1e6  # de millón en millón
n_rows <- nrow(vacunas)
if (n_rows > n_limit) {
  grupo  <- rep(1:ceiling(n_rows/n_limit),each = n_limit)[1:n_rows]
  v_list <- split(vacunas, grupo)
  o_list <- split(orig, grupo)
  for(i in 1:length(v_list)) {
    tmp_df <- v_list[[i]]
    orig_df <- o_list[[i]]
    origname <- glue::glue("datos/orig/vacunas_covid_{sprintf('%03d', i)}.csv.gz")
    csvname <- glue::glue("datos/vacunas_covid_aumentada_{sprintf('%03d', i)}.csv.gz")
    rdsname <- glue::glue("datos/vacunas_covid_aumentada_{sprintf('%03d', i)}.rds")
    write_csv(orig_df, file = origname)
    write_csv(tmp_df, file = csvname)
    saveRDS(tmp_df, file = rdsname)
  }
}

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

