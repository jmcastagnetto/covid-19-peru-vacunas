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

cli_alert("-> Por quintiles")
pob_quintiles <- readRDS("datos/peru-pob2021-rango-etareo-quintiles.rds") %>%
  select(rango, pob2021 = población)
quintiles <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad_quintiles, dosis) %>%
  tally() %>%
  arrange(rango_edad_quintiles, dosis, date) %>%
  group_by(rango_edad_quintiles, dosis) %>%
  mutate(
    n_acum = cumsum(n)
  ) %>%
  ungroup() %>%
  rename(rango_edad = rango_edad_quintiles) %>%
  left_join(
    pob_quintiles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2021
  ) %>%
  arrange(date, rango_edad, dosis)

saveRDS(
  quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.rds"
)

write_csv(
  quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.csv"
)


cli_alert("-> Por deciles")
pob_deciles <- readRDS("datos/peru-pob2021-rango-etareo-deciles.rds") %>%
  select(rango, pob2021 = población)
deciles <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad_deciles, dosis) %>%
  tally() %>%
  arrange(rango_edad_deciles, dosis, date) %>%
  group_by(rango_edad_deciles, dosis) %>%
  mutate(
    n_acum = cumsum(n)
  ) %>%
  ungroup() %>%
  rename(rango_edad = rango_edad_deciles) %>%
  left_join(
    pob_deciles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2021
  ) %>%
  arrange(date, rango_edad, dosis)

saveRDS(
  deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.rds"
)

write_csv(
  deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.csv"
)

cli_alert("-> Por veintiles")
pob_veintiles <- readRDS("datos/peru-pob2021-rango-etareo-veintiles.rds") %>%
  select(rango, pob2021 = población)
veintiles <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad, dosis) %>%
  tally() %>%
  arrange(rango_edad, dosis, date) %>%
  group_by(rango_edad, dosis) %>%
  mutate(
    n_acum = cumsum(n)
  ) %>%
  ungroup() %>%
  left_join(
    pob_veintiles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2021
  ) %>%
  arrange(date, rango_edad, dosis)

saveRDS(
  veintiles,
  file = "datos/vacunas_covid_rangoedad_veintiles.rds"
)

write_csv(
  veintiles,
  file = "datos/vacunas_covid_rangoedad_veintiles.csv"
)

cli_alert("-> Por OWID")
pob_owid <- readRDS("datos/peru-pob2021-rango-etareo-owid.rds") %>%
  select(rango, pob2021 = población)
owid <- vacunas %>%
  mutate(
    date = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  group_by(epi_year, epi_week, date, rango_edad_owid, dosis) %>%
  tally() %>%
  arrange(rango_edad_owid, dosis, date) %>%
  group_by(rango_edad_owid, dosis) %>%
  mutate(
    n_acum = cumsum(n)
  ) %>%
  ungroup() %>%
  rename(rango_edad = rango_edad_owid) %>%
  left_join(
    pob_owid,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2021
  ) %>%
  arrange(date, rango_edad, dosis)

owid_format <- owid %>%
  filter(rango_edad != "(Missing)") %>%
  select(date, rango_edad, dosis, pct_acum) %>%
  add_column(
    location = "Peru",
    .before = 1
  ) %>%
  mutate(
    pct_acum = round(pct_acum * 100, 4),
    rango_edad = str_replace(rango_edad, "80\\+", "80-")
  ) %>%
  separate(
    col = rango_edad,
    into = c("age_group_min", "age_group_max"),
    sep = "-"
  ) %>%
  mutate(
    dosis = if_else(
      dosis == 1,
      "people_vaccinated_per_hundred",
      "people_fully_vaccinated_per_hundred"
    )
  ) %>%
  pivot_wider(
    names_from = dosis,
    values_from = pct_acum
  )

saveRDS(
  owid_format,
  file = "datos/vacunas_covid_rangoedad_owid.rds"
)

write_csv(
  owid_format,
  file = "datos/vacunas_covid_rangoedad_owid.csv"
)

cli_alert_success("Proceso finalizado")
