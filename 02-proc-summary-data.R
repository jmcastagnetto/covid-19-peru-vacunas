options(tidyverse.quiet = TRUE)
library(tidyverse)
library(cli)
library(lubridate)
library(clock)

cli_h1("Generando archivos resúmen")

cli_progress_step("Cargando los datos procesados")
vacunas <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  select(
    fecha_vacunacion,
    fabricante,
    dosis,
    rango_edad_veintiles = rango_edad,
    rango_edad_deciles,
    rango_edad_quintiles,
    rango_edad_owid,
    epi_year,
    epi_week,
  ) %>%
  mutate(
    monday = iso_year_week_day(epi_year, epi_week, 1) %>%
      as_date(), #monday
  ) %>%
  select(-epi_year, -epi_week)

fecha_corte <- max(vacunas$fecha_vacunacion, na.rm = TRUE)

cli_progress_step("Acumulando por fecha de vacunación")
vacunas_sumario <- vacunas %>%
  group_by(fecha_vacunacion, fabricante, dosis) %>%
  tally(name = "n_reg") %>%
  add_column(fecha_corte = fecha_corte, .before = 1)

write_csv(
  vacunas_sumario,
  file = "datos/vacunas_covid_resumen.csv",
  num_threads = 4
)

saveRDS(
  vacunas_sumario,
  file = "datos/vacunas_covid_resumen.rds"
)

cli_progress_step("Acumulando datos por semana epi y rango de edades")

vacunas <- vacunas %>%
  select(monday, dosis,
         rango_edad_veintiles,
         rango_edad_deciles,
         rango_edad_quintiles,
         rango_edad_owid
         ) %>%
  add_column(
    fecha_corte = fecha_corte,
    .before = 1
  )

cli_inform("-> Por quintiles")
pob_quintiles <- readRDS("datos/peru-pob2021-rango-etareo-quintiles.rds") %>%
  select(rango, pob2021 = población)
quintiles <- vacunas %>%
  group_by(fecha_corte, monday, rango_edad_quintiles, dosis) %>%
  tally() %>%
  arrange(rango_edad_quintiles, dosis, monday) %>%
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
  arrange(monday, rango_edad, dosis)

saveRDS(
  quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.rds"
)

write_csv(
  quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.csv",
  num_threads = 4
)


cli_inform("-> Por deciles")
pob_deciles <- readRDS("datos/peru-pob2021-rango-etareo-deciles.rds") %>%
  select(rango, pob2021 = población)
deciles <- vacunas %>%
  group_by(fecha_corte, monday, rango_edad_deciles, dosis) %>%
  tally() %>%
  arrange(rango_edad_deciles, dosis, monday) %>%
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
  arrange(monday, rango_edad, dosis)

saveRDS(
  deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.rds"
)

write_csv(
  deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.csv",
  num_threads = 4
)

cli_inform("-> Por veintiles")
pob_veintiles <- readRDS("datos/peru-pob2021-rango-etareo-veintiles.rds") %>%
  select(rango, pob2021 = población)
veintiles <- vacunas %>%
  group_by(fecha_corte, monday, rango_edad_veintiles, dosis) %>%
  tally() %>%
  arrange(rango_edad_veintiles, dosis, monday) %>%
  group_by(rango_edad_veintiles, dosis) %>%
  mutate(
    n_acum = cumsum(n)
  ) %>%
  ungroup() %>%
  rename(rango_edad = rango_edad_veintiles) %>%
  left_join(
    pob_veintiles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2021
  ) %>%
  arrange(monday, rango_edad, dosis)

saveRDS(
  veintiles,
  file = "datos/vacunas_covid_rangoedad_veintiles.rds"
)

write_csv(
  veintiles,
  file = "datos/vacunas_covid_rangoedad_veintiles.csv",
  num_threads = 4
)

cli_inform("-> Por OWID")
pob_owid <- readRDS("datos/peru-pob2021-rango-etareo-owid.rds") %>%
  select(rango, pob2021 = población)
owid <- vacunas %>%
  group_by(monday, rango_edad_owid, dosis) %>%
  tally() %>%
  arrange(rango_edad_owid, dosis, monday) %>%
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
  arrange(monday, rango_edad, dosis)

owid_format <- owid %>%
  filter(rango_edad != "(Missing)") %>%
  select(monday, rango_edad, dosis, pct_acum) %>%
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
  file = "datos/vacunas_covid_rangoedad_owid.csv",
  num_threads = 4
)

cli_process_done()

cli_alert_success("Proceso finalizado")
