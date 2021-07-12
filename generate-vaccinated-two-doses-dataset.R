library(tidyverse)
library(qs)

ubigeos <- readRDS(url("https://github.com/jmcastagnetto/ubigeo-peru-aumentado/raw/main/ubigeos_reniec_inei_aumentado.rds")) %>%
  select(reniec, inei, departamento, provincia, distrito) %>%
  mutate_at(
    vars(departamento, provincia, distrito),
    iconv,
    to='ASCII//TRANSLIT'
  )

vacunas <- qread("datos/vacunas_covid_aumentada.qs") %>%
  select(uuid, sexo, rango_edad, dosis, fecha_vacunacion,
         departamento, provincia, distrito) %>%
  mutate(
    provincia = str_replace_all(
      provincia,
      pattern = c(
        "SAN ROMAS" = "SAN ROMAN"
      )
    ) %>%
      iconv(to='ASCII//TRANSLIT'),
    distrito = str_replace_all(
      distrito,
      pattern = c(
        "MAGDALENA VIEJA \\(PUEBLO LIBRE\\)" = "PUEBLO LIBRE",
        "LURIGANCHO \\(CHOSICA\\)" = "LURIGANCHO",
        "KIMBIRI" = "QUIMBIRI",
        "PICHANAKI" = "PICHANAQUI",
        "ALEXANDER VON HUMBO" = "ALEXANDER VON HUMBOLDT",
        "VEINTISEIS DE OCTUB" = "VEINTISEIS DE OCTUBRE",
        "DANIEL ALOMIA ROBLES" = "DANIEL ALOMIAS ROBLES",
        "SAN JUAN DE ISCOS" = "SAN JUAN DE YSCOS"
      )
    ) %>%
      iconv(to='ASCII//TRANSLIT'),
    # caso especial
    provincia = if_else(
      provincia == "CONCEPCION" &
        distrito == "SANTO DOMINGO DE ACOBAMBA",
      "HUANCAYO",
      provincia
    )
  ) %>%
  left_join(
    ubigeos,
    by = c("departamento", "provincia", "distrito")
  )

dosis1 <- vacunas %>%
  filter(dosis == 1) %>%
  rename(
    reniec1 = reniec,
    inei1 = inei,
    rango_edad1 = rango_edad,
    dosis1 = fecha_vacunacion
  ) %>%
  select(-dosis, -departamento, -provincia, -distrito)

dosis2 <- vacunas %>%
  filter(dosis == 2) %>%
  rename(
    reniec2 = reniec,
    inei2 = inei,
    rango_edad2 = rango_edad,
    dosis2 = fecha_vacunacion
  ) %>%
  select(-dosis, -departamento, -provincia, -distrito)

dos_dosis <- dosis1 %>%
  full_join(
    dosis2,
    by = c("uuid", "sexo")
  ) %>%
  filter(!is.na(dosis2))

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

qsave(
  dos_dosis,
  file = "datos/vacunados-dos-dosis.qs"
)
