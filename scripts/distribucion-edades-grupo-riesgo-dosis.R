library(tidyverse)
library(ggridges)

vacunas <- readRDS("datos/vacunas_covid_aumentada.rds")

p1 <- ggplot(
  vacunas %>%
    mutate(
      dosis_lbl = if_else(
        dosis == 1,
        "Primera Dosis",
        "Segunda Dosis"
      )
    ),
  aes(y = grupo_riesgo, x = edad, fill = grupo_riesgo)
) +
  stat_density_ridges(
    geom = "density_ridges",
    calc_ecdf = TRUE,
    quantile_lines = TRUE,
    quantiles = c(.5),
    alpha = .7,
    scale = 1.1,
    show.legend = FALSE
  ) +
  scale_fill_brewer(type = "qual", palette = "Paired") +
  facet_wrap(~dosis_lbl) +
  theme_classic(base_size = 16) +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(size = 32),
    plot.subtitle = element_text(size = 24, color = "gray40"),
    plot.caption = element_text(family = "Inconsolata", size = 16)
  ) +
  labs(
    x = "Edad",
    y = "",
    title = "COVID-19, Perú: Distribución etárea por grupo de riesgo",
    subtitle = "Fuente de datos: MINSA",
    caption = glue::glue("@jmcastagnetto, Jesus M. Castagnetto ({Sys.Date()})")
  )

ggsave(
  p1,
  filename = "plots/distribucion-edades-grupo-riesgo-dosis.png",
  width = 14,
  height = 9
)
