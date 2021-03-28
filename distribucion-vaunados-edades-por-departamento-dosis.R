library(tidyverse)
library(hrbrthemes)
library(ggridges)

df <- readRDS("datos/vacunas_covid.rds")

my_theme <- function() {
  theme_ipsum_gs() +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(size = 32),
      plot.subtitle = element_text(size = 22, color = "grey50"),
      plot.caption = element_text(size = 16, family = "Inconsolata"),
      strip.text = element_text(size = 20),
      axis.text.y = element_text(size = 22),
      axis.text.x = element_text(angle = 90, size = 20, hjust = 1),
      legend.position = "left",
      legend.title = element_text(size = 20),
      legend.text = element_text(size = 18),
      legend.key.height = unit(4, "lines"),
      panel.spacing.x = unit(2, "lines")
    )
}


d1 <- df %>% filter(DOSIS == 1)
tot_d1 <- format(nrow(d1), big.mark = ",")

d2 <- df %>% filter(DOSIS == 2)

fecha_corte <- unique(d1$FECHA_CORTE)

p1 <- ggplot(
  d1 %>% group_by(DEPARTAMENTO, rango_edad2, FABRICANTE, SEXO) %>% tally(),
  aes(x = rango_edad2, y = DEPARTAMENTO)
) +
  geom_raster(aes(fill = n)) +
  scale_fill_viridis_c(
    direction = -1,
    option = "magma",
    n.breaks = 15,
    name = "Número de\npersonas\nvacunadas",
    labels = scales::comma
  ) +
  my_theme() +
  facet_wrap(~FABRICANTE+SEXO, nrow = 1) +
  labs(
    x = "",
    y = "",
    title = glue::glue("Vacunación COVID-19 en Perú: Primera dosis (N = {tot_d1})"),
    subtitle = glue::glue("Al {fecha_corte}, por Fabricante y Sexo, para cada Departamento y Grupo Etáreo"),
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  )
p1

ggsave(
  plot = p1,
  filename = "plots/vacunados-primera-dosis-por-departamento.png",
  width = 20,
  height = 14
)

tot_d2 <- format(nrow(d2), big.mark = ",")

p2 <- ggplot(
  d2 %>% group_by(DEPARTAMENTO, rango_edad2, FABRICANTE, SEXO) %>% tally(),
  aes(x = rango_edad2, y = DEPARTAMENTO)
) +
  geom_raster(aes(fill = n)) +
  scale_fill_viridis_c(
    direction = -1,
    option = "magma",
    n.breaks = 15,
    name = "Número de\npersonas\nvacunadas",
    labels = scales::comma
  ) +
  my_theme() +
  facet_wrap(~FABRICANTE+SEXO, nrow = 1) +
  labs(
    x = "",
    y = "",
    title = glue::glue("Vacunación COVID-19 en Perú: Segunda dosis (N = {tot_d2})"),
    subtitle = glue::glue("Al {fecha_corte}, por Fabricante y Sexo, para cada Departamento y Grupo Etáreo"),
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  )
p2
ggsave(
  plot = p2,
  filename = "plots/vacunados-segunda-dosis-por-departamento.png",
  width = 18,
  height = 14
)


d1m <- d1 %>%
  group_by(DEPARTAMENTO, FABRICANTE) %>%
  summarise(
    n = n(),
    mediana = median(EDAD, na.rm = TRUE),
    lbl1 = glue::glue("N: {n}"),
    lbl2 = glue::glue("[{mediana}]")
  )

p1d <- ggplot(
  d1,
  aes(x = EDAD, y = DEPARTAMENTO, fill = factor(stat(quantile)))
) +
  ggridges::stat_density_ridges(
    geom = "density_ridges_gradient",
    calc_ecdf = TRUE,
    quantiles = 4,
    quantile_lines = TRUE,
    scale = 1.1,
    show.legend = FALSE
  ) +
  # geom_label(
  #   data = d1m,
  #   aes(x = 20, y = DEPARTAMENTO, label = lbl1),
  #   inherit.aes = FALSE,
  #   hjust = 1,
  #   label.size = 0
  # ) +
  # geom_label(
  #   data = d1m,
  #   aes(x = 110, y = DEPARTAMENTO, label = lbl2),
  #   inherit.aes = FALSE,
  #   label.size = 0
  # ) +
  scale_fill_viridis_d(
    direction = -1,
    alpha = .5
  ) +
  theme_ridges(font_size = 20) +
  theme(
    panel.spacing.x = unit(2, "lines"),
    strip.text = element_text(family = "bold", size = 24),
    strip.background = element_blank(),
    plot.title.position = "plot",
    plot.caption = element_text(size = 18, family = "Inconsolata")
  ) +
  facet_wrap(~FABRICANTE, nrow = 1) +
  labs(
    x = "",
    y = "",
    title = glue::glue("Distribución de Edades en la Vacunación COVID-19 en Perú: Primera dosis (N = {tot_d1})"),
    subtitle = glue::glue("Al {fecha_corte}, por Fabricante y Departamento, separado por cuartiles"),
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  )
p1d
ggsave(
  plot = p1d,
  filename = "plots/distribucion-edades-por-departamento-primera-dosis.png",
  width = 18,
  height = 16
)


p2d <- ggplot(
  d2,
  aes(x = EDAD, y = DEPARTAMENTO, fill = factor(stat(quantile)))
) +
  ggridges::stat_density_ridges(
    geom = "density_ridges_gradient",
    calc_ecdf = TRUE,
    quantiles = 4,
    quantile_lines = TRUE,
    scale = 1.1,
    show.legend = FALSE
  ) +
  # geom_label(
  #   data = d1m,
  #   aes(x = 20, y = DEPARTAMENTO, label = lbl1),
  #   inherit.aes = FALSE,
  #   hjust = 1,
  #   label.size = 0
  # ) +
  # geom_label(
  #   data = d1m,
  #   aes(x = 110, y = DEPARTAMENTO, label = lbl2),
  #   inherit.aes = FALSE,
#   label.size = 0
# ) +
scale_fill_viridis_d(
  direction = -1,
  alpha = .5
) +
  theme_ridges(font_size = 20) +
  theme(
    panel.spacing.x = unit(2, "lines"),
    strip.text = element_text(family = "bold", size = 24),
    strip.background = element_blank(),
    plot.title.position = "plot",
    plot.caption = element_text(size = 18, family = "Inconsolata")
  ) +
  facet_wrap(~FABRICANTE, nrow = 1) +
  labs(
    x = "",
    y = "",
    title = glue::glue("Distribución de Edades en la Vacunación COVID-19 en Perú: Segunda dosis (N = {tot_d2})"),
    subtitle = glue::glue("Al {fecha_corte}, por Fabricante y Departamento, separado por cuartiles"),
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  )

p2d
ggsave(
  plot = p2d,
  filename = "plots/distribucion-edades-por-departamento-segunda-dosis.png",
  width = 12,
  height = 16
)
