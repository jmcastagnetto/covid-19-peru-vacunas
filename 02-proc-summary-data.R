options(tidyverse.quiet = TRUE)
library(tidyverse)
library(cli)
library(lubridate)
#library(clock)
library(fst)

cli_h1("Generando archivos resúmen")

cli_progress_step("Cargando los datos procesados")

vacunas <- read_fst(
  "datos/vacunas_covid_aumentada.fst",
  columns = c(
    "fecha_vacunacion",
    "fabricante",
    "dosis",
    "rango_edad",
    "rango_edad_deciles",
    "rango_edad_quintiles",
    "rango_edad_owid",
    "epi_year",
    "epi_week"
  )
) %>%
  rename(
    rango_edad_veintiles = rango_edad
  ) %>%
  mutate(
    first_day_of_epi_week = floor_date(fecha_vacunacion, "weeks", week_start = 7), # first dow
    last_day_of_epi_week = ceiling_date(fecha_vacunacion, "weeks", week_start = 7), # last dow
  )

fecha_corte <- max(vacunas$fecha_vacunacion, na.rm = TRUE)
last_epi_week <- max(vacunas$epi_week, na.rm = TRUE)
vacunas <- vacunas %>%
  mutate(
    complete_epi_week = case_when(
      epi_week < last_epi_week ~ 1,
      (epi_week == last_epi_week) &
        (fecha_corte == last_day_of_epi_week) ~ 1,
      (epi_week == last_epi_week) &
        (fecha_corte < last_day_of_epi_week) ~ 0
    )
  )

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

cli_progress_step("Acumulando por dia y fabricante")

vacunas_fabricante <- vacunas_sumario %>%
  group_by(fecha_vacunacion, fabricante) %>%
  summarise(
    n_reg_day = sum(n_reg, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  arrange(fabricante, fecha_vacunacion) %>%
  group_by(fabricante) %>%
  mutate(
    total_vaccinations = cumsum(n_reg_day),
    fabricante = str_replace_all(
      fabricante,
      c(
        "PFIZER" = "Pfizer/BioNTech",
        "ASTRAZENECA" = "Oxford/AstraZeneca",
        "SINOPHARM" = "Sinopharm/Beijing"
      )
    )
  ) %>%
  add_column(location = "Peru", .before = 1) %>%
  select(
    location,
    date = fecha_vacunacion,
    vaccine = fabricante,
    vaccinations = n_reg_day,
    total_vaccinations
  ) %>%
  arrange(date, vaccine)

write_csv(
  vacunas_fabricante,
  file = "datos/vacunas_covid_fabricante.csv",
  num_threads = 4
)

saveRDS(
  vacunas_fabricante,
  file = "datos/vacunas_covid_fabricante.rds"
)

cli_progress_step("Acumulando datos por semana epi y rango de edades")

vacunas <- vacunas %>%
  select(epi_year, epi_week,
         last_day_of_epi_week,
         complete_epi_week,
         dosis,
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
  group_by(fecha_corte, epi_year, epi_week,
           last_day_of_epi_week, complete_epi_week,
           rango_edad_quintiles, dosis) %>%
  tally() %>%
  arrange(rango_edad_quintiles, dosis, last_day_of_epi_week) %>%
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
  arrange(last_day_of_epi_week, rango_edad, dosis)

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
  group_by(fecha_corte, epi_year, epi_week,
           last_day_of_epi_week, complete_epi_week,
           rango_edad_deciles, dosis) %>%
  tally() %>%
  arrange(rango_edad_deciles, dosis, last_day_of_epi_week) %>%
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
  arrange(last_day_of_epi_week, rango_edad, dosis)

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
  group_by(fecha_corte, epi_year, epi_week,
           last_day_of_epi_week, complete_epi_week,
           rango_edad_veintiles, dosis) %>%
  tally() %>%
  arrange(rango_edad_veintiles, dosis, last_day_of_epi_week) %>%
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
  arrange(last_day_of_epi_week, rango_edad, dosis)

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
  group_by(fecha_corte, epi_year, epi_week,
           last_day_of_epi_week, complete_epi_week,
           rango_edad_owid, dosis) %>%
  tally() %>%
  arrange(rango_edad_owid, dosis, last_day_of_epi_week) %>%
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
  arrange(last_day_of_epi_week, rango_edad, dosis)

owid_format <- owid %>%
  filter(rango_edad != "(Missing)") %>%
  select(fecha_corte,
         epi_year, epi_week,
         last_day_of_epi_week,
         complete_epi_week,
         rango_edad, dosis, pct_acum) %>%
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
    dosis = case_when(
      dosis == 1 ~ "people_vaccinated_per_hundred",
      dosis == 2 ~ "people_fully_vaccinated_per_hundred",
      dosis == 3 ~ "people_recieving_booster_per_hundred"
    )
  ) %>%
  ungroup() %>%
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

cli_h2("Generando archivos resúmen por UBIGEO (distrito) de la persona")

ubigeos <- read_fst("~/devel/local/datos-accessorios-vacunas/datos/ubigeos.fst")

cli_progress_step("Cargando los datos procesados con UBIGEO")
vacunas_ubiraw <- read_fst(
  "datos/vacunas_covid_aumentada.fst",
  columns = c(
    "fecha_vacunacion",
    "fabricante",
    "dosis",
    "ubigeo_persona"
  )
)

fecha_corte <- max(vacunas_ubiraw$fecha_vacunacion, na.rm = TRUE)

cli_progress_step("Acumulando por UBIGEO de la persona")
vacunas_ubigeo <- vacunas_ubiraw %>%
  group_by(ubigeo_persona, fabricante, dosis) %>%
  tally(name = "n_reg") %>%
  add_column(fecha_corte = fecha_corte, .before = 1) %>%
  ungroup() %>%
  left_join(
    ubigeos %>%
      select(
        ubigeo_persona = ubigeo_inei,
        departamento,
        provincia,
        distrito,
        macroregion_inei,
        macroregion_minsa
      ),
    by = "ubigeo_persona"
  ) %>%
  relocate(
    departamento,
    provincia,
    distrito,
    macroregion_inei,
    macroregion_minsa,
    .before = fabricante
  )

write_csv(
  vacunas_ubigeo,
  file = "datos/vacunas_covid_totales_fabricante_ubigeo.csv",
  num_threads = 4
)

saveRDS(
  vacunas_ubigeo,
  file = "datos/vacunas_covid_totales_fabricante_ubigeo.rds"
)

cli_process_done()

cli_alert_success("Proceso finalizado")
