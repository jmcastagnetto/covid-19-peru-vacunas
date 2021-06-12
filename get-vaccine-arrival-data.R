library(tidyverse)
library(rvest)
library(lubridate)

# Fuente: Wikipedia
url <- "https://es.wikipedia.org/wiki/Vacunaci%C3%B3n_contra_la_COVID-19_en_Per%C3%BA"

table_xpath <- "/html/body/div[3]/div[3]/div[5]/div[1]/table[13]"

raw_data <- read_html(url)
tab1 <- raw_data %>%
  html_element(xpath = table_xpath) %>%
  html_table() %>%
  janitor::clean_names()

header <- slice(tab1, 1:1)
nrows <- nrow(tab1)
colnames(tab1) <- header

Sys.setlocale("LC_TIME", "es_PE.utf8")
vaccine_arrivals <- tab1 %>%
  slice(2:nrows) %>%
  janitor::clean_names() %>%
  mutate(
    nro = str_remove(nro, "°") %>% as.integer(),
    fecha_de_llegada = as_date(
      fecha_de_llegada,
      format = "%e de %B de %Y"
    ),
    cantidad = str_remove_all(cantidad, "\\s+") %>% as.numeric(),
    covax = str_detect(farmaceutica, "(COVAX)"),
    farmaceutica = str_remove(farmaceutica, fixed(" (COVAX)"))
  ) %>%
  relocate(
    fecha_de_llegada,
    .before = 2
  ) %>%
  add_column(last_update = Sys.Date()) %>%
  select(-ref)

write_csv(
  vaccine_arrivals,
  file = "datos/covid19_vaccine_arrivals_peru.csv"
)
