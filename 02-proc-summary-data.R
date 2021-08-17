suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(clock))

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

cli_alert("Acumulando datos por semana epi y rango de edades")

deciles <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad) %>%
  tally() %>%
  arrange(rango_edad, date) %>%
  group_by(rango_edad) %>%
  mutate(
    n_acum = cumsum(n)
  )

saveRDS(
  deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.rds"
)

write_csv(
  deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.csv"
)

quintiles <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad2) %>%
  tally() %>%
  arrange(rango_edad2, date) %>%
  group_by(rango_edad2) %>%
  mutate(
    n_acum = cumsum(n)
  )

saveRDS(
  quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.rds"
)

write_csv(
  quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.csv"
)


owid <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad_owid) %>%
  tally() %>%
  arrange(rango_edad_owid, date) %>%
  group_by(rango_edad_owid) %>%
  mutate(
    n_acum = cumsum(n)
  )

saveRDS(
  owid,
  file = "datos/vacunas_covid_rangoedad_owid.rds"
)

write_csv(
  owid,
  file = "datos/vacunas_covid_rangoedad_owid.csv"
)


cli_alert_success("Proceso finalizado")
