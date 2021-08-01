library(tidyverse)
data_df <- read_csv(
  "datos/Reporte_Detallado.csv",
  col_types = cols(
    DEPARTAMENTO = col_character(),
    DISA = col_character(),
    ESTABLECIMIENTO = col_character(),
    MARCA = col_character(),
    PERIODO = col_date(format = "%d/%m/%Y"),
    CANTIDAD = col_number()
  )
) %>%
  janitor::clean_names()

write_csv(
  data_df,
  file = "datos/vacunas_covid_distribucion.csv.gz"
)

saveRDS(
  data_df,
  file = "datos/vacunas_covid_distribucion.rds"
)
