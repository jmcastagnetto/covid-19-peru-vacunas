options(tidyverse.quiet = TRUE)
library(tidyverse)
library(cli)
library(lubridate, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)

cli_h1("Generando archivos resúmen")

cli_progress_step("Cargando los datos procesados")

vacunas <- open_dataset("tmp/arrow_augmented_data/") %>%
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
    flag_vacunacion_general
  ) %>%
  collect()

cli_alert_info(
  glue::glue("Los datos abarcan desde el {min(vacunas$fecha_vacunacion, na.rm = TRUE)} hasta el {max(vacunas$fecha_vacunacion, na.rm = TRUE)}")
)

n_old_records <- nrow(
  vacunas %>%
    filter(flag_vacunacion_general == FALSE)
)
n_total <- nrow(vacunas)

cli_alert_info(
  glue::glue("Hay {format(n_old_records, big.mark = ',')} registros que no parecen ser parte de la vacunación general, de un total de {format(n_total, big.mark = ',')}. Estos corresponden a un {sprintf('%.4f%%', (n_old_records * 100 / n_total))} del total.")
)

current_year <- lubridate::epiyear(Sys.Date())

fecha_corte <- max(vacunas$fecha_vacunacion, na.rm = TRUE)
last_epi_week <- vacunas %>%
  select(epi_year, epi_week) %>%
  distinct() %>%
  filter(epi_year == current_year) %>%
  filter(epi_week == max(epi_week, na.rm = TRUE)) %>%
  select(epi_week) %>%
  pull(epi_week)

vacunas <- vacunas %>%
  mutate(
    complete_epi_week = case_when(
      epi_year < current_year ~ 1,
      epi_year == current_year &
        epi_week < last_epi_week ~ 1,
      epi_year == current_year &
        epi_week == last_epi_week &
        fecha_corte == last_day_of_epi_week ~ 1,
      epi_year == current_year &
        epi_week == last_epi_week &
        fecha_corte < last_day_of_epi_week ~ 0
    )
  )

cli_progress_step("Acumulando por fecha de vacunación")
vacunas_sumario <- vacunas %>%
  group_by(fecha_vacunacion, fabricante, dosis, flag_vacunacion_general) %>%
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
  group_by(fecha_vacunacion, fabricante, flag_vacunacion_general) %>%
  summarise(
    n_reg_day = sum(n_reg, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  arrange(fabricante, fecha_vacunacion) %>%
  group_by(fabricante, flag_vacunacion_general) %>%
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
    total_vaccinations,
    flag_vacunacion_general
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

cli_progress_step("Acumulando datos por semana epi, dosis y proporción de población total del Perú")

pob_peru <- readRDS("datos/peru-poblacion2021-departamentos.rds") %>%
  filter(departamento == "PERU") %>%
  pull(pob2021)

vacunas_totales <- vacunas %>%
  filter(flag_vacunacion_general == TRUE) %>%
  group_by(
    epi_year, epi_week,
    last_day_of_epi_week,
    complete_epi_week,
    dosis
  ) %>%
  tally(name = "n_reg") %>%
  arrange(epi_year, epi_week, dosis) %>%
  group_by(
    epi_year,
    dosis
  ) %>%
  mutate(
    total_vaccinations = cumsum(n_reg),
    pct_total_population = 100 * total_vaccinations / pob_peru
  ) %>%
  add_column(location = "Peru", .before = 1) %>%
  select(
    location,
    epi_year,
    epi_week,
    last_day_of_epi_week,
    complete_epi_week,
    vaccine_dose = dosis,
    vaccinations_epi_week = n_reg,
    total_vaccinations,
    pct_total_population
  ) %>%
  arrange(epi_year, epi_week, vaccine_dose)

write_csv(
  vacunas_totales,
  file = "datos/vacunas_covid_totales_por_semana.csv",
  num_threads = 4
)

saveRDS(
  vacunas_totales,
  file = "datos/vacunas_covid_totales_por_semana.rds"
)

cli_progress_step("Acumulando datos por semana epi y rango de edades")

# Sólo considerar los registros de la campaña general de vacunación
# flag_vacunacion_general == TRUE

vacunas <- vacunas %>%
  filter(flag_vacunacion_general == TRUE) %>%
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
  filter(dosis <= 3) %>% # filter off dosis == 4,5,etc.
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

ubigeos <- read_parquet("~/devel/local/datos-accessorios-vacunas/datos/ubigeos.parquet")

cli_progress_step("Cargando los datos procesados con UBIGEO")
vacunas_ubiraw <- open_dataset("tmp/arrow_augmented_data/") %>%
  select(
    fecha_vacunacion,
    fabricante,
    dosis,
    ubigeo_persona,
    flag_vacunacion_general
  ) %>%
  collect()

fecha_corte <- max(vacunas_ubiraw$fecha_vacunacion, na.rm = TRUE)

cli_progress_step("Acumulando por UBIGEO de la persona")
vacunas_ubigeo <- vacunas_ubiraw %>%
  group_by(ubigeo_persona, fabricante, dosis, flag_vacunacion_general) %>%
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
