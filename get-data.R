library(tidyverse)
library(archive)
library(vroom)
library(qs)
library(arrow)


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


# Recombinar los datos procesados -----------------------------------------
rm("orig")
rm("vacunas")
gc()
print("Recombinando datos y guardando RDS, qs y parquet locales")
rdslist <- fs::dir_ls("datos/", regexp = "vacunas_covid_aumentada_[0-9]{3}\\.rds")
vacunas <- tibble()
for(fn in rdslist) {
  vacunas <- bind_rows(vacunas, readRDS(fn))
}

# local files that will not fit in github because of their size
saveRDS(
  vacunas,
  file = "datos/vacunas_covid_aumentada.rds"
)

qsave(
  vacunas,
  file = "datos/vacunas_covid_aumentada.qs"
)

# Save as arrow's parquet separated by epi week ---------------------------

vacunas %>%
  group_by(epi_week) %>%
  write_dataset(
    path = "datos/parquet/",
    format = "parquet",
    template = "covid_vacunas_part_{i}.parquet"
  )


# Resumen -----------------------------------------------------------------
print("Generando archivo resúmen")

vac_resumen <- vacunas %>%
  select(fecha_corte, fecha_vacunacion,
         uuid, fabricante, dosis) %>%
  distinct() %>%
  group_by(fecha_corte,
           fecha_vacunacion,
           fabricante,
           dosis) %>%
  tally(name = "n_reg") %>%
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

