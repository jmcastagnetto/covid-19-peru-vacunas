suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(cli))

cli_h1("Generando archivo resúmen")

rdslist <- fs::dir_ls("datos/",
                      regexp = "vacunas_covid_aumentada_[0-9]{3}\\.rds")
cli_alert("Cargando los archivos parciales")
vacunas <- map_dfr(rdslist, read_rds) #, .id = "source")
# RDS
saveRDS(
  vacunas,
  file = "datos/vacunas_covid_aumentada.rds"
)

cli_alert("Acumulando datos por fecha de vacunación")
vac_resumen <- vacunas %>%
  select(fecha_corte, fecha_vacunacion,
         uuid, fabricante, dosis) %>%
  distinct() %>%
  group_by(fecha_corte,
           fecha_vacunacion,
           fabricante,
           dosis) %>%
  tally(name = "n_reg") %>%
  ungroup() %>%
  mutate(
    fabricante = factor(fabricante)
  ) %>%
  arrange(fecha_vacunacion)

saveRDS(
  vac_resumen,
  file = "datos/vacunas_covid_resumen.rds"
)

write_csv(
  vac_resumen,
  file = "datos/vacunas_covid_resumen.csv"
)

cli_alert_success("Proceso finalizado")
