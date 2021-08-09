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

# SQLite
# change types of columns so sqlite can grok them
cli_progress_update(status = "Generando SQLite")
vacunas <- vacunas %>%
  mutate(
    fecha_corte = as.character(fecha_corte),
	fecha_vacunacion = as.character(fecha_vacunacion)
  )
vac_conn <- dbConnect(RSQLite::SQLite(), "datos/vacunas_covid_aumentada.sqlite")
dbWriteTable(vac_conn, name = "vacunas_covid", value = vacunas,
             row.names = FALSE, append = FALSE, overwrite = TRUE)
dbDisconnect(vac_conn)
cli_progress_done()

cli_alert_success("Proceso finalizado")
