# library(tidyverse)
# library(rvest)
# library(lubridate)
#
# # Fuente: Wikipedia
# url <- "https://es.wikipedia.org/wiki/Vacunaci%C3%B3n_contra_la_COVID-19_en_Per%C3%BA"
#
# vacunatonfest_xpath <- '/html/body/div[3]/div[3]/div[5]/div[1]//dt'
# #
# # vacunaton_xpath <- "/html/body/div[3]/div[3]/div[5]/div[1]/table[5]"
# # vacunafest_xpath <- "/html/body/div[3]/div[3]/div[5]/div[1]/table[6]"
#
# raw_data <- read_html(url)
#
# re_capture <- ".+ \\((\\d{1,2}) a[l]? (\\d{1,2}) de (\\w+)\\)"
#
# Sys.setlocale("LC_TIME", "es_PE.utf8")
#
# vtext <- raw_data %>%
#   html_elements(xpath = vacunaton_xpath) %>%
#   html_text()
#
# vacunaton <- vtext[1:7]
# vacunafest <- vtext[8:length(vtext)]
#
# vacunaton_tab <- tibble(
#   edicion = str_extract(vacunaton, "[^(]+") %>% str_trim(),
#   año = 2021,
#   inicio = str_extract(vacunaton, "\\d{1,2} a[l]?") %>%
#     str_extract("\\d+"),
#   fin = str_extract(vacunaton, "a[l]? \\d{1,2}") %>%
#     str_extract("\\d+"),
#   mes = str_extract(vacunaton, "de \\w+") %>%
#     str_remove(fixed("de "))
# )
#
# vacunafes_ta
#
# vacunaton_tab <- raw_data %>%
#   html_element(xpath = vacunaton_xpath) %>%
#   html_table() %>%
#   janitor::clean_names() %>%
#   mutate(
#     day_ini = str_extract(intervalo_de_tiempo, "Del \\d{1,2}") %>%
#       str_remove("Del "),
#     day_end = str_extract(intervalo_de_tiempo, "(a|al) \\d{1,2}") %>%
#       str_remove("(a|al) "),
#     month = str_extract(intervalo_de_tiempo, "de \\w+ de") %>%
#       str_remove("de ") %>%
#       str_remove(" de") %>%
#       str_replace_all(
#         c(
#           "septiembre" = "setiembre"
#         )
#       ),
#     year = str_extract(intervalo_de_tiempo, "\\d{4}") %>%
#       as.integer(),
#     date_ini = strptime(glue::glue("{year}-{month}-{day_ini}"), format = "%Y-%B-%d") %>%
#       as.Date(),
#     date_end = strptime(glue::glue("{year}-{month}-{day_end}"), format = "%Y-%B-%d") %>%
#       as.Date()
#   )
#
# vacunafest_tab <- raw_data %>%
#   html_element(xpath = vacunafest_xpath) %>%
#   html_table() %>%
#   janitor::clean_names() %>%
#   mutate(
#     day_ini = str_extract(intervalo_de_tiempo, "Del \\d{1,2}") %>%
#       str_remove("Del "),
#     day_end = str_extract(intervalo_de_tiempo, "(a|al) \\d{1,2}") %>%
#       str_remove("(a|al) "),
#     month = str_extract(intervalo_de_tiempo, "de \\w+ de") %>%
#       str_remove("de ") %>%
#       str_remove(" de") %>%
#       str_replace_all(
#         c(
#           "septiembre" = "setiembre"
#         )
#       ),
#     year = str_extract(intervalo_de_tiempo, "\\d{4}") %>%
#       as.integer(),
#     date_ini = strptime(glue::glue("{year}-{month}-{day_ini}"), format = "%Y-%B-%d") %>%
#       as.Date(),
#     date_end = strptime(glue::glue("{year}-{month}-{day_end}"), format = "%Y-%B-%d") %>%
#       as.Date()
#   )
#
# write_csv(
#   vacunaton_tab,
#   file = "datos/vacunas_covid_vacunatones.csv"
# )
#
# write_csv(
#   vacunafest_tab,
#   file = "datos/vacunas_covid_vacunafests.csv"
# )