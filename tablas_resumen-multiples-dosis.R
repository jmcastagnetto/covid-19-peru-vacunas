library(tidyverse)
library(fst)
library(gt)
library(gtExtras)

multiples <- read_fst("datos/vacunados-multiples-dosis.fst")

fecha_corte <- unique(multiples$fecha_corte)

# Cantidad y tipo de dosis ------------------------------------------------

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
  "Solo primera dosis", vac_1,
  "Primera y segunda dosis", vac_1_2,
  "Primera y segunda dosis + refuerzo", vac_1_2_3,
  "Solo primera dosis + refuerzo", vac_1_3,
  "Solo segunda dosis", vac_2,
  "Solo segunda dosis + refuerzo", vac_2_3,
  "Solo refuerzo", vac_3
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
    title = md("**Vacunación contra COVID-19 en Perú**:<br/>Cantidad de personas por cantidad y tipo de dosis recibidas"),
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

gtsave(
  data = tab1,
  filename = "tabla_multiples_dosis.pdf",
  expand = 15
)


# Combinación de vacunas --------------------------------------------------

por_fabricante <- multiples %>%
  group_by(fabricante_1, fabricante_2, fabricante_3) %>%
  tally() %>%
  mutate(
    rgroup = case_when(
      !is.na(fabricante_1) & is.na(fabricante_2) & is.na(fabricante_3) ~ "1",
      !is.na(fabricante_1) & !is.na(fabricante_2) & is.na(fabricante_3) ~ "1,2",
      !is.na(fabricante_1) & !is.na(fabricante_2) & !is.na(fabricante_3) ~ "1,2,3",
      !is.na(fabricante_1) & is.na(fabricante_2) & !is.na(fabricante_3) ~ "1,3",
      is.na(fabricante_1) & !is.na(fabricante_2) & !is.na(fabricante_3) ~ "2,3",
      is.na(fabricante_1) & !is.na(fabricante_2) & is.na(fabricante_3) ~ "2",
      is.na(fabricante_1) & is.na(fabricante_2) & !is.na(fabricante_3) ~ "3"
    )
  ) %>%
  ungroup() %>%
  arrange(desc(n)) %>%
  mutate(
    pct = n / sum(n)
  )

tab2 <- gt(por_fabricante) %>%
  tab_row_group(
    id = "d1",
    label = md("_Solo la primera dosis_"),
    rows = (rgroup == "1")
  ) %>%
  summary_rows(
    groups = "d1",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d1",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 2
  ) %>%
  tab_row_group(
    id = "d12s",
    label = md("_Primera y segunda dosis del mismo fabricante_"),
    rows = (rgroup == "1,2" & fabricante_1 == fabricante_2)
  ) %>%
  summary_rows(
    groups = "d12s",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d12s",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 2
  ) %>%
  tab_row_group(
    id = "d12d",
    label = md("_Primera y segunda dosis de distinto fabricante_"),
    rows = (rgroup == "1,2" & fabricante_1 != fabricante_2)
  ) %>%
  summary_rows(
    groups = "d12d",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d12d",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_row_group(
    id = "d123s",
    label = md("_Primera y segunda dosis + refuerzo del mismo fabricante_"),
    rows = (rgroup == "1,2,3" & fabricante_1 == fabricante_2 & fabricante_1 == fabricante_3)
  ) %>%
  summary_rows(
    groups = "d123s",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d123s",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_row_group(
    id = "d123d",
    label = md("_Primera y segunda dosis + refuerzo de distinto fabricante_"),
    rows = (rgroup == "1,2,3" & (fabricante_1 != fabricante_2 | fabricante_2 != fabricante_3 | fabricante_1 != fabricante_3))
  ) %>%
  summary_rows(
    groups = "d123d",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d123d",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_row_group(
    id = "d13",
    label = md("_Primera dosis + refuerzo_"),
    rows = (rgroup == "1,3")
  ) %>%
  summary_rows(
    groups = "d13",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d13",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_row_group(
    id = "d23",
    label = md("_Segunda dosis + refuerzo_"),
    rows = (rgroup == "2,3")
  ) %>%
  summary_rows(
    groups = "d23",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d23",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_row_group(
    id = "d2",
    label = md("_Solo segunda dosis_"),
    rows = (rgroup == "2")
  ) %>%
  summary_rows(
    groups = "d2",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d2",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  tab_row_group(
    id = "d3",
    label = md("_Solo refuerzo_"),
    rows = (rgroup == "3")
  ) %>%
  summary_rows(
    groups = "d3",
    columns = 4,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  summary_rows(
    groups = "d3",
    columns = 6,
    fns = list("Sub-total" = "sum"),
    formatter = "fmt_percent",
    decimals = 4
  ) %>%
  grand_summary_rows(
    columns = 4,
    fns = list("Total" = "sum"),
    formatter = "fmt_integer"
  ) %>%
  grand_summary_rows(
    columns = 6,
    fns = list("Total" = "sum"),
    formatter = "fmt_percent",
    decimals = 2
  ) %>%
  row_group_order(
    groups = c("d1", "d12s", "d12d", "d123s", "d123d",
               "d13", "d23", "d2", "d3")
  ) %>%
  cols_hide(
    columns = 5
  ) %>%
  cols_label(
    fabricante_1 = "Primera dosis",
    fabricante_2 = "Segunda dosis",
    fabricante_3 = "Refuerzo",
    n = "Número de personas",
    pct = "% del total"
  ) %>%
  tab_spanner(
    label = "Fabricante de la vacuna",
    columns = 1:3
  ) %>%
  fmt_integer(columns = 4) %>%
  fmt_missing(columns = 1:3) %>%
  fmt_percent(columns = 6, decimals = 2) %>%
  tab_header(
    title = md("**Vacunación contra COVID-19 en Perú**: Fabricante por dosis recibida por las personas"),
    subtitle = md(glue::glue("_Fuente: Datos abiertos del MINSA, al {fecha_corte}_"))
  ) %>%
  tab_source_note(glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")) %>%
  tab_style(
    locations = cells_source_notes(),
    style = list(
      cell_text(font = google_font("Inconsolata"), align = "right")
    )
  ) %>%
  opt_table_font(
    font = list(
      google_font(name = "Merriweather")
    )
  ) %>%
  gt_theme_538()


gtsave(
  data = tab2,
  filename = "tabla_multiples-dosis-fabricantes.png",
  expand = 15
)
gtsave(
  data = tab2,
  filename = "tabla_multiples-dosis-fabricantes.pdf",
  expand = 15
)

# Combinar tablas --------------------------------------------------------------

gt_two_column_layout(
  tables = list(tab1, tab2),
  output = "save",
  expand = 50,
  file = "tabla_combinada_multiples-dosis_fabricantes.png",
  vwidth = 1500,
  vheight = 1200
)
