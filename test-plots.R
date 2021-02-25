library(tidyverse)

df <- readRDS("datos/vacunas_covid.rds") %>%
  group_by(FECHA_VACUNACION, SEXO, rango_edad) %>%
  tally() %>%
  ungroup() %>%
  arrange(FECHA_VACUNACION, SEXO) %>%
  group_by(rango_edad, SEXO) %>%
  mutate(
    csum = cumsum(n)
  )


ggplot(
  df,
  aes(x = FECHA_VACUNACION, y = n, group = rango_edad,
      fill = rango_edad)
) +
  geom_col() +
  facet_wrap(~SEXO, scales = "free_y") +
  scale_x_date(date_breaks = "1 week", date_minor_breaks = "1 day",
               date_labels = "%b %d") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    x = "",
    y = "Número de vacunados",
    fill = "Rango de edad",
    title = "Vacunados por dia en el Perú al 2021-02-23",
    subtitle = "Primera dosis, Sinopharm - agrupados por sexo y rango de edades",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  theme_bw(20) +
  theme(
    legend.position = "bottom",
    plot.caption = element_text(family = "Inconsolata", size = 14)
  )


ggplot(
  df %>% filter(!is.na(rango_edad)),
  aes(x = FECHA_VACUNACION, y = csum,
      group = SEXO, color = SEXO, fill = SEXO)
) +
  geom_point() +
  geom_smooth() +
  facet_wrap(~rango_edad, scales = "free_y") +
  scale_x_date(date_breaks = "1 week", date_minor_breaks = "1 day",
               date_labels = "%b %d") +
  scale_y_continuous(labels = scales::comma) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    x = "",
    y = "Número de vacunados",
    fill = "Sexo",
    color = "Sexo",
    title = "Vacunados en el Perú al 2021-02-23 (acumulado)",
    subtitle = "Primera dosis, Sinopharm - agrupados por sexo y rango de edades (filtrando los que no consignan edad",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  theme_bw(20) +
  theme(
    legend.position = c(.8, .2),
    plot.caption = element_text(family = "Inconsolata", size = 14)
  )
