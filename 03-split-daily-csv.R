library(fst)
library(dplyr)
library(stringr)
wk_list <- fs::dir_ls("datos", regexp = "vacunas_covid_aumentada_202.+\\.fst")

for (wk in wk_list) {
  df <- read_fst(wk) %>%
    arrange(fecha_vacunacion)
  days <- unique(df$fecha_vacunacion)
  for (day in days) {
    df2 <- df %>%
      filter(fecha_vacunacion == day) %>%
      arrange(id_vacunados_covid19)
    n_limit <- 150001
    if (nrow(df2) >= n_limit) {
      split_list <- df2 %>%
        group_split(group_id = row_number() %/% n_limit)
      for(part in 1:length(split_list)) {
        df3 <- split_list[[part]]
        fname <- paste0(
          "datos/datos_aumentados_diarios/",
          str_remove(basename(wk), ".fst"),
          "_",
          format(as.Date(day, origin = "1970-01-01"), format = "%Y%m%d"),
          "_",
          sprintf("p%03d", part),
          ".csv"
        )
        cat("> Guardando ", fname, "\n")
        write.csv(df3, fname, row.names = FALSE)
      }
    } else {
      fname <- paste0(
        "datos/datos_aumentados_diarios/",
        str_remove(basename(wk), ".fst"),
        "_",
        format(as.Date(day, origin = "1970-01-01"), format = "%Y%m%d"),
        ".csv"
      )
      cat("> Guardando ", fname, "\n")
      write.csv(df2, fname, row.names = FALSE)
    }
  }
}
