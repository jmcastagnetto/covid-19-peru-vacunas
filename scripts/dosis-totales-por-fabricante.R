library(tidyverse)
library(ggtext)
library(ggforce)
library(patchwork)

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

p1 <- ggplot(
  por_fabricante,
  aes(x = fecha_vacunacion, y = n_acum,
      group = fabricante,
      fill = fabricante)
) +
  geom_area(color = "black") +
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

eventos <- read_csv("datos/eventos_relacionados_vacunas_covid_peru.csv")

p2 <- ggplot(
  eventos,
  aes(x = fecha, y = 0, label = fecha, description = evento, group = evento)
) +
  geom_hline(yintercept = 0, color = "gray70", size = 2) +
  geom_point() +
  geom_mark_circle(
    expand = unit(2, "mm"),
    label.width = unit(4, "cm"),
    label.fill = rgb(1, 1, 0, .3),
    con.colour = "blue",
    con.cap = 0,
    label.fontsize = 10
  ) +
  scale_y_continuous(limits = c(-1, 1)) +
  theme_void() +
  theme(
    legend.position = "none",
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank()
  )

p12 <- p1 +
  inset_element(
    p2,
    left = .05,
    bottom = .2,
    right = .8,
    top = 1
  )

ggsave(
  plot = p12,
  filename = "plots/dosis-totales-por-fabricante.png",
  width = 20,
  height = 14
)
