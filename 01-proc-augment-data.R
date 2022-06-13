library(tidyverse, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)
library(collapse, warn.conflicts = FALSE)
library(cli)

vac_raw <- open_dataset("tmp/arrow_data/")

cli_progress_step("Leyendo los datos de referencia")

cli_progress_step("Leyendo los datos de personas")

primer_lote_sinopharm <- as.Date("2021-02-07")
primer_lote_pfizer <- as.Date("2021-03-03")
primer_lote_astrazeneca <- as.Date("2021-04-18")
primer_lote_moderna <- as.Date("2022-03-27")
inicio_primera_dosis <- as.Date("2021-02-09")
inicio_segunda_dosis <- as.Date("2021-03-02")
inicio_tercera_dosis <- as.Date("2021-10-15")
inicio_cuarta_dosis <- as.Date("2022-04-02")

cli_progress_step("Combinando los datos de vacunación con los de referencia")

proc_week_data <- function(infn) {
  cli_progress_step(paste0(">> Procesando ", infn))
  wkdata <- read_parquet(infn)
  vacunas <- wkdata %>%
    collect() %>%
    fmutate(
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
      flag_vacunacion_general = if_else(
        (
          (fecha_vacunacion > primer_lote_sinopharm &
             fabricante == "SINOPHARM") |
          (fecha_vacunacion > primer_lote_pfizer &
             fabricante == "PFIZER") |
          (fecha_vacunacion > primer_lote_astrazeneca &
             fabricante == "ASTRAZENECA") |
          (fecha_vacunacion > primer_lote_moderna &
             fabricante == "MODERNA")
        ) &
        (
          (fecha_vacunacion >= inicio_primera_dosis &
             dosis == 1) |
          (fecha_vacunacion >= inicio_segunda_dosis &
             dosis == 2) |
          (fecha_vacunacion >= inicio_tercera_dosis &
             dosis == 3) |
          (fecha_vacunacion >= inicio_cuarta_dosis &
             dosis == 4)
        ),
        TRUE,
        FALSE
      )
    )

  outfn <- str_replace(infn, "arrow_data", "arrow_augmented_data")
  base_dir <- dirname(outfn)
  # make base dir if it does not exist
  if(!fs::dir_exists(base_dir)) {
    fs::dir_create(base_dir)
  }
  cli_progress_step(
    paste0(">>> Guardando datos aumentados en: ", outfn)
  )
  write_parquet(vacunas, sink = outfn)
}

for (fn in vac_raw$files) {
  proc_week_data(fn)
}

cli_alert_success("Proceso de datos, finalizado")
