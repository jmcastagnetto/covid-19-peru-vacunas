library(tidyverse)

vacunas <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  select(id_persona, sexo, edad, dosis, 
         fecha_vacunacion, persona_ubigeo = ubigeo_persona,
         centro_vacunacion_ubigeo)

dosis1 <- vacunas %>%
  filter(dosis == 1) %>%
  rename(
    vacunacion_ubigeo_1 = centro_vacunacion_ubigeo,
    edad_1 = edad,
    dosis_1 = fecha_vacunacion
  ) %>%
  select(-dosis)

dosis2 <- vacunas %>%
  filter(dosis == 2) %>%
  rename(
    vacunacion_ubigeo_2 = centro_vacunacion_ubigeo,
    edad_2 = edad,
    dosis_2 = fecha_vacunacion
  ) %>%
  select(-dosis, -sexo, -persona_ubigeo)

dos_dosis <- dosis1 %>%
  full_join(
    dosis2,
    by = c("id_persona")
  ) %>%
  filter(!is.na(dosis_2))

saveRDS(
  dos_dosis,
  file = "datos/vacunados-dos-dosis.rds"
)

n_limit <- 1e6  # de millón en millón
n_rows <- nrow(dos_dosis)
if (n_rows > n_limit) {
  grupo  <- rep(1:ceiling(n_rows/n_limit),each = n_limit)[1:n_rows]
  v_list <- split(dos_dosis, grupo)
  for(i in 1:length(v_list)) {
    tmp_df <- v_list[[i]]
    csvname <- glue::glue("datos/vacunados_dos_dosis_{sprintf('%03d', i)}.csv.gz")
    write_csv(tmp_df, file = csvname)
  }
}
