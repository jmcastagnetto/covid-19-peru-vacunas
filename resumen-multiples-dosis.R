library(tidyverse)
library(fst)
library(gt)

multiples <- read_fst("datos/vacunados-multiples-dosis.fst")

fecha_corte <- unique(multiples$fecha_corte)

vac_1_2_3 <- sum(!is.na(multiples$fabricante_1) &
                   !is.na(multiples$fabricante_2) &
                   !is.na(multiples$fabricante_3))

vac_1_2 <- sum(!is.na(multiples$fabricante_1) &
                   !is.na(multiples$fabricante_2) &
                   is.na(multiples$fabricante_3))

vac_1 <- sum(!is.na(multiples$fabricante_1) &
                   is.na(multiples$fabricante_2) &
                   is.na(multiples$fabricante_3))

vac_2 <- sum(is.na(multiples$fabricante_1) &
               !is.na(multiples$fabricante_2) &
               is.na(multiples$fabricante_3))

vac_2_3 <- sum(is.na(multiples$fabricante_1) &
                 !is.na(multiples$fabricante_2) &
                 !is.na(multiples$fabricante_3))

vac_3 <- sum(is.na(multiples$fabricante_1) &
                   is.na(multiples$fabricante_2) &
                   !is.na(multiples$fabricante_3))

vac_1_3 <- sum(!is.na(multiples$fabricante_1) &
                   is.na(multiples$fabricante_2) &
                   !is.na(multiples$fabricante_3))

vac_dosis_sum <- tribble(
  ~dosis_recibida, ~n,
  "Sólo primera dosis", vac_1,
  "Primera y segunda dosis", vac_1_2,
  "Primera y segunda dosis + refuerzo", vac_1_2_3,
  "Sólo primera dosis + refuerzo", vac_1_3,
  "Sólo segunda dosis", vac_2,
  "Sólo segunda dosis + refuerzo", vac_2_3,
  "Sólo refuerzo", vac_3
) %>%
  mutate(
    pct = n / sum(n)
  ) %>%
  select(
    dosis_recibida,
    n,
    pct
  )

tab1 <- gt(vac_dosis_sum) %>%
  cols_align(
    align = "right",
    columns = 2:3
  ) %>%
  cols_label(
    dosis_recibida = md("**Dosis recibidas<br/>por cada persona**"),
    n = md("**Número de<br/>personas**"),
    pct = md("**Porcentaje<br/>del total**")
  ) %>%
  fmt_integer(
    columns = 2
  ) %>%
  fmt_percent(
    columns = 3, decimals = 4
  ) %>%
  tab_row_group(
    id = "poco_comun",
    label = md("_Casos poco comunes_"),
    rows = 4:7
  ) %>%
  summary_rows(
    groups = "poco_comun",
    columns = 2,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "poco_comun",
    columns = 3,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_style(
    locations = cells_body(rows = 4:7),
    style = list(
      cell_fill(color = rgb(1, 0, 0, .3))
    )
  ) %>%
  tab_row_group(
    id = "esperado",
    label = md("_Casos esperados_"),
    rows = 1:3
  ) %>%
  tab_style(
    locations = cells_body(rows = 1:3),
    style = list(
      cell_fill(color = rgb(0, 1, 0, .3))
    )
  ) %>%
  tab_style(
    locations = cells_row_groups(),
    style = list(
      cell_text(align = "center")
    )
  ) %>%
  summary_rows(
    groups = "esperado",
    columns = 2,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "esperado",
    columns = 3,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  grand_summary_rows(
    columns = 2,
    fns = list("Total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  grand_summary_rows(
    columns = 3,
    fns = list("Total" = "sum"),
    formatter = "fmt_percent",
    decimals = 0
  ) %>%
  #opt_table_lines() %>%
  #opt_table_outline(width = px(1), color = "grey40") %>%
  opt_table_font(
    font = list(
      google_font(name = "Merriweather")
    )
  ) %>%
  tab_header(
    title = md("**Vacunación contra COVID-19 en Perú**:<br/>Cantidad de personas por combinación de dosis recibidas"),
    subtitle = md(glue::glue("_Fuente: Datos abiertos del MINSA, al {fecha_corte}_"))
  ) %>%
  tab_source_note(glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")) %>%
  tab_style(
    locations = cells_source_notes(),
    style = list(
      cell_text(font = google_font("Inconsolata"), align = "right")
    )
  )
#tab1
gtsave(
  data = tab1,
  filename = "tabla_multiples_dosis.png",
  expand = 15
)

