library(fst)
library(dplyr)
library(stringr)
wk_list <- fs::dir_ls("datos", regexp = "vacunas_covid_aumentada_2021.+\\.fst")

for (wk in wk_list) {
  df <- read_fst(wk)
  days <- unique(df$fecha_vacunacion)
  for (day in days) {
    df2 <- df %>%
      filter(fecha_vacunacion == day)
    fname <- paste0(
      "datos/datos_aumentados_diarios/",
      str_remove(basename(wk), ".fst"),
      "_",
      format(as.Date(day, origin = "1970-01-01"), format = "%Y%m%d"),
      ".csv"
    )
    cat("> Guardando ", fname, "\n")
    write.csv(df2, fname)
  }
}
