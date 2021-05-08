library(tidyverse)

df <- readRDS("datos/vacunas_covid_resumen.rds")
fecha_corte <- unique(df$fecha_corte)

max_y <- sum(df$n_reg)

por_fabricante <- df %>%
  ungroup() %>%
  group_by(fecha_vacunacion, fabricante) %>%
  summarise(
    n = sum(n_reg)
  ) %>%
  ungroup() %>%
  arrange(fabricante, fecha_vacunacion) %>%
  distinct() %>%
  group_by(fabricante) %>%
  mutate(
    n_acum = cumsum(n)
  ) %>%
  arrange(fecha_vacunacion, fabricante)

ggplot(
  por_fabricante,
  aes(x = fecha_vacunacion, y = n_acum,
      group = fabricante,
      fill = fabricante)
) +
  geom_area(color = "black") +
  geom_vline(xintercept = as.Date("2021-03-08"),
             color = "grey 40",
             size = 2, linetype = "dashed") +
  annotate(
    geom = "text",
    x = as.Date("2021-02-20"),
    y = .95*max_y,
    hjust = .5,
    vjust = 1,
    label = "2021-03-08:\nInicio de vacunación de\nadultos mayores a 80 años",
    size = 7,
    color = "grey40"
  ) +
  annotate(
    geom = "curve",
    x = as.Date("2021-02-20"),
    y = .75*max_y,
    xend = as.Date("2021-03-07"),
    yend = .8e6,
    angle = 45,
    size = 1,
    arrow = arrow(length = unit(5, "mm"), type = "closed"),
    color = "grey40"
  ) +
  geom_vline(xintercept = as.Date("2021-04-30"),
             color = "grey 40",
             size = 2, linetype = "dashed") +
  annotate(
    geom = "text",
    x = as.Date("2021-04-01"),
    y = .95*max_y,
    hjust = .5,
    vjust = 1,
    label = "2021-04-30:\nInicio de vacunación de\nadultos mayores a 70 años",
    size = 7,
    color = "grey40"
  ) +
  annotate(
    geom = "curve",
    x = as.Date("2021-04-01"),
    y = .75*max_y,
    xend = as.Date("2021-04-29"),
    yend = .8e6,
    angle = 45,
    size = 1,
    arrow = arrow(length = unit(5, "mm"), type = "closed"),
    color = "grey40"
  ) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_date(
    date_breaks = "2 weeks",
    date_labels = "Sem: %V\n%b %Y"
  ) +
  scale_fill_brewer(type = "qual", palette = "Pastel2") +
  labs(
    x = "",
    y = "Dosis totales aplicadas",
    fill = "",
    title = "Perú - Vacunación contra COVID-19",
    subtitle = glue::glue("Fuente: Datos abiertos del MINSA (al {fecha_corte})"),
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto Medium",
    base_size = 24
  ) +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(size = 32, face = "bold"),
    plot.subtitle = element_text(face = "italic", size = 22, colour = "grey70"),
    plot.caption.position = "plot",
    plot.caption = element_text(family = "Inconsolata"),
    legend.position = "top",
    plot.margin = unit(rep(1, 4), "cm")
  )

ggsave(
  filename = "plots/dosis-totales-por-fabricante.png",
  width = 16,
  height = 10
)
