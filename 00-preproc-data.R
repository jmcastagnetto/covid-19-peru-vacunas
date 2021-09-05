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
  ),
  num_threads = 4
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
mark_changed <- data.frame()

cli_progress_bar(
  glue::glue("Desagregando por semana epi (Total={length(wk_list)}): "), 
  total = length(wk_list)
)
for (wk in wk_list) {
  out_fn <- glue::glue("tmp/vacunas_raw_{wk}.rds")
  days <- fechas %>%
    filter(grp == wk)
  wk_df <- vac_raw %>%
    filter(fecha_vacunacion %in% days$fecha_vacunacion) %>%
    arrange(id_vacunados_covid19)
  if (file.exists(out_fn)) {
    res <- try (
      prev_df <- readRDS(out_fn) %>%
        arrange(id_vacunados_covid19)
      compare <- all.equal(prev_df,
                           wk_df,
                           check.attributes = FALSE,
                           check.names = TRUE)
      if (!isTRUE(compare)) {
        changed_list <- paste0(
          substr(
            as.character(paste(compare, sep = " ", collapse = ",")), 
            1, 8), 
          "...")
        cli_alert_warning("Datos de {wk} han cambiado ({changed_list})")
        mark_changed <- bind_rows(
          mark_changed,
          tibble(changed_wk = wk, file = out_fn)
        )
      }
    )
    if (inherits(res, "try-error") {
      cli_alert_danger(as.character(attr(r, "condition")))
    }
  }
  cli_alert_info("Guardando {out_fn}")
  saveRDS(wk_df, file = out_fn)
  cli_progress_update()
}

saveRDS(
  mark_changed,
  file = "tmp/changed_weeks.rds"
)
cli_progress_done()

cli_alert_success("Pre-proceso de datos finalizado")
