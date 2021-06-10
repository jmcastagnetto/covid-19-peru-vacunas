library(tidyverse)
library(ggtext)

df <- readRDS("datos/vacunas_covid_resumen.rds")
fecha_corte <- unique(df$fecha_corte)
min_date <- min(df$fecha_vacunacion, na.rm = TRUE)
max_date <- max(df$fecha_vacunacion, na.rm = TRUE)
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

# anotaciones <- tribble(
#   ~x, ~y, ~label, ~description,
#   as.Date("2021-03-08"), .75*max_y, "2021-03-08", "Inicio de vacunación de adultos mayores a 80 años",
#   as.Date("2021-04-30"), .75*max_y, "2021-04-30", "Inicio de vacunación de adultos mayores a 70 años",
#   as.Date("2021-05-21"), .75*max_y, "2021-05-21", "Inicio de vacunación de adultos mayores a 65 años"
# )

anotaciones <- read_csv("datos/eventos_relacionados_vacunas_covid_peru.csv") %>%
  rename(x = fecha, description = evento) %>%
  mutate(
    label = as.character(x)
  ) %>%
  add_column(y = .75 * max_y)


p1 <- ggplot(
  por_fabricante,
  aes(x = fecha_vacunacion, y = n_acum,
      group = fabricante,
      fill = fabricante)
) +
  geom_area(color = "black") +
  geom_vline(
    data = anotaciones,
    aes(xintercept = x),
    color = "grey40",
    size = 2,
    linetype = "dashed"
  ) +
  ggforce::geom_mark_circle(
    data = anotaciones,
    aes(
      x = x,
      y = y,
      label = label,
      description = description
    ),
    label.fill = rgb(1,1,1, .7),
    con.type = "straight",
    con.colour = "blue",
    color = "blue",
    fill = "blue",
    alpha = 1,
    expand = unit(1, "mm"),
    inherit.aes = FALSE
  ) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_date(
    date_breaks = "2 weeks",
    date_labels = "Sem: %V\n%b %Y",
    expand = expansion()
  ) +
  scale_fill_brewer(type = "qual", palette = "Set2") +
  labs(
    x = "",
    y = "Dosis totales aplicadas",
    fill = "",
    title = "Perú - Vacunación contra COVID-19",
    subtitle = glue::glue("*Fuente*: Datos abiertos del MINSA (del {min_date} al {max_date})"),
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  ) +
  ggthemes::theme_hc(
    base_family = "Roboto Medium",
    base_size = 24
  ) +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(size = 32, face = "bold"),
    plot.subtitle = element_markdown(size = 22, colour = "grey70"),
    plot.caption.position = "plot",
    plot.caption = element_text(family = "Inconsolata"),
    legend.position = "top",
    plot.margin = unit(rep(1, 4), "cm")
  )
ggsave(
  plot = p1,
  filename = "plots/dosis-totales-por-fabricante.png",
  width = 16,
  height = 10
)
