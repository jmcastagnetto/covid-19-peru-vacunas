library(tidyverse)


# Primera dosis -----------------------------------------------------------

df <- readRDS("datos/vacunas_covid_aumentada.rds") %>%
  mutate(
    dosis_lbl = paste("Dosis:", dosis)
  ) %>%
  group_by(fecha_vacunacion, fabricante, dosis, dosis_lbl, sexo, rango_edad) %>%
  tally() %>%
  ungroup() %>%
  arrange(fecha_vacunacion, fabricante, dosis, dosis_lbl, sexo, rango_edad) %>%
  group_by(rango_edad, fabricante, dosis, dosis_lbl, sexo) %>%
  mutate(
    csum = cumsum(n)
  )

max_date <- max(df$fecha_vacunacion, na.rm = TRUE)


my_theme <- function() {
  hrbrthemes::theme_ipsum_rc(
    base_size = 20,
    plot_title_size = 32,
    subtitle_size = 26,
    axis_title_size = 24,
    strip_text_size = 18,
    caption_family = "Inconsolata",
    caption_size = 20
  ) +
  theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    legend.direction = "horizontal",
    plot.caption = element_text(family = "Inconsolata", size = 14)
  )
}

# Por dia -----------------------------------------------------------------

p1 <- ggplot(
  df,
  aes(x = fecha_vacunacion, y = n, group = rango_edad,
      fill = rango_edad)
) +
  geom_col() +
  facet_grid(sexo~fabricante+dosis_lbl, scales = "free_y") +
  scale_x_date() +
  #scale_x_date(date_labels = "%b %d") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    x = "",
    y = "Número de vacunados",
    fill = "Rango de edad",
    title = glue::glue("Vacunados por dia en el Perú al {max_date}"),
    subtitle = "Agrupados por sexo y rango de edades, por fabricante y dosis",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  my_theme() +
  guides(fill = guide_legend(nrow = 1))
#p1
ggsave(
  plot = p1,
  filename = "plots/vacunados-por-dia-edades-sexo.png",
  width = 18,
  height = 10
)


# Acumulativo -------------------------------------------------------------

p2 <- ggplot(
  df %>% filter(!is.na(rango_edad)),
  aes(x = fecha_vacunacion, y = csum,
      group = sexo, color = sexo, fill = sexo)
) +
  geom_point(size = .2) +
  geom_smooth(method = "loess", se = FALSE) +
  facet_grid(fabricante+dosis_lbl~rango_edad, scales = "free_y") +
  scale_x_date() +
  scale_y_continuous(labels = scales::comma) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    x = "",
    y = "Número de vacunados",
    fill = "Sexo",
    color = "Sexo",
    title = glue::glue("Vacunados por dia en el Perú al {max_date} (acumulado)"),
    subtitle = "Agrupados por sexo y rango de edades, por fabricante y dosis",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\nCurvas aproximadas usando LOESS // @jmcastagnetto, Jesus M. Castagnetto"
  ) +
  my_theme()

#p2
ggsave(
  plot = p2,
  filename = "plots/vacunas-acumulados-rango-edades-sexo.png",
  width = 24,
  height = 16
)

