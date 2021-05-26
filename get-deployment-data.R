library(tidyverse)
library(rvest)
library(V8)

ctx <- v8()
url <- "https://mvc.cenares.gob.pe/sic/Vacuna/MapaVacuna3"
xpath <- "/html/body/script[2]"

txt <- read_html(url) %>%
  html_elements(xpath = xpath) %>%
  html_text(trim = TRUE)

tmpfile <- tempfile()
write_file(
  txt,
  file = tmpfile
)
txt2 <- read_lines(
  tmpfile,
  n_max = 2
)
ctx$eval(txt2)
data_df <- ctx$get("infoVacunasDetalle") %>%
  as_tibble() %>%
  mutate(
    periodo = lubridate::ymd(periodo),
    ultimoReparto = lubridate::ymd(ultimoReparto)
  )

write_csv(
  data_df,
  file = "datos/vacunas_covid_distribucion.csv.gz"
)

saveRDS(
  data_df,
  file = "datos/vacunas_covid_distribucion.rds"
)

unlink(tmpfile)
