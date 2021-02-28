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

max_date <- max(df$FECHA_VACUNACION, na.rm = TRUE)

p1 <- ggplot(
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
    title = glue::glue("Vacunados por dia en el Perú al {max_date}"),
    subtitle = "Primera dosis, Sinopharm - agrupados por sexo y rango de edades",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  theme_bw(20) +
  theme(
    legend.position = "bottom",
    plot.caption = element_text(family = "Inconsolata", size = 14)
  )

ggsave(
  plot = p1,
  filename = "plots/vacunados-por-dia-edades-sexo.png",
  width = 16,
  height = 9
)

p2 <- ggplot(
  df %>% filter(!is.na(rango_edad)),
  aes(x = FECHA_VACUNACION, y = csum,
      group = SEXO, color = SEXO, fill = SEXO)
) +
  geom_point() +
  geom_smooth(method = "loess") +
  facet_wrap(~rango_edad, scales = "free_y") +
  scale_x_date(date_breaks = "1 week",
               date_minor_breaks = "1 day",
               date_labels = "%b %d\nSem. %V") +
  scale_y_continuous(labels = scales::comma) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    x = "",
    y = "Número de vacunados",
    fill = "Sexo",
    color = "Sexo",
    title = glue::glue("Vacunados por dia en el Perú al {max_date} (acumulado)"),
    subtitle = "Primera dosis, Sinopharm - agrupados por sexo y rango de edades (filtrando los que no consignan edad)",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\nCurvas aproximadas usando LOESS // @jmcastagnetto, Jesus M. Castagnetto"
  ) +
  theme_bw(20) +
  theme(
    legend.position = "bottom",
    legend.background = element_blank(),
    plot.title.position = "plot",
    plot.caption = element_text(family = "Inconsolata", size = 14)
  )
p2

ggsave(
  plot = p2,
  filename = "plots/vacunas-acumulados-rango-edades-sexo.png",
  width = 16,
  height = 12
)

