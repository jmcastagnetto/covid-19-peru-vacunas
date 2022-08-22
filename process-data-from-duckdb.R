library(tidyverse)
library(DBI)
library(duckdb)
library(lubridate)
library(cli)

# Conectar a duckdb y generar tablas accesorias ---------------------------

# Open the duckdb database file
con = dbConnect(duckdb(),
                dbdir = "tmp/ddb/peru-vacunas-covid19.duckdb",
                read_only = FALSE)
dbExecute(con, "SET memory_limit='6GB';")

cli_h1("Generando tablas accesorias")

cli_progress_step(">> epidates")
# Rebuild the epidates table
epidates <- dbGetQuery(
  con,
  "select distinct FECHA_VACUNACION from vacunas order by FECHA_VACUNACION;"
) %>%
  mutate(
    FECHA_VACUNACION = ymd(FECHA_VACUNACION),
    epi_year = epiyear(FECHA_VACUNACION) %>% as.integer(),
    epi_week = epiweek(FECHA_VACUNACION) %>% as.integer(),
    first_day_of_epi_week = floor_date(FECHA_VACUNACION,
                                       "weeks",
                                       week_start = 7), # first dow
    last_day_of_epi_week = first_day_of_epi_week + 6, # last dow
  )
current_year <- epiyear(Sys.Date())
last_epi_week <- epidates %>%
  filter(epi_year == current_year) %>%
  filter(epi_week == max(epi_week)) %>%
  pull(epi_week)
last_vaccination_date <- max(epidates$FECHA_VACUNACION, na.rm = TRUE)

epidates <- epidates %>%
  mutate(
    complete_epi_week = if_else(
      (epi_year < current_year) |
        (epi_year == current_year & epi_week < last_epi_week) |
        (epi_year == current_year &
           epi_week == last_epi_week &
           last_vaccination_date == last_day_of_epi_week),
      1,
      0
    ) %>% as.integer()
  )

dbWriteTable(con, "epidates", epidates, overwrite = TRUE)

# Rebuild the agegroups table
# Consider EDAD > 130 as an error, and take it as NA

