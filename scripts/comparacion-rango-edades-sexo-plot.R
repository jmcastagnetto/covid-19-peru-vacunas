library(tidyverse)
library(ggtext)
library(ggpattern)

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
      "Primera dosis" = "grey40",
      "Segunda dosis" = "green"
    )
  ) +
  scale_linetype_manual(
    values = c(
      "pob2020" = NA,
      "Primera dosis" = "solid",
      "Segunda dosis" = "dashed"
    )
  ) +
  scale_fill_brewer(palette = "Paired",
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
    title = "Vacunación COVID-19 en Perú: Adultos con <span style='color:grey40;'>una</span> y <span style='color:green;'>dos</span> dosis, comparado con la pirámide poblacional",
    caption = glue::glue("Fuente: Estimaciones poblacionales del INEI y datos de vacunación contra el COVID-19 del MINSA (rango: del {min_date} al {max_date})\n@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto",
    base_size = 22
  ) +
  theme(
    plot.title.position = "plot",
    legend.position = "top",
    legend.title = element_text(size = 22),
    legend.text = element_text(size = 20),
    axis.text = element_text(size = 18),
    plot.title = element_textbox_simple(size = 38),
    plot.subtitle = element_text(size = 20, face = "italic"),
    plot.caption = element_text(family = "Inconsolata"),
    plot.margin = unit(rep(.5, 4), "cm")
  )


ggsave(
  plot = p01,
  filename = "plots/comparacion-vacunados-sexo-rango-edad.png",
  width = 17,
  height = 13
)
