library(dplyr, warn.conflicts = FALSE)
library(vroom, warn.conflicts = FALSE)
library(lubridate, warn.conflicts = FALSE)
library(cli, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)
library(collapse, warn.conflicts = FALSE, quietly = TRUE)

options(cli.progress_show_after = 0)
options(cli.progress_clear = FALSE)

cli_h1("Pre-procesando los datos")

# separar datos por año y semana epi usando arrow
cli_progress_step("Leyendo los datos originales y agregando epi_year, epi_week, last/first day of epi_week")

# vroom tiene mejor performance que readr::read_csv() o
# que arrow::read_csv_arrow()
vac_raw <- vroom(
  "datos/orig/vacunas_covid.csv",
  col_types = cols(
    .default = col_integer(),
    FECHA_VACUNACION = col_date(format = "%Y%m%d")
  ),
  num_threads = 4,
  progress = TRUE,
  altrep = TRUE
) %>%
  janitor::clean_names() %>%
  ftransform(
    epi_year = epiyear(fecha_vacunacion) %>% as.integer(),
    epi_week = epiweek(fecha_vacunacion) %>% as.integer(),
    first_day_of_epi_week = floor_date(fecha_vacunacion,
                                       "weeks",
                                       week_start = 7) # first dow
  ) %>%
  mutate(
    last_day_of_epi_week = first_day_of_epi_week + 6 # last dow
  )
cli_progress_step(paste0(">>> Orig. rows: ", nrow(vac_raw)))
#vac_raw <- distinct(vac_raw)
#cli_progress_step(paste0(">>> Distinct rows: ", nrow(vac_raw)))

cli_progress_step("Estructura de datos")
str(vac_raw)

cli_progress_step("Guardando datos por epi_year y epi_week como parquet files")
write_dataset(
  vac_raw,
  path = "tmp/arrow_data/",
  partitioning = c("epi_year", "epi_week"),
  existing_data_behavior = "overwrite"
)
cli_progress_step("Guardando datos por dosis y epi_year como parquet files")
write_dataset(
  vac_raw,
  path = "tmp/arrow_data2/",
  partitioning = c("dosis", "epi_year"),
  existing_data_behavior = "overwrite"
)
cli_progress_done()

cli_alert_success("Pre-proceso de datos finalizado")