cli_progress_step(">> agegroups")
agegroups <- dbGetQuery(
  con,
  "select distinct EDAD from vacunas order by EDAD;"
) %>%
  mutate(
    rango_edad_veintiles = cut(
      EDAD,
      c(seq(0, 80, 20), 130),
      include.lowest = TRUE,
      right = FALSE,
      labels = c("0-19",
                 "20-39",
                 "40-59",
                 "60-79",
                 "80+")
    ),
    rango_edad_deciles = cut(
      EDAD,
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
    rango_edad_quintiles = cut(
      EDAD,
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
    rango_edad_owid = cut(
      EDAD,
      c(0, 18, 25, 50, 60, 70, 80, 130),
      include.lowest = TRUE,
      right = FALSE,
      labels = c("0-17",
                 "18-24",
                 "25-49",
                 "50-59",
                 "60-69",
                 "70-79",
                 "80+")
    ),
    rango_edad_veintiles = fct_explicit_na(rango_edad_veintiles, "Desconocido"),
    rango_edad_deciles = fct_explicit_na(rango_edad_deciles, "Desconocido"),
    rango_edad_quintiles = fct_explicit_na(rango_edad_quintiles,
                                           "Desconocido"),
    rango_edad_owid = fct_explicit_na(rango_edad_owid, "(Missing)"),
    rango_edad_veintiles = as.character(rango_edad_veintiles),
    rango_edad_deciles = as.character(rango_edad_deciles),
    rango_edad_quintiles = as.character(rango_edad_quintiles),
    rango_edad_owid = as.character(rango_edad_owid)
  )

dbWriteTable(con, "agegroups", agegroups, overwrite = TRUE)

# Create the summaries
cli_h1("Generando archivos resúmen")

range_dates <- dbGetQuery(con, "select min(FECHA_VACUNACION) as min_date, max(FECHA_VACUNACION) as max_date from vacunas;") %>% as.list()

cli_alert_info(
  glue::glue("Los datos abarcan desde el {range_dates$min_date} hasta el {range_dates$max_date}")
)

vac_grl <- dbGetQuery(
  con,
  "select flag_vacunacion_general, count(*) as n
   from vacunas group by flag_vacunacion_general;")

novac_gral <- vac_grl %>% filter(!flag_vacunacion_general) %>% pull(n)
vac_total <- sum(vac_grl$n)

cli_alert_info(
  glue::glue("Hay {format(novac_gral, big.mark = ',')} registros que no parecen ser parte de la vacunación general, de un total de {format(vac_total, big.mark = ',')}. Estos corresponden a un {sprintf('%.4f%%', (novac_gral * 100 / vac_total))} del total.")
)

cli_progress_step("Acumulando por fecha de vacunación")

vacunas_sumario <- dbGetQuery(
  con,
"
  select
    FECHA_VACUNACION, FABRICANTE, DOSIS, flag_vacunacion_general,
    count(*) as n_reg
  from vacunas
  group by all
--    FECHA_VACUNACION, FABRICANTE, DOSIS, flag_vacunacion_general
  order by all
--    FECHA_VACUNACION, FABRICANTE, DOSIS, flag_vacunacion_general
"
) %>%
  add_column(
    fecha_corte = last_vaccination_date,
    .before = 1
  ) %>%
  janitor::clean_names()

write_csv(
  vacunas_sumario,
  file = "datos/vacunas_covid_resumen.csv",
  num_threads = 4
)

saveRDS(
  vacunas_sumario,
  file = "datos/vacunas_covid_resumen.rds"
)

# Por fabricante ----------------------------------------------------------

cli_progress_step("Acumulando por dia y fabricante")

vacunas_fabricante <- vacunas_sumario %>%
  group_by(fecha_vacunacion, fabricante, flag_vacunacion_general) %>%
  summarise(
    n_reg_day = sum(n_reg, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(fabricante, fecha_vacunacion) %>%
  group_by(fabricante, flag_vacunacion_general) %>%
  mutate(
    total_vaccinations = cumsum(replace_na(n_reg_day, 0))#,
    # fabricante = str_replace_all(
    #   fabricante,
    #   c(
    #     "PFIZER" = "Pfizer/BioNTech",
    #     "ASTRAZENECA" = "Oxford/AstraZeneca",
    #     "SINOPHARM" = "Sinopharm/Beijing",
    #     "MODERNA" = "Moderna",
    #   )
    # )
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

# Por semana epi, dosis y % de población ----------------------------------
cli_progress_step("Acumulando datos por semana epi, dosis y proporción de población total del Perú")

pob_peru <- readRDS("datos/peru-pob2022-departamentos.rds") %>%
  filter(departamento == "PERU") %>%
  pull(total)

vacunas_totales <- dbGetQuery(
  con,
"
  select
    b.epi_year,
    b.epi_week,
    b.last_day_of_epi_week,
    b.complete_epi_week,
    a.DOSIS,
    count(a.id_row) as n_reg
  from
    vacunas as a
    left join
    epidates as b
    on (a.FECHA_VACUNACION = b.FECHA_VACUNACION)
  where
    flag_vacunacion_general = TRUE
  group by all
    -- epi_year,
    -- epi_week,
    -- last_day_of_epi_week,
    -- complete_epi_week,
    -- dosis
  order by all
    -- epi_year,
    -- epi_week,
    -- dosis
"
) %>%
  janitor::clean_names() %>%
  group_by(
    dosis
  ) %>%
  mutate(
    total_vaccinations = cumsum(replace_na(n_reg, 0)),
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

cli_h1("Acumulando datos por semana epi y rango de edades")

# Sólo considerar los registros de la campaña general de vacunación
# flag_vacunacion_general == TRUE


# Veintiles ---------------------------------------------------------------

cli_inform("-> Por veintiles")
pob_veintiles <- readRDS("datos/peru-pob2022-rango-etareo-veintiles.rds") %>%
  select(rango, pob2022 = población)

vacunas_veintiles <- dbGetQuery(
  con,
  "
  select
    b.epi_year,
    b.epi_week,
    b.last_day_of_epi_week,
    b.complete_epi_week,
    c.rango_edad_veintiles as rango_edad,
    a.DOSIS,
    count(a.id_row) as n
  from
    vacunas as a
    left join
      epidates as b
      on (a.FECHA_VACUNACION = b.FECHA_VACUNACION)
    left join
      agegroups as c
      on (a.EDAD = c.EDAD)
  where
    flag_vacunacion_general = TRUE
  group by all
  order by
    c.rango_edad_veintiles,
    a.DOSIS,
    b.last_day_of_epi_week
"
) %>%
  janitor::clean_names() %>%
  filter(!is.na(rango_edad)) %>%
  group_by(rango_edad, dosis) %>%
  mutate(
    n = replace_na(n, 0),
    n_acum = cumsum(n)  # avoid NAs affecting cummulative sum
  ) %>%
  ungroup() %>%
  left_join(
    pob_veintiles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2022
  ) %>%
  arrange(last_day_of_epi_week, rango_edad, dosis) %>%
  add_column(
    fecha_corte = last_vaccination_date,
    .before = 1
  )

saveRDS(
  vacunas_veintiles,
  file = "datos/vacunas_covid_rangoedad_veintiles.rds"
)

write_csv(
  vacunas_veintiles,
  file = "datos/vacunas_covid_rangoedad_veintiles.csv",
  num_threads = 4
)

# Deciles ---------------------------------------------------------------

cli_inform("-> Por deciles")
pob_deciles <- readRDS("datos/peru-pob2022-rango-etareo-deciles.rds") %>%
  select(rango, pob2022 = población)

vacunas_deciles <- dbGetQuery(
  con,
  "
  select
    b.epi_year,
    b.epi_week,
    b.last_day_of_epi_week,
    b.complete_epi_week,
    c.rango_edad_deciles as rango_edad,
    a.DOSIS,
    count(a.id_row) as n
  from
    vacunas as a
    left join
      epidates as b
      on (a.FECHA_VACUNACION = b.FECHA_VACUNACION)
    left join
      agegroups as c
      on (a.EDAD = c.EDAD)
  where
    flag_vacunacion_general = TRUE
  group by all
  order by
    c.rango_edad_deciles,
    a.DOSIS,
    b.last_day_of_epi_week
"
) %>%
  janitor::clean_names() %>%
  filter(!is.na(rango_edad)) %>%
  group_by(rango_edad, dosis) %>%
  mutate(
    n = replace_na(n, 0),
    n_acum = cumsum(n)  # avoid NAs affecting cummulative sum
  ) %>%
  ungroup() %>%
  left_join(
    pob_deciles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2022
  ) %>%
  arrange(last_day_of_epi_week, rango_edad, dosis) %>%
  add_column(
    fecha_corte = last_vaccination_date,
    .before = 1
  )

saveRDS(
  vacunas_deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.rds"
)

write_csv(
  vacunas_deciles,
  file = "datos/vacunas_covid_rangoedad_deciles.csv",
  num_threads = 4
)

# Quintiles ---------------------------------------------------------------

cli_inform("-> Por quintiles")
pob_quintiles <- readRDS("datos/peru-pob2022-rango-etareo-quintiles.rds") %>%
  select(rango, pob2022 = población)

vacunas_quintiles <- dbGetQuery(
  con,
  "
  select
    b.epi_year,
    b.epi_week,
    b.last_day_of_epi_week,
    b.complete_epi_week,
    c.rango_edad_quintiles as rango_edad,
    a.DOSIS,
    count(a.id_row) as n
  from
    vacunas as a
    left join
      epidates as b
      on (a.FECHA_VACUNACION = b.FECHA_VACUNACION)
    left join
      agegroups as c
      on (a.EDAD = c.EDAD)
  where
    flag_vacunacion_general = TRUE
  group by all
  order by
    c.rango_edad_quintiles,
    a.DOSIS,
    b.last_day_of_epi_week
"
) %>%
  janitor::clean_names() %>%
  filter(!is.na(rango_edad)) %>%
  group_by(rango_edad, dosis) %>%
  mutate(
    n = replace_na(n, 0),
    n_acum = cumsum(n)  # avoid NAs affecting cummulative sum
  ) %>%
  ungroup() %>%
  left_join(
    pob_quintiles,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2022
  ) %>%
  arrange(last_day_of_epi_week, rango_edad, dosis) %>%
  add_column(
    fecha_corte = last_vaccination_date,
    .before = 1
  )

saveRDS(
  vacunas_quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.rds"
)

write_csv(
  vacunas_quintiles,
  file = "datos/vacunas_covid_rangoedad_quintiles.csv",
  num_threads = 4
)


# OWID --------------------------------------------------------------------

cli_inform("-> Por owid")
pob_owid <- readRDS("datos/peru-pob2022-rango-etareo-owid.rds") %>%
  select(rango, pob2022 = población)

vacunas_owid <- dbGetQuery(
  con,
  "
  select
    b.epi_year,
    b.epi_week,
    b.last_day_of_epi_week,
    b.complete_epi_week,
    c.rango_edad_owid as rango_edad,
    a.DOSIS,
    count(a.id_row) as n
  from
    vacunas as a
    left join
      epidates as b
      on (a.FECHA_VACUNACION = b.FECHA_VACUNACION)
    left join
      agegroups as c
      on (a.EDAD = c.EDAD)
  where
    flag_vacunacion_general = TRUE
  group by all
  order by
    c.rango_edad_owid,
    a.DOSIS,
    b.last_day_of_epi_week
"
) %>%
  janitor::clean_names() %>%
  filter(!is.na(rango_edad)) %>%
  group_by(rango_edad, dosis) %>%
  mutate(
    n = replace_na(n, 0),
    n_acum = cumsum(n)  # avoid NAs affecting cummulative sum
  ) %>%
  ungroup() %>%
  left_join(
    pob_owid,
    by = c("rango_edad" = "rango")
  ) %>%
  mutate(
    pct_acum = n_acum / pob2022
  ) %>%
  arrange(last_day_of_epi_week, rango_edad, dosis) %>%
  add_column(
    fecha_corte = last_vaccination_date,
    .before = 1
  )

owid_format <- vacunas_owid %>%
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
      dosis == 3 ~ "people_receiving_booster_per_hundred",
      dosis == 4 ~ "people_receiving_second_booster_per_hundred",
      TRUE ~ "WRONG"
    )
  ) %>%
  filter(dosis != "WRONG") %>%
  ungroup() %>%
  pivot_wider(
    names_from = dosis,
    values_from = pct_acum
  ) %>%
  relocate(
    people_receiving_booster_per_hundred,
    people_receiving_second_booster_per_hundred,
    .after = last_col()
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

dbDisconnect(con, shutdown = TRUE)

cli_process_done()

cli_alert_success("Proceso finalizado")

