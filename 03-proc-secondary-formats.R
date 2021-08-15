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
drop_tbl <- "DROP TABLE IF EXISTS vacunas_covid;"
ddl_tbl <- "CREATE TABLE `vacunas_covid` (
  `source` TEXT,
  `fecha_corte` TEXT,
  `uuid` TEXT,
  `grupo_riesgo` TEXT,
  `edad` NUMERIC,
  `sexo` TEXT,
  `fecha_vacunacion` TEXT,
  `dosis` TEXT,
  `fabricante` TEXT,
  `diresa` TEXT,
  `departamento` TEXT,
  `provincia` TEXT,
  `distrito` TEXT,
  `rango_edad` TEXT,
  `rango_edad2` TEXT,
  `epi_week` INTEGER,
  `epi_year` INTEGER
);"
dbSendStatement(vac_conn, drop_tbl)
dbSendStatement(vac_conn, ddl_tbl)
dbWriteTable(vac_conn, name = "vacunas_covid", value = vacunas,
             row.names = FALSE, append = TRUE)
# cleanup some memory
rm("vacunas")
gc()
cli_progress_update(status = "Creando indices para SQLite")
# create some indexes after storing data
idx1_tbl <- "CREATE INDEX uuid_idx ON vacunas_covid(uuid);"
dbSendStatement(vac_conn, idx1_tbl)
idx2_tbl <- "CREATE INDEX dpto_idx ON vacunas_covid(departamento);"
dbSendStatement(vac_conn, idx2_tbl)
idx3_tbl <- "CREATE INDEX prov_idx ON vacunas_covid(provincia);"
dbSendStatement(vac_conn, idx3_tbl)
idx4_tbl <- "CREATE INDEX dist_idx ON vacunas_covid(distrito);"
dbSendStatement(vac_conn, idx4_tbl)
idx5_tbl <- "CREATE INDEX dose_idx ON vacunas_covid(dosis);"
dbSendStatement(vac_conn, idx5_tbl)
idx6_tbl <- "CREATE INDEX fabr_idx ON vacunas_covid(fabricante);"
dbSendStatement(vac_conn, idx6_tbl)
idx7_tbl <- "CREATE INDEX grpr_idx ON vacunas_covid(grupo_riesgo);"
dbSendStatement(vac_conn, idx7_tbl)
idx8_tbl <- "CREATE INDEX sexo_idx ON vacunas_covid(sexo);"
dbSendStatement(vac_conn, idx8_tbl)
idx9_tbl <- "CREATE INDEX drsa_idx ON vacunas_covid(diresa);"
dbSendStatement(vac_conn, idx9_tbl)
idx10_tbl <- "CREATE INDEX rng1_idx ON vacunas_covid(rango_edad);"
dbSendStatement(vac_conn, idx10_tbl)
idx11_tbl <- "CREATE INDEX rng2_idx ON vacunas_covid(rango_edad2);"
dbSendStatement(vac_conn, idx11_tbl)
dbDisconnect(vac_conn)
cli_progress_done()

cli_alert_success("Proceso finalizado")
