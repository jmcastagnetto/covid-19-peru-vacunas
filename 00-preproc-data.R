options(tidyverse.quiet = TRUE)
library(tidyverse)
library(vroom)
library(lubridate)
library(cli)


options(cli.progress_show_after = 0)
options(cli.progress_clear = FALSE)

cli_h1("Pre-procesando los datos")


# separar datos por semana epi para un
# mejor uso de mucha memoria y no llegar al límite de github
cli_progress_step("Leyendo los datos originales")
vac_raw <- vroom(
  "datos/orig/vacunas_covid.csv",
  col_types = cols(
    .default = col_integer(),
    fecha_vacunacion = col_date(format = "%d/%m/%Y")
  )
) %>%
  mutate(
    grp = glue::glue(
      "{epiyear(fecha_vacunacion)}-w",
      "{sprintf('%02d', epiweek(fecha_vacunacion))}"
    )
  )
cli_progress_step("Estimando las semanas epidemiológicas")
fechas <- vac_raw %>%
  select(fecha_vacunacion, grp) %>%
  arrange(fecha_vacunacion) %>%
  distinct()
wk_list <- unique(fechas$grp)

cli_progress_bar(glue::glue("Desagregando por semana epi (Total={length(wk_list)}): "), total = length(wk_list))
for (wk in wk_list) {
  days <- fechas %>%
    filter(grp == wk)
  wk_df <- vac_raw %>%
    filter(fecha_vacunacion %in% days$fecha_vacunacion)
  saveRDS(
    wk_df,
    file = glue::glue("tmp/vacunas_raw_{wk}.rds")
  )
  cli_progress_update()
}
cli_progress_done()

cli_alert_success("Pre-proceso de datos finalizado")
