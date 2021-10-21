library(tidyverse)
library(fst)

vacunas <- read_fst(
  "datos/vacunas_covid_aumentada.fst",
  columns = c("id_persona", "sexo", "edad", "fabricante", "dosis",
              "fecha_vacunacion", "ubigeo_persona",
              "centro_vacunacion_ubigeo")
)

fecha_corte <- max(vacunas$fecha_vacunacion, na.rm = TRUE)

dosis1 <- vacunas %>%
  filter(dosis == 1) %>%
  rename(
    vacunacion_ubigeo_1 = centro_vacunacion_ubigeo,
    ubigeo_persona_1 = ubigeo_persona,
    edad_1 = edad,
    fabricante_1 = fabricante,
    dosis_1 = fecha_vacunacion
  ) %>%
  select(-dosis)

dosis2 <- vacunas %>%
  filter(dosis == 2) %>%
  rename(
    vacunacion_ubigeo_2 = centro_vacunacion_ubigeo,
    ubigeo_persona_2 = ubigeo_persona,
    edad_2 = edad,
    fabricante_2 = fabricante,
    dosis_2 = fecha_vacunacion
  ) %>%
  select(-dosis, -sexo)

dosis3 <- vacunas %>%
  filter(dosis == 3) %>%
  rename(
    vacunacion_ubigeo_3 = centro_vacunacion_ubigeo,
    ubigeo_persona_3 = ubigeo_persona,
    edad_3 = edad,
    fabricante_3 = fabricante,
    dosis_3 = fecha_vacunacion
  ) %>%
  select(-dosis, -sexo)

multiples_dosis <- dosis1 %>%
  full_join(
    dosis2,
    by = c("id_persona")
  ) %>%
  full_join(
    dosis3,
    by = c("id_persona")
  ) %>%
  add_column(
    fecha_corte = fecha_corte
  )

write_fst(
  multiples_dosis,
  "datos/vacunados-multiples-dosis.fst"
)

