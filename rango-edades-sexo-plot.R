library(tidyverse)
library(patchwork)

vacunas <- readRDS("datos/vacunas_covid.rds") %>%
  mutate(
    SEXO = str_to_title(SEXO)
  )

max_date <- max(vacunas$FECHA_VACUNACION, na.rm = TRUE)

por_sexo_edad <- vacunas %>%
  mutate(
    rango_edad = fct_explicit_na(rango_edad, "Desconocido")
  ) %>%
  group_by(SEXO, rango_edad) %>%
  tally()

hrbrthemes::import_roboto_condensed()

p1 <- ggplot(
  por_sexo_edad,
  aes(x = n, y = rango_edad,
      group = SEXO,
      color = rango_edad,
      fill = rango_edad)
) +
  geom_col(show.legend = FALSE) +
  hrbrthemes::scale_fill_ipsum() +
  scale_x_continuous(labels = scales::comma) +
  facet_wrap(~SEXO, scales = "free_x") +
  hrbrthemes::theme_ipsum_rc(
    plot_title_size = 32
  ) +
  labs(
    y = "Rango etáreo (años)",
    x = "Número de personas",
    title = glue::glue("Vacunados por rango etáreo en el Perú al {max_date}"),
    subtitle = "Primera dosis, Sinopharm - agrupados por sexo y rango de edades",
    caption = "Fuente: https://www.datosabiertos.gob.pe/dataset/vacunación-contra-covid-19-ministerio-de-salud-minsa\n@jmcastagnetto, Jesus M. Castagnetto"
  ) +
  theme(
    plot.title.position = "plot",
    plot.caption = element_text(family = "Inconsolata", size = 14),
    plot.subtitle = element_text(size = 20),
    axis.title.x = element_text(size = 16),
    axis.title.y = element_text(size = 16),
    strip.text = element_text(size = 20),
  )

tab_df <- vacunas %>%
  group_by(SEXO) %>%
  tally() %>%
  mutate(
    Porcentaje = sprintf("%.1f%%", 100 * n / sum(n)),
    Personas = format(n, big.mark = ",")
  ) %>%
  select(SEXO, Personas, Porcentaje) %>%
  rename(
    Sexo = SEXO
  )

df <- tibble(
  x = .8, y = .2, tb = list(tab_df)
)

p2 <- ggplot() +
  ggpmisc::geom_table(
    data = df,
    aes(x = x, y = y, label = tb),
    size = 5
  ) +
  theme_void()

p3 <- p1 +
  inset_element(p2, left = .8, right = .9, bottom = 1.1, top = 1.25)

ggsave(
  plot = p3,
  filename = "plots/vacunados-sexo-rango-edad.png",
  width = 16,
  height = 10
)
