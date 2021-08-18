suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(arrow))
suppressPackageStartupMessages(library(qs))
suppressPackageStartupMessages(library(RSQLite))
suppressPackageStartupMessages(library(cli))

# Guardar en formatos secundarios, datos completos ------------------------

cli_h1("Convirtiendo de RDS a sqlite y parquet locales")

cli_progress_bar("Procesando... ", type = "task")
cli_progress_update(status = "Cargando datos acumulados")
vacunas <- readRDS("datos/vacunas_covid_aumentada.rds")

# Archivos que no van a github

# QS
#cli_alert("Generando QS")
#qsave(
#  vacunas,
#  file = "datos/vacunas_covid_aumentada.qs"
#)

# Arrow
cli_progress_update(status = "Generando parquet, por semana epidemiológica")
vacunas %>%
  group_by(epi_week) %>%
  write_dataset(
    path = "datos/parquet/",
    format = "parquet",
    template = "covid_vacunas_part_{i}.parquet"
  )


# csv to use as input for sqlite
write_csv(
  vacunas,
  file = "datos/vacunas_covidi_aumentada.csv"
)
cli_progress_done()

cli_alert_success("Proceso finalizado")
