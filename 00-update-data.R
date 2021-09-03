options(tidyverse.quiet = TRUE)
library(tidyverse)
library(vroom)
library(cli)
library(DBI)

options(cli.progress_show_after = 0)
options(cli.progress_clear = FALSE)

cli_h1("Actualizando los datos")

# separar datos cada 50,000 registros,
# para insertar mejor en PostgreSQL
# y el uso de mucha memoria
n_limit <- 5e4  # de 50K en 50K
cli_alert("Estimando número de bloques")

tmp <- vroom("datos/orig/vacunas_covid.csv",
             col_types = cols(.default = col_character()))

n_rows <- nrow(tmp)
rm("tmp")
seq_nums <- 1:ceiling(n_rows/n_limit)
cli_alert("Separando por cada 50,000 registros en {max(seq_nums)} bloques")

db <- dbConnect(
  odbc::odbc(),
  "localpgsql"
)

ids <- dbGetQuery(db, "SELECT id_vacunados_covid19 from proc_vacunascovid19.tb_vacunacion_covid19;")$id_vacunados_covid19

cli_progress_bar(glue::glue("Procesando por bloques (Total={max(seq_nums)}): "), total = max(seq_nums))
for (part in seq_nums) {
  skip <- (part - 1) * n_limit + 1
  orig <- vroom(
    "datos/orig/vacunas_covid.csv",
    col_names = c(
      "id_persona",
      "id_vacunados_covid19",
      "fecha_vacunacion",
      "id_eess",
      "id_centro_vacunacion",
      "id_vacuna",
      "id_grupo_riesgo",
      "dosis"
    ),
    col_types = cols(
      .default = col_integer(),
      fecha_vacunacion = col_date(format = "%d/%m/%Y")
    ),
    skip = skip,
    n_max = n_limit
  ) %>%
    filter(
      !id_vacunados_covid19 %in% ids
    )
  if(nrow(orig) > 0) {
    cli_alert_info(paste0("Bloque: ", part, ", añadiendo ", nrow(orig), " registros"))
    dbWriteTable(
      conn = db,
      name = Id(schema = "proc_vacunascovid19",
                table = "tb_vacunacion_covid19"),
      value = orig,
      overwrite = FALSE,
      append = TRUE
    )
  } else {
    cli_alert_info(paste0("Nada que actualizar en el bloque ", part))
  }
  cli_progress_update()
}
cli_progress_done()

cli_alert("Refrescando los views materializados")

dbExecute(
  db,
  "REFRESH MATERIALIZED VIEW proc_vacunascovid19.vacunacion_covid19_resumen"
)

dbExecute(
  db,
  "REFRESH MATERIALIZED VIEW proc_vacunascovid19.vacunacion_covid19_edad"
)

dbExecute(
  db,
  "REFRESH MATERIALIZED VIEW proc_vacunascovid19.vacunacion_covid19_edad_resumen"
)

cli_alert("Descargando los datos acumulados")

df <- dbGetQuery(
  db,
  "SELECT * from proc_vacunascovid19.vacunacion_covid19_resumen ORDER BY fecha_vacunacion"
) %>%
  mutate(n_reg = as.numeric(n_reg))
saveRDS(
  df,
  file = "datos/vacunas_covid_resumen.rds"
)
write_csv(
  df,
  file = "datos/vacunas_covid_resumen.csv"
)

df <- dbGetQuery(
  db,
  "SELECT * from proc_vacunascovid19.vacunacion_covid19_edad_resumen ORDER BY fecha_vacunacion"
) %>%
  mutate(n = as.numeric(n))
saveRDS(
  df,
  file = "datos/vacunas_covid_edad_resumen.rds"
)


dbDisconnect(db)

cli_alert_success("Actualización de datos finalizada")
