library(tidyverse)
library(ggtext)
library(gt)
library(patchwork)

pob2020_df <- readRDS("datos/inei-estimado-pob2020-edad-sexo.rds") %>%
  mutate(
    n = if_else(sexo == "Masculino", -1*n, n),
    hjust = if_else(sexo == "Masculino", 1.1, -0.1)
  )


vacunas <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  mutate(
    sexo = str_to_title(sexo)
  )

min_date <- min(vacunas$fecha_vacunacion, na.rm = TRUE)
max_date <- max(vacunas$fecha_vacunacion, na.rm = TRUE)
fabs <- paste(unique(vacunas$fabricante), collapse = ", ")

por_sexo_edad <- vacunas %>%
  group_by(dosis, sexo, rango_edad2) %>%
  tally() %>%
  ungroup() %>%
  mutate(
    n = if_else(sexo == "Masculino", as.integer(-1*n), n),
    hjust = if_else(sexo == "Masculino", 1.1, -0.1),
    dosis_lbl = if_else(dosis == 1, "Primera dosis", "Segunda dosis")
  ) %>%
  filter(rango_edad2 != "Desconocido")

max_val <- round(max(abs(por_sexo_edad$n)), -5)

d1 <- por_sexo_edad %>%
  filter(dosis == 1)
d2 <- por_sexo_edad %>%
  filter(dosis == 2)

comb_df <- bind_rows(
  pob2020_df %>%
    filter(rango_edad2 != "0-9") %>%
    add_column(grupo = "pob2020", width = .9) %>%
    mutate(rango_edad2 = as.character(rango_edad2)),
  d1 %>%
    select(-dosis) %>%
    rename(grupo = dosis_lbl) %>%
    add_column(width = .7) %>%
    mutate(rango_edad2 = as.character(rango_edad2)),
  d2 %>%
    select(-dosis) %>%
    rename(grupo = dosis_lbl) %>%
    add_column(width = .5) %>%
    mutate(rango_edad2 = as.character(rango_edad2))
)

tab_df <- comb_df %>%
  select(rango_edad2, sexo, n, grupo) %>%
  mutate(n = if_else(sexo == "Masculino", -1 * n, n)) %>%
  pivot_wider(
    names_from = grupo,
    values_from = n
  ) %>%
  janitor::clean_names() %>%
  mutate(
    pct_d1 = primera_dosis / pob2020,
    pct_d2 = segunda_dosis / pob2020
  ) %>%
  select(
    rango = rango_edad2,
    sexo,
    pob2020,
    d1 = primera_dosis,
    pct_d1,
    d2 = segunda_dosis,
    pct_d2
  )

tab_df1 <- tab_df %>%
  filter(sexo == "Femenino") %>%
  left_join(
    tab_df %>%
      filter(sexo == "Masculino"),
    by = "rango"
  )

