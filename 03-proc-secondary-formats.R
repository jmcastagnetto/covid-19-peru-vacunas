library(tidyverse)
library(arrow)
library(qs)
library(RSQLite)

# Guardar en formatos secundarios, datos completos ------------------------

message("Convirtiendo de RDS a qs, sqlite y parquet locales")
vacunas <- readRDS("datos/vacunas_covid_aumentada.rds")

# Archivos que no van a github

# QS
qsave(
  vacunas,
  file = "datos/vacunas_covid_aumentada.qs"
)

# Arrow
vacunas %>%
  group_by(epi_week) %>%
  write_dataset(
    path = "datos/parquet/",
    format = "parquet",
    template = "covid_vacunas_part_{i}.parquet"
  )

# SQLite
# change types of columns so sqlite can grok them
vacunas <- vacunas %>%
  mutate(
    fecha_corte = as.character(fecha_corte),
	fecha_vacunacion = as.character(fecha_vacunacion)
  )
vac_conn <- dbConnect(RSQLite::SQLite(), "datos/vacunas_covid_aumentada.sqlite")
dbWriteTable(vac_conn, name = "vacunas_covid", value = vacunas,
             row.names = FALSE, append = FALSE, overwrite = TRUE)
dbDisconnect(vac_conn)

