library(arrow, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
library(stringr)

# remove old csv files
oldcsv <- fs::dir_ls("datos/datos_aumentados_diarios/", glob = "*.csv")
unlink(oldcsv)

dataset <- open_dataset("tmp/arrow_augmented_data/")

parquet_files <- dataset$files
for (pqt in parquet_files) {
  cat("> Procesando ", pqt, "\n")
  df <- read_parquet(pqt) %>%
    rename(
      rango_edad_veintiles = rango_edad
    ) %>%
    mutate(
      epi_year = lubridate::epiyear(fecha_vacunacion),
      epi_week = lubridate::epiweek(fecha_vacunacion)
    )
  days <- unique(df$fecha_vacunacion)
  for (day in days) {
    df2 <- df %>%
      filter(fecha_vacunacion == day) %>%
      arrange(id_vacunados_covid19)
    epi_year <- unique(df2$epi_year)
    epi_week <- unique(df2$epi_week)
    n_limit <- 150001
    if (nrow(df2) >= n_limit) {
      split_list <- df2 %>%
        group_split(group_id = row_number() %/% n_limit)
      for(part in 1:length(split_list)) {
        df3 <- split_list[[part]]
        fname <- paste0(
          "datos/datos_aumentados_diarios/vacunas_covid_aumentada_",
          epi_year,
          "-w",
          sprintf("%02d", epi_week),
          "_",
          format(as.Date(day, origin = "1970-01-01"), format = "%Y%m%d"),
          "_",
          sprintf("p%03d", part),
          ".csv"
        )
        cat("--> Guardando ", fname, "\n")
        write.csv(df3, fname, row.names = FALSE)
      }
    } else {
      fname <- paste0(
        "datos/datos_aumentados_diarios/vacunas_covid_aumentada_",
        epi_year,
        "-w",
        sprintf("%02d", epi_week),
        "_",
        format(as.Date(day, origin = "1970-01-01"), format = "%Y%m%d"),
        ".csv"
      )
      cat("> Guardando ", fname, "\n")
      write.csv(df2, fname, row.names = FALSE)
    }
  }
}