tab_cmp <- tab_df1 %>%
  select(-sexo.x, -sexo.y) %>%
  gt() %>%
  tab_spanner(
    label = "Población Femenina",
    columns = c(pob2020.x, d1.x, pct_d1.x, d2.x, pct_d2.x)
  ) %>%
  tab_spanner(
    label = "Población Masculina",
    columns = c(pob2020.y, d1.y, pct_d1.y, d2.y, pct_d2.y)
  ) %>%
  cols_label(
      rango = "Rango de edades",
      pob2020.x = "Estimado al 2020",
      d1.x = "Con Primera dosis",
      pct_d1.x = "% con Primera dosis",
      d2.x = "Con Segunda dosis",
      pct_d2.x = "% con Segunda dosis",
      pob2020.y = "Estimado al 2020",
      d1.y = "Con Primera dosis",
      pct_d1.y = "% con Primera dosis",
      d2.y = "Con Segunda dosis",
      pct_d2.y = "% con Segunda dosis"
  ) %>%
  tab_header(
    title = "COVID-19 (Perú): Vacunados por rango de edad y sexo",
    subtitle = glue::glue("Datos del {min_date} al {max_date}. Fuente: MINSA")
  ) %>%
  tab_source_note(
    glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) %>%
  tab_style(
    style = cell_text(align = "center", v_align = "middle"),
    locations = cells_column_labels()
  ) %>%
  tab_style(
    style = cell_text(align = "center", weight = "bold"),
    locations = cells_body(columns = 1)
  ) %>%
  tab_style(
    style = cell_text(font = "Inconsolata", align = "right"),
    locations = cells_source_notes()
  ) %>%
  tab_style(
    style = cell_borders(sides = "right", color = "#d3d3d3"),
    locations = list(cells_body(columns = 1), cells_column_labels(columns = 1))
  ) %>%
  tab_style(
    style = cell_borders(sides = "right", color = "#d3d3d3"),
    locations = list(cells_body(columns = 6),
                     cells_column_labels(columns = 6),
                     cells_column_spanners(spanners = 1))
  ) %>%
  fmt_number(
    columns = c(2, 3, 5, 7, 8, 10),
    decimals = 0
  ) %>%
  fmt_percent(
    columns = c(4, 6, 9, 11)
  ) %>%
  tab_options(
    row.striping.include_table_body = TRUE,
    row.striping.background_color = "#eeeeee",
    #column_labels.font.size = px(16),
    table.font.size = px(20)
  )

gtsave(
  tab_cmp,
  filename = "tables/comparacion-vacunados-sexo-rango-edad.pdf"
)
gtsave(
  tab_cmp,
  filename = "tables/comparacion-vacunados-sexo-rango-edad.html"
)

tmpfile <- tempfile(fileext = ".png")
gtsave(
  tab_cmp,
  filename = tmpfile,
  vwidth = 5100,
  vheight = 3900,
  zoom = 1.5
)
tbl_img <- png::readPNG(tmpfile, native = TRUE)

abs_comma <- function(x) {
  scales::comma(abs(x))
}

p01 <- ggplot(comb_df) +
  geom_col(
    aes(x = n,
        y = rango_edad2,
        group = grupo,
        color = grupo,
        linetype = grupo,
        width = width,
        fill = sexo),
    alpha = .6,
    size = 1,
    position = position_identity()
  ) +
  geom_vline(color = "black", xintercept = 0) +
  scale_color_manual(
    values = c(
      "pob2020" = "white",
      "Primera dosis" = "orange",
      "Segunda dosis" = "chartreuse3"
    )
  ) +
  scale_linetype_manual(
    values = c(
      "pob2020" = NA,
      "Primera dosis" = "solid",
      "Segunda dosis" = "dotted"
    )
  ) +
  scale_fill_brewer(palette = "Set1",
                    type = "qual") +
  scale_x_continuous(labels = abs_comma, limits = c(-3e6, 3e6),
                     n.breaks = 7) +
  guides(
    linetype = guide_none(),
    color = guide_none(),
    fill = guide_legend(title = "Sexo", reverse = TRUE)
  ) +
  labs(
    x = "",
    y = "",
    title = "Vacunación COVID-19 en Perú: Adultos con <span style='color:orange;'>primera</span> y <span style='color:chartreuse3;'>segunda</span> dosis, comparado con la pirámide poblacional",
    caption = glue::glue("Fuente: INEI y MINSA (rango: del {min_date} al {max_date})\n@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto",
    base_size = 22
  ) +
  theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    legend.title = element_text(size = 20),
    legend.text = element_text(size = 20),
    axis.text = element_text(size = 18),
    plot.title = element_textbox_simple(size = 42, hjust = .5),
    plot.subtitle = element_text(size = 20, face = "italic"),
    plot.caption = element_text(family = "Inconsolata"),
    plot.margin = unit(rep(1, 4), "cm")
  )

design <- "
111111
111111
111111
111111
222222
222222
222222
222222
222222
"

p2 <- (p01 / tbl_img) + plot_layout(design = design)

ggsave(
  plot = p2,
  filename = "plots/comparacion-vacunados-sexo-rango-edad.png",
  width = 17,
  height = 12
)
