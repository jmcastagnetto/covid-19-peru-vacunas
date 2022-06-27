library(dplyr, warn.conflicts = FALSE)
library(cli, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)
library(lubridate)

options(cli.progress_show_after = 0)
options(cli.progress_clear = FALSE)

cli_h1("Pre-procesando los datos")

cli_progress_step("Leyendo los datos originales")

vac_raw <- read_csv_arrow(
  "datos/orig/vacunas_covid.csv"
) %>%
  janitor::clean_names() %>%
  mutate(
    fecha_corte = ymd(fecha_corte),
    fecha_vacunacion = ymd(fecha_vacunacion),
    epi_year = epiyear(fecha_vacunacion),
    epi_week = epiweek(fecha_vacunacion),
    first_day_of_epi_week = floor_date(fecha_vacunacion,
                                       "weeks",
                                       week_start = 7), # first dow
    last_day_of_epi_week = first_day_of_epi_week + 6 # last dow
  )
#cli_progress_step(paste0(">>> Orig. rows: ", nrow(vac_raw)))
#vac_raw <- distinct(vac_raw)
#cli_progress_step(paste0(">>> Distinct rows: ", nrow(vac_raw)))

cli_inform("Estructura de datos")
str(vac_raw)
gc()

cli_progress_step("Guardando datos por epi_year y epi_week como parquet files")
write_dataset(
  vac_raw,
  path = "tmp/arrow_data/",
  partitioning = c("epi_year", "epi_week"),
  existing_data_behavior = "overwrite"
)
#cli_progress_step("Guardando datos por dosis y epi_year como parquet files")
#write_dataset(
#  vac_raw,
#  path = "tmp/arrow_data2/",
#  partitioning = c("dosis", "epi_year"),
#  existing_data_behavior = "overwrite"
#)
#cli_progress_done()
#
cli_alert_success("Pre-proceso de datos finalizado")
