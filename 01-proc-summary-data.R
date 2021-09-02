options(tidyverse.quiet = TRUE)
library(tidyverse)
library(cli)
library(lubridate)
library(clock)

cli_h1("Generando archivos resúmen")

vacunas <- readRDS("datos/vacunas_covid_edad_resumen.rds") %>%
  mutate(
    epi_year = epiyear(fecha_vacunacion),
    epi_week = epiweek(fecha_vacunacion),
    rango_edad = cut(edad,
                     c(seq(0, 80, 20), 130),
                     include.lowest = TRUE,
                     right = FALSE,
                     labels = c(
                       "0-19",
                       "20-39",
                       "40-59",
                       "60-79",
                       "80+"
                     )
    ),
    rango_edad_deciles = cut(edad,
                             c(seq(0, 80, 10), 130),
                             include.lowest = TRUE,
                             right = FALSE,
                             labels = c(
                               "0-9",
                               "10-19",
                               "20-29",
                               "30-39",
                               "40-49",
                               "50-59",
                               "60-69",
                               "70-79",
                               "80+"
                             )
    ),
    rango_edad_quintiles = cut(edad,
                               c(seq(0, 80, 5), 130),
                               include.lowest = TRUE,
                               right = FALSE,
                               labels = c(
                                 "0-4",
                                 "5-9",
                                 "10-14",
                                 "15-19",
                                 "20-24",
                                 "25-29",
                                 "30-34",
                                 "35-39",
                                 "40-44",
                                 "45-49",
                                 "50-54",
                                 "55-59",
                                 "60-64",
                                 "65-69",
                                 "70-74",
                                 "75-79",
                                 "80+"
                               )
    ),
    rango_edad_owid = cut(edad,
                          c(0, 18, 25, 50, 60, 70, 80, 130),
                          include.lowest = TRUE,
                          right = FALSE,
                          labels = c(
                            "0-17",
                            "18-24",
                            "25-49",
                            "50-59",
                            "60-69",
                            "70-79",
                            "80+"
                          )
    ),
    rango_edad = fct_explicit_na(rango_edad, "Desconocido"),
    rango_edad_deciles = fct_explicit_na(rango_edad_deciles, "Desconocido"),
    rango_edad_quintiles = fct_explicit_na(rango_edad_quintiles, "Desconocido"),
    rango_edad_owid = fct_explicit_na(rango_edad_owid, "(Missing)"),
    rango_edad = as.character(rango_edad),
    rango_edad_deciles = as.character(rango_edad_deciles),
    rango_edad_quintiles = as.character(rango_edad_quintiles),
    rango_edad_owid = as.character(rango_edad_owid)
  )

max_date <- vacunas$fecha_vacunacion

vacunas <- vacunas %>%
  add_column(
    fecha_corte = max_date,
    .before = 1
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
  group_by(fecha_corte, epi_year, epi_week, date, rango_edad_quintiles, dosis) %>%
  summarise(
    n = sum(n, na.rm = TRUE)
  ) %>%
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
  group_by(fecha_corte, epi_year, epi_week, date, rango_edad_deciles, dosis) %>%
  summarise(
    n = sum(n, na.rm = TRUE)
  ) %>%
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
  group_by(fecha_corte, epi_year, epi_week, date, rango_edad, dosis) %>%
  summarise(
    n = sum(n, na.rm = TRUE)
  ) %>%
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
  summarise(
    n = sum(n, na.rm = TRUE)
  ) %>%
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